import { Router } from 'express';
import crypto from 'crypto';
import { orders, products, users } from '../db/mongo';
import { authenticateToken, requireAdmin, AuthRequest } from '../middlewares/auth';
import { computeDelivery, deliverySettings } from '../services/delivery';

const router = Router();

// Server-side money constants. Totals are ALWAYS recomputed from these + DB
// prices; client amounts are never trusted. The delivery fee itself is computed
// by the admin-managed distance engine (see ../services/delivery).
const GST_RATE = 0.18;

// Map an order document (items embedded) to the camelCase API shape.
const mapOrder = (o: any) => ({
  id: o.id,
  userId: o.user_id,
  totalAmount: Number(o.total_amount),
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
    for (const item of items) {
      const product = await products().findOne({ _id: item.productId });
      if (!product) throw new Error(`Product not found: ${item.productId}`);
      if (product.stock_quantity < item.quantity) {
        throw new Error(`Insufficient stock for ${product.name}. Available: ${product.stock_quantity}, Requested: ${item.quantity}`);
      }
      const unitPrice = Number(product.price);
      subtotal += unitPrice * item.quantity;
      orderItems.push({
        id: `oi-${crypto.randomUUID()}`,
        product_id: item.productId,
        name: item.name || product.name,
        price: unitPrice,
        quantity: item.quantity,
        image_url: item.imageUrl || null,
      });
    }

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
    const shipping = isExpress ? deliverySettings.expressSurcharge : quote.deliveryFee;
    const gst = subtotal * GST_RATE;
    const discount = 0;
    const total = subtotal + shipping + gst - discount;

    // 3. Decrement inventory with a guard against concurrent oversell.
    for (const item of items) {
      const upd = await products().updateOne(
        { _id: item.productId, stock_quantity: { $gte: item.quantity } },
        { $inc: { stock_quantity: -item.quantity } }
      );
      if (upd.modifiedCount !== 1) {
        throw new Error(`Insufficient stock for product ${item.productId}`);
      }
      decremented.push({ productId: item.productId, quantity: item.quantity });
    }

    // 4. Persist the order (items embedded).
    const now = new Date();
    await orders().insertOne({
      _id: orderId,
      id: orderId,
      user_id: req.user.id,
      total_amount: total,
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

    // Restock each line item (product_id may be null if the product was removed).
    for (const item of order.items || []) {
      if (item.product_id) {
        await products().updateOne({ _id: item.product_id }, { $inc: { stock_quantity: item.quantity } });
      }
    }

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

  try {
    const existing = await orders().findOne({ _id: id });
    if (!existing) return res.status(404).json({ error: 'Order not found' });
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
  const { isBlocked } = req.body;
  try {
    await users().updateOne({ _id: id }, { $set: { is_blocked: isBlocked } });
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
