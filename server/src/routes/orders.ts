import { Router } from 'express';
import crypto from 'crypto';
import { orders, products, users, coupons } from '../db/mongo';
import { authenticateToken, requireAdmin, AuthRequest } from '../middlewares/auth';
import { computeDelivery, deliverySettings } from '../services/delivery';

const router = Router();

// Server-side money constants. Totals are ALWAYS recomputed from these + DB
// prices; client amounts are never trusted. The delivery fee itself is computed
// by the admin-managed distance engine (see ../services/delivery).
const GST_RATE = 0.18;

// Money is stored rounded to paise; floating-point accumulation otherwise leaks
// values like 8928.999999999998 into the order record.
const round2 = (n: number) => Math.round(n * 100) / 100;

// The statuses the API accepts. This used to be any free-form string, so a typo
// persisted happily and then matched no admin tab, stranding the order.
const ORDER_STATUSES = [
  'pending', 'confirmed', 'processing', 'packed', 'shipped', 'delivered', 'cancelled',
];

// What a single unit actually sells for: the sale price when one is set, then the
// best bulk-pricing tier the line quantity qualifies for. This mirrors
// CartItemEntity.effectivePrice in lib/domain/entities/cart_entity.dart - the two
// MUST agree, or the customer is billed something other than the cart showed.
function unitPriceFor(product: any, quantity: number): number {
  const base = product.discount_price != null
    ? Number(product.discount_price)
    : Number(product.price);
  let bestDiscount = 0;
  const tiers = product.bulk_pricing;
  if (tiers && typeof tiers === 'object') {
    for (const [threshold, pct] of Object.entries<any>(tiers)) {
      const min = parseInt(threshold, 10);
      if (Number.isFinite(min) && quantity >= min) {
        const d = Number(pct);
        if (Number.isFinite(d) && d > bestDiscount) bestDiscount = d;
      }
    }
  }
  return base * (1 - bestDiscount);
}

// A whole number of 1 or more, else null. Quantity used to go unchecked, so a
// negative value passed the stock test, made the total negative, and *increased*
// stock when the $inc ran.
function normaliseQuantity(raw: any): number | null {
  const n = Number(raw);
  if (!Number.isInteger(n) || n < 1) return null;
  return n;
}

// Return every line of an order to stock. Shared by the customer cancel route and
// the admin status route so the two cannot drift apart again.
async function restockOrder(order: any) {
  for (const item of order.items || []) {
    if (!item.product_id) continue;
    // Orders placed before quantity was validated may hold a string or a
    // fraction. $inc with a string concatenates in the in-memory store and
    // throws on real MongoDB, so never hand one straight back.
    const qty = Number(item.quantity);
    if (!Number.isInteger(qty) || qty < 1) {
      console.warn(
        `Skipped restock of ${item.product_id} on order ${order.id}: ` +
        `unusable quantity ${JSON.stringify(item.quantity)}`
      );
      continue;
    }
    await products().updateOne(
      { _id: item.product_id },
      { $inc: { stock_quantity: qty } }
    );
  }
}

// Map an order document (items embedded) to the camelCase API shape.
const mapOrder = (o: any) => ({
  id: o.id,
  userId: o.user_id,
  totalAmount: Number(o.total_amount),
  // Breakdown is null on orders placed before it was recorded.
  subtotal: o.subtotal != null ? Number(o.subtotal) : null,
  shippingFee: o.shipping_fee != null ? Number(o.shipping_fee) : null,
  gstAmount: o.gst_amount != null ? Number(o.gst_amount) : null,
  discountAmount: o.discount_amount != null ? Number(o.discount_amount) : null,
  status: o.status,
  paymentStatus: o.payment_status,
  paymentMethod: o.payment_method,
  shippingAddress: o.shipping_address,
  createdAt: o.created_at,
  updatedAt: o.updated_at,
  items: (o.items || []).map((item: any) => ({
    id: item.id,
    productId: item.product_id,
    name: item.name,
    price: Number(item.price),
    quantity: item.quantity,
    imageUrl: item.image_url,
  })),
});

// Place a New Order. Inventory is decremented with conditional updates and a
// compensating restock on failure (keeps stock correct without needing a
// replica-set transaction, so it works on Atlas and the in-memory store alike).
router.post('/orders', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  const { items, paymentMethod, shippingAddress } = req.body;
  if (!items || !items.length || !paymentMethod || !shippingAddress) {
    return res.status(400).json({ error: 'Missing required order details' });
  }

  const isExpress = req.body.shippingMethod === 'express' || req.body.express === true;
  const orderId = `order-${crypto.randomUUID()}`;

  // Track decrements so we can roll them back if a later step fails.
  const decremented: { productId: string; quantity: number }[] = [];

  try {
    // 1. Price line items from DB and validate stock availability (read-only).
    let subtotal = 0;
    const orderItems: any[] = [];
    // Carries the *validated* quantity through to the decrement in step 3, so that
    // step can never act on a different number than this one priced.
    const lines: { productId: string; quantity: number }[] = [];
    for (const item of items) {
      const quantity = normaliseQuantity(item.quantity);
      if (quantity === null) {
        throw new Error(`Quantity for ${item.productId} must be a whole number of 1 or more`);
      }
      const product = await products().findOne({ _id: item.productId });
      if (!product) throw new Error(`Product not found: ${item.productId}`);
      // Externally-fulfilled products link out to another store; they carry no real
      // stock or price here and must never enter an order, whatever client asked.
      if (product.external_url) {
        throw new Error(`${product.name} is sold on ${product.external_store_name || 'an external store'} and cannot be ordered here`);
      }
      if (Number(product.stock_quantity) < quantity) {
        throw new Error(`Insufficient stock for ${product.name}. Available: ${product.stock_quantity}, Requested: ${quantity}`);
      }
      const unitPrice = round2(unitPriceFor(product, quantity));
      subtotal += unitPrice * quantity;
      orderItems.push({
        id: `oi-${crypto.randomUUID()}`,
        product_id: item.productId,
        name: item.name || product.name,
        price: unitPrice,
        quantity,
        image_url: item.imageUrl || null,
      });
      lines.push({ productId: item.productId, quantity });
    }
    subtotal = round2(subtotal);

    // 2. Authoritative delivery + totals (distance engine; client amount ignored).
    const addrStr = [
      shippingAddress.street, shippingAddress.city,
      shippingAddress.state, shippingAddress.pinCode, 'India',
    ].filter((p: any) => p && String(p).trim()).join(', ');
    const quote = await computeDelivery({
      subtotal,
      destLat: typeof shippingAddress.lat === 'number' ? shippingAddress.lat : undefined,
      destLng: typeof shippingAddress.lng === 'number' ? shippingAddress.lng : undefined,
      address: addrStr,
    });
    if (!quote.deliverable) {
      throw new Error(quote.label || 'Delivery is not available to the selected address.');
    }
    // Express is a premium ON TOP of the distance fee (the contract documented in
    // ../services/delivery), not a replacement for it.
    let shipping = quote.deliveryFee + (isExpress ? deliverySettings.expressSurcharge : 0);

    // Apply a promo code — validated server-side against active coupons so the
    // charged total matches (client-supplied discounts are never trusted).
    let discount = 0;
    const couponCode = (req.body.couponCode || '').toString().toUpperCase().trim();
    if (couponCode) {
      const c = await coupons().findOne({ code: couponCode, is_active: true });
      if (c) {
        if (c.type === 'percentage') discount = (subtotal * (Number(c.value) || 0)) / 100;
        else if (c.type === 'fixed') discount = Number(c.value) || 0;
        else if (c.type === 'free_shipping') shipping = 0;
        if (discount > subtotal) discount = subtotal;
      }
    }
    // GST applies to the discounted goods value, matching CartEntity.gstAmount.
    discount = round2(discount);
    shipping = round2(shipping);
    const gst = round2((subtotal - discount) * GST_RATE);
    const total = round2(subtotal + shipping + gst - discount);

    // 3. Decrement inventory with a guard against concurrent oversell.
    for (const line of lines) {
      const upd = await products().updateOne(
        { _id: line.productId, stock_quantity: { $gte: line.quantity } },
        { $inc: { stock_quantity: -line.quantity } }
      );
      if (upd.modifiedCount !== 1) {
        throw new Error(`Insufficient stock for product ${line.productId}`);
      }
      decremented.push({ productId: line.productId, quantity: line.quantity });
    }

    // 4. Persist the order (items embedded).
    const now = new Date();
    await orders().insertOne({
      _id: orderId,
      id: orderId,
      user_id: req.user.id,
      total_amount: total,
      subtotal,
      shipping_fee: shipping,
      gst_amount: gst,
      discount_amount: discount,
      status: 'pending',
      payment_status: 'pending',
      payment_method: paymentMethod,
      shipping_address: shippingAddress,
      items: orderItems,
      created_at: now,
      updated_at: now,
    });

    res.status(201).json({ id: orderId, message: 'Order placed successfully' });
  } catch (err: any) {
    // Compensating restock for any decrements already applied.
    for (const d of decremented) {
      try {
        await products().updateOne({ _id: d.productId }, { $inc: { stock_quantity: d.quantity } });
      } catch { /* best-effort */ }
    }
    console.error('Order creation error:', err);
    res.status(400).json({ error: err.message });
  }
});

// Get User Orders History
router.get('/orders', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const rows = await orders().find({ user_id: req.user.id }).sort({ created_at: -1 }).toArray();
    res.json(rows.map(mapOrder));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get All System Orders (Admin only)
// NOTE: MUST be registered before GET '/orders/:id' so ':id' doesn't match "admin".
router.get('/orders/admin', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  try {
    const rows = await orders().find({}).sort({ created_at: -1 }).toArray();
    res.json(rows.map(mapOrder));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get Single Order Details
router.get('/orders/:id', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const order = await orders().findOne({ _id: req.params.id });
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    if (order.user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Forbidden' });
    }
    res.json(mapOrder(order));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Cancel Order (owner only; restocks inventory)
router.post('/orders/:id/cancel', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const order = await orders().findOne({ _id: req.params.id });
    if (!order) return res.status(404).json({ error: 'Order not found' });
    if (order.user_id !== req.user.id) return res.status(403).json({ error: 'Forbidden' });

    const cancellable = ['pending', 'confirmed', 'processing'];
    if (!cancellable.includes(order.status)) {
      return res.status(400).json({ error: `Order cannot be cancelled while it is ${order.status}` });
    }

    await restockOrder(order);

    const now = new Date();
    await orders().updateOne({ _id: req.params.id }, { $set: { status: 'cancelled', updated_at: now } });

    res.json({ order: mapOrder({ ...order, status: 'cancelled', updated_at: now }) });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Update Order Status (Admin only)
router.put('/orders/admin/:id/status', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  const { id } = req.params;
  const { status } = req.body;
  if (!status) return res.status(400).json({ error: 'Status is required' });
  if (!ORDER_STATUSES.includes(status)) {
    return res.status(400).json({
      error: `Invalid status "${status}". Expected one of: ${ORDER_STATUSES.join(', ')}`,
    });
  }

  try {
    const existing = await orders().findOne({ _id: id });
    if (!existing) return res.status(404).json({ error: 'Order not found' });

    // Cancelling must return the goods to stock, exactly as the customer-facing
    // cancel route does. Guarded on the transition so re-saving an already
    // cancelled order cannot restock it twice.
    if (status === 'cancelled' && existing.status !== 'cancelled') {
      await restockOrder(existing);
    }

    // Reopening would hand out stock that cancelling already returned, and a
    // re-decrement can fail halfway through a multi-line order. Refuse it.
    if (existing.status === 'cancelled' && status !== 'cancelled') {
      return res.status(409).json({
        error: 'A cancelled order cannot be reopened. Please place a new order instead.',
      });
    }

    await orders().updateOne({ _id: id }, { $set: { status, updated_at: new Date() } });
    res.json({ message: 'Order status updated successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get Admin Dashboard Stats (Admin only)
router.get('/admin/stats', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  try {
    const allOrders = await orders().find({}).sort({ created_at: -1 }).toArray();
    const customers = await users().find({ role: 'customer' }).sort({ created_at: -1 }).toArray();
    const nameById: Record<string, string> = {};
    for (const u of customers) nameById[u.id] = u.name;
    const activeProducts = await products().find({ is_active: true }).toArray();

    const totalRevenue = allOrders
      .filter((o) => o.status !== 'cancelled')
      .reduce((sum, o) => sum + (Number(o.total_amount) || 0), 0);

    res.json({
      totalOrders: allOrders.length,
      totalRevenue,
      totalCustomers: customers.length,
      totalProducts: activeProducts.length,
      recentOrders: allOrders.slice(0, 5).map((row) => {
        const id = String(row.id ?? '');
        return {
          id,
          orderNumber: id.length > 8 ? `TH-${id.substring(id.length - 8).toUpperCase()}` : id.toUpperCase(),
          userName: nameById[row.user_id] || 'Guest',
          total: Number(row.total_amount) || 0,
          status: row.status,
        };
      }),
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get All Customers (Admin only)
router.get('/admin/customers', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  try {
    const rows = await users().find({ role: 'customer' }).sort({ created_at: -1 }).toArray();
    res.json(rows.map((u) => ({
      id: u.id,
      email: u.email,
      name: u.name,
      phone: u.phone,
      photoUrl: u.photo_url,
      role: u.role,
      isBlocked: u.is_blocked,
      createdAt: u.created_at,
    })));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Block/Unblock Customer (Admin only)
router.put('/admin/customers/:id/block', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  const { id } = req.params;
  const blocked = !!req.body.isBlocked;
  try {
    const target = await users().findOne({ _id: id });
    if (!target) return res.status(404).json({ error: 'Customer not found' });
    // Blocking an admin is unrecoverable through the API - login would 403 and
    // there is no unblock route reachable without logging in.
    if (blocked && target.role === 'admin') {
      return res.status(403).json({ error: 'Admin accounts cannot be blocked' });
    }
    await users().updateOne({ _id: id }, { $set: { is_blocked: blocked } });
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Full Customer Details (Admin only) — everything captured at registration.
router.get('/admin/customers/:id', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  try {
    const u = await users().findOne({ _id: req.params.id });
    if (!u) return res.status(404).json({ error: 'Customer not found' });
    res.json({
      id: u.id,
      email: u.email,
      name: u.name,
      phone: u.phone,
      photoUrl: u.photo_url,
      role: u.role,
      isBlocked: u.is_blocked,
      isEmailVerified: u.is_email_verified,
      createdAt: u.created_at,
      lastLoginAt: u.last_login_at,
      addresses: (u.addresses || []).map((a: any) => ({
        id: a.id, type: a.type, fullName: a.full_name, phone: a.phone,
        street: a.street, city: a.city, state: a.state, country: a.country,
        pinCode: a.pin_code, isDefault: a.is_default,
      })),
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a Customer (Admin only). Never deletes admin accounts.
router.delete('/admin/customers/:id', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  try {
    await users().deleteOne({ _id: req.params.id, role: 'customer' });
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
