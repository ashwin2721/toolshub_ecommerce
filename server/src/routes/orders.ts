import { Router } from 'express';
import crypto from 'crypto';
import pool, { query } from '../db';
import { authenticateToken, requireAdmin, AuthRequest } from '../middlewares/auth';
import { computeDelivery, deliverySettings } from '../services/delivery';

const router = Router();

// Server-side money constants. Totals are ALWAYS recomputed from these + DB
// prices; client amounts are never trusted. The delivery fee itself is computed
// by the admin-managed distance engine (see ../services/delivery).
const GST_RATE = 0.18;

// Place a New Order (ACID compliant transaction)
router.post('/orders', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  const { items, paymentMethod, shippingAddress } = req.body;
  if (!items || !items.length || !paymentMethod || !shippingAddress) {
    return res.status(400).json({ error: 'Missing required order details' });
  }

  // Whether the client requested express delivery. Client-supplied item prices and
  // totalAmount are intentionally ignored and recomputed authoritatively below.
  const isExpress = req.body.shippingMethod === 'express' || req.body.express === true;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const orderId = `order-${crypto.randomUUID()}`;

    // 1. Insert Order record first (to avoid foreign key constraint issues in order_items).
    //    total_amount is a placeholder and is recomputed authoritatively once line items
    //    are priced from the products table below.
    await client.query(
      `INSERT INTO orders (id, user_id, total_amount, payment_method, shipping_address, status, payment_status)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [orderId, req.user.id, 0, paymentMethod, JSON.stringify(shippingAddress), 'pending', 'pending']
    );

    // 2. Process items, lock stock rows, verify inventory, decrement stock, insert order items,
    //    and accumulate the authoritative subtotal from DB prices.
    let subtotal = 0;
    for (const item of items) {
      const prodRes = await client.query(
        'SELECT stock_quantity, price, name FROM products WHERE id = $1 FOR UPDATE',
        [item.productId]
      );

      if (prodRes.rows.length === 0) {
        throw new Error(`Product not found: ${item.productId}`);
      }

      const product = prodRes.rows[0];
      if (product.stock_quantity < item.quantity) {
        throw new Error(`Insufficient stock for ${product.name}. Available: ${product.stock_quantity}, Requested: ${item.quantity}`);
      }

      // Authoritative unit price from the products table (client-supplied price ignored).
      const unitPrice = parseFloat(product.price);
      subtotal += unitPrice * item.quantity;

      // Decrement stock
      await client.query(
        'UPDATE products SET stock_quantity = stock_quantity - $1 WHERE id = $2',
        [item.quantity, item.productId]
      );

      // Insert Order Item record (price sourced from DB, not the client)
      await client.query(
        `INSERT INTO order_items (order_id, product_id, name, price, quantity, image_url)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [orderId, item.productId, item.name || product.name, unitPrice, item.quantity, item.imageUrl || null]
      );
    }

    // 3. Authoritative total recompute. Client totalAmount is ignored entirely.
    //    Delivery is priced by distance from the shop to the shipping address
    //    using the admin-configured rules (free radius, per-km, third-party…).
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
    // TODO: server-side coupon validation is not implemented yet, so any client-supplied
    // discount is ignored here to prevent underpayment.
    const discount = 0;
    const total = subtotal + shipping + gst - discount;

    await client.query(
      'UPDATE orders SET total_amount = $1 WHERE id = $2',
      [total, orderId]
    );

    await client.query('COMMIT');
    res.status(201).json({ id: orderId, message: 'Order placed successfully' });
  } catch (err: any) {
    console.error('Order creation error:', err);
    await client.query('ROLLBACK');
    res.status(400).json({ error: err.message });
  } finally {
    client.release();
  }
});

// Get User Orders History
router.get('/orders', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const ordersRes = await query(
      'SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC',
      [req.user.id]
    );
    
    const orders = [];
    for (const order of ordersRes.rows) {
      const itemsRes = await query('SELECT * FROM order_items WHERE order_id = $1', [order.id]);
      orders.push({
        id: order.id,
        userId: order.user_id,
        totalAmount: parseFloat(order.total_amount),
        status: order.status,
        paymentStatus: order.payment_status,
        paymentMethod: order.payment_method,
        shippingAddress: order.shipping_address,
        createdAt: order.created_at,
        updatedAt: order.updated_at,
        items: itemsRes.rows.map(item => ({
          id: item.id,
          productId: item.product_id,
          name: item.name,
          price: parseFloat(item.price),
          quantity: item.quantity,
          imageUrl: item.image_url
        }))
      });
    }

    res.json(orders);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get All System Orders (Admin only)
// NOTE: This MUST be registered before GET '/orders/:id', otherwise ':id' would
// match the literal "admin" and shadow this route.
router.get('/orders/admin', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  try {
    const ordersRes = await query('SELECT * FROM orders ORDER BY created_at DESC');
    const orders = [];
    for (const order of ordersRes.rows) {
      const itemsRes = await query('SELECT * FROM order_items WHERE order_id = $1', [order.id]);
      orders.push({
        id: order.id,
        userId: order.user_id,
        totalAmount: parseFloat(order.total_amount),
        status: order.status,
        paymentStatus: order.payment_status,
        paymentMethod: order.payment_method,
        shippingAddress: order.shipping_address,
        createdAt: order.created_at,
        updatedAt: order.updated_at,
        items: itemsRes.rows.map(item => ({
          id: item.id,
          productId: item.product_id,
          name: item.name,
          price: parseFloat(item.price),
          quantity: item.quantity,
          imageUrl: item.image_url
        }))
      });
    }
    res.json(orders);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get Single Order Details
router.get('/orders/:id', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  const { id } = req.params;

  try {
    const orderRes = await query('SELECT * FROM orders WHERE id = $1', [id]);
    if (orderRes.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderRes.rows[0];

    // Ensure user owns the order, or is an admin
    if (order.user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const itemsRes = await query('SELECT * FROM order_items WHERE order_id = $1', [id]);

    res.json({
      id: order.id,
      userId: order.user_id,
      totalAmount: parseFloat(order.total_amount),
      status: order.status,
      paymentStatus: order.payment_status,
      paymentMethod: order.payment_method,
      shippingAddress: order.shipping_address,
      createdAt: order.created_at,
      updatedAt: order.updated_at,
      items: itemsRes.rows.map(item => ({
        id: item.id,
        productId: item.product_id,
        name: item.name,
        price: parseFloat(item.price),
        quantity: item.quantity,
        imageUrl: item.image_url
      }))
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Cancel Order (owner only; ACID transaction with inventory restock)
router.post('/orders/:id/cancel', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  const { id } = req.params;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const orderRes = await client.query('SELECT * FROM orders WHERE id = $1 FOR UPDATE', [id]);
    if (orderRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderRes.rows[0];

    // Ensure the order belongs to the requesting user.
    if (order.user_id !== req.user.id) {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'Forbidden' });
    }

    // Only pending/confirmed/processing orders may be cancelled.
    const cancellable = ['pending', 'confirmed', 'processing'];
    if (!cancellable.includes(order.status)) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `Order cannot be cancelled while it is ${order.status}` });
    }

    const itemsRes = await client.query('SELECT * FROM order_items WHERE order_id = $1', [id]);

    // Restock inventory for each line item (product_id may be null if the product was removed).
    for (const item of itemsRes.rows) {
      if (item.product_id) {
        await client.query(
          'UPDATE products SET stock_quantity = stock_quantity + $1 WHERE id = $2',
          [item.quantity, item.product_id]
        );
      }
    }

    const updatedRes = await client.query(
      "UPDATE orders SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *",
      [id]
    );

    await client.query('COMMIT');

    const updated = updatedRes.rows[0];
    res.json({
      order: {
        id: updated.id,
        userId: updated.user_id,
        totalAmount: parseFloat(updated.total_amount),
        status: updated.status,
        paymentStatus: updated.payment_status,
        paymentMethod: updated.payment_method,
        shippingAddress: updated.shipping_address,
        createdAt: updated.created_at,
        updatedAt: updated.updated_at,
        items: itemsRes.rows.map(item => ({
          id: item.id,
          productId: item.product_id,
          name: item.name,
          price: parseFloat(item.price),
          quantity: item.quantity,
          imageUrl: item.image_url
        }))
      }
    });
  } catch (err: any) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// Update Order Status (Admin only)
router.put('/orders/admin/:id/status', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ error: 'Status is required' });
  }

  try {
    const existing = await query('SELECT id FROM orders WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    await query(
      'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [status, id]
    );

    res.json({ message: 'Order status updated successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get Admin Dashboard Stats (Admin only)
router.get('/admin/stats', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  try {
    // Compute stats from the raw rows in JS rather than SQL aggregates, so this
    // works against both real Postgres and the in-memory mock DB (which does not
    // support COUNT()/SUM()/JOIN and would otherwise return empty rows -> crash).
    const ordersRes = await query('SELECT * FROM orders ORDER BY created_at DESC');
    const orders: any[] = ordersRes.rows || [];

    const usersRes = await query(
      "SELECT id, name FROM users WHERE role = 'customer' ORDER BY created_at DESC");
    const customers: any[] = usersRes.rows || [];
    const nameById: Record<string, string> = {};
    for (const u of customers) nameById[u.id] = u.name;

    const productsRes = await query(
      'SELECT id FROM products WHERE is_active = true ORDER BY created_at DESC LIMIT $1',
      [100000]);
    const products: any[] = productsRes.rows || [];

    const totalRevenue = orders
      .filter((o) => o.status !== 'cancelled')
      .reduce((sum, o) => sum + (parseFloat(o.total_amount) || 0), 0);

    res.json({
      totalOrders: orders.length,
      totalRevenue,
      totalCustomers: customers.length,
      totalProducts: products.length,
      recentOrders: orders.slice(0, 5).map((row) => {
        const id = String(row.id ?? '');
        return {
          id,
          orderNumber: id.length > 8
              ? `TH-${id.substring(id.length - 8).toUpperCase()}`
              : id.toUpperCase(),
          userName: nameById[row.user_id] || 'Guest',
          total: parseFloat(row.total_amount) || 0,
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
    const result = await query(
      "SELECT id, email, name, phone, photo_url, role, is_blocked as \"isBlocked\", created_at as \"createdAt\" FROM users WHERE role = 'customer' ORDER BY created_at DESC"
    );
    res.json(result.rows);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Block/Unblock Customer (Admin only)
router.put('/admin/customers/:id/block', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  const { id } = req.params;
  const { isBlocked } = req.body;
  try {
    await query('UPDATE users SET is_blocked = $1 WHERE id = $2', [isBlocked, id]);
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
