// Load environment variables BEFORE any route module is imported. Route modules
// (e.g. ./routes/auth) read process.env at module-load time, and ES/CJS import
// evaluation runs those imports before the module body — so dotenv must be a
// side-effect import on the very first line, not a dotenv.config() call below.
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import path from 'path';
import crypto from 'crypto';
import authRouter from './routes/auth';
import productRouter from './routes/products';
import orderRouter from './routes/orders';
import assistantRouter from './routes/assistant';
import { authenticateToken, requireAdmin, AuthRequest } from './middlewares/auth';
import {
  deliverySettings,
  updateDeliverySettings,
  computeDelivery,
  forwardGeocode,
} from './services/delivery';
import { connectDB, ping, supportTickets, isMemoryMode } from './db/mongo';

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());

// Basic logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Register API routers
app.use('/api/auth', authRouter);
app.use('/api', productRouter);
app.use('/api', orderRouter);
app.use('/api', assistantRouter);

// Tool services mock booking endpoint
app.post('/api/tool-services', (req, res) => {
  const { bookingId } = req.body;
  res.status(201).json({ success: true, bookingId });
});

// Support tickets endpoint
app.post('/api/support-tickets', async (req, res) => {
  const { subject, message, category } = req.body;
  if (!subject || !message) {
    return res.status(400).json({ error: 'Subject and message are required' });
  }

  const ticketId = `ticket-${crypto.randomUUID()}`;

  try {
    // Best-effort persistence into the support_tickets collection.
    await supportTickets().insertOne({
      _id: ticketId,
      id: ticketId,
      subject,
      message,
      category: category || null,
      status: 'open',
      created_at: new Date(),
    });
  } catch (err: any) {
    // Persistence is best-effort; still return a real generated id per contract.
    console.warn(`Failed to persist support ticket ${ticketId}: ${err.message}`);
  }

  res.status(201).json({ success: true, ticketId });
});

// ── Storefront content settings (editable from the Admin panel) ──────────────
// Kept in memory (resets on restart); the admin edits the promo/hero copy that
// the app's announcement bar and home hero read from GET /api/settings.
let storeSettings = {
  announcementText: 'Get 50% Off on Selected Items',
  announcementCtaLabel: 'Shop Now',
  heroTitle: 'Grab Upto 50% Off On Selected Power Tools',
  heroSubtitle: 'Top brands. Pro-grade gear. Delivered fast.',
  heroCtaLabel: 'Buy Now',
};

app.get('/api/settings', (req, res) => {
  res.json(storeSettings);
});

app.put('/api/settings', authenticateToken, requireAdmin, (req: AuthRequest, res) => {
  const allowed = [
    'announcementText',
    'announcementCtaLabel',
    'heroTitle',
    'heroSubtitle',
    'heroCtaLabel',
  ];
  for (const key of allowed) {
    if (typeof req.body[key] === 'string') {
      (storeSettings as any)[key] = req.body[key];
    }
  }
  res.json(storeSettings);
});

// ── Reverse geocoding ──────────────────────────────────────────────────────
// Turns a device GPS position (lat/lon) into a street/city/state/PIN address.
// Proxied server-side (via OpenStreetMap Nominatim) so the web client avoids
// cross-origin restrictions and no API key is exposed to the browser.
app.get('/api/geocode', async (req, res) => {
  const lat = parseFloat(String(req.query.lat));
  const lon = parseFloat(String(req.query.lon));
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return res.status(400).json({ error: 'Valid lat and lon are required' });
  }
  try {
    const url =
      `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}` +
      `&format=json&addressdetails=1&zoom=18`;
    const r = await fetch(url, {
      headers: { 'User-Agent': 'ToolsHub/1.0 (store address autofill)' },
    });
    if (!r.ok) {
      return res.status(502).json({ error: 'Geocoding service unavailable' });
    }
    const data: any = await r.json();
    const a = data.address || {};
    const street =
      [a.house_number, a.road].filter(Boolean).join(' ') ||
      a.neighbourhood ||
      a.suburb ||
      a.hamlet ||
      '';
    res.json({
      street,
      city: a.city || a.town || a.village || a.municipality || a.county || '',
      state: a.state || a.region || '',
      pinCode: a.postcode || '',
      display: data.display_name || '',
    });
  } catch (err: any) {
    res.status(500).json({ error: err?.message || 'Geocoding failed' });
  }
});

// Forward-geocode a free-text address into coordinates (used by the admin
// delivery screen to resolve the shop's location from a typed address).
app.get('/api/geocode-forward', async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (!q) return res.status(400).json({ error: 'Query "q" is required' });
  try {
    const hit = await forwardGeocode(q);
    if (!hit) return res.status(404).json({ error: 'No location found for that address' });
    res.json({ lat: hit.lat, lng: hit.lng });
  } catch (err: any) {
    res.status(500).json({ error: err?.message || 'Geocoding failed' });
  }
});

// ── Delivery-fee settings (admin-managed, distance-based) ───────────────────
app.get('/api/delivery-settings', (req, res) => {
  res.json(deliverySettings);
});

app.put('/api/delivery-settings', authenticateToken, requireAdmin, (req: AuthRequest, res) => {
  res.json(updateDeliverySettings(req.body || {}));
});

// Live delivery quote for a destination: distance from the shop + the fee that
// applies, computed with the exact same engine the order total uses.
app.get('/api/delivery-quote', async (req, res) => {
  const subtotal = parseFloat(String(req.query.subtotal ?? '0')) || 0;
  const lat = parseFloat(String(req.query.lat));
  const lng = parseFloat(String(req.query.lng));
  const address = req.query.address ? String(req.query.address) : undefined;
  try {
    const quote = await computeDelivery({
      subtotal,
      destLat: Number.isFinite(lat) ? lat : undefined,
      destLng: Number.isFinite(lng) ? lng : undefined,
      address,
    });
    res.json(quote);
  } catch (err: any) {
    res.status(500).json({ error: err?.message || 'Quote failed' });
  }
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await ping();
    res.json({ status: 'UP', database: isMemoryMode() ? 'IN-MEMORY' : 'CONNECTED' });
  } catch (err: any) {
    res.status(500).json({ status: 'DOWN', error: err.message });
  }
});

// Connect to MongoDB (or the in-memory fallback), seed if empty, then listen.
connectDB()
  .catch((err) => console.error('Database initialization error:', err))
  .finally(() => {
    app.listen(PORT, () => {
      console.log(`=========================================`);
      console.log(`ToolsHub Backend API Server running on port ${PORT}`);
      console.log(`URL: http://localhost:${PORT}`);
      console.log(`Database: ${isMemoryMode() ? 'IN-MEMORY (set MONGODB_URI for MongoDB)' : 'MongoDB'}`);
      console.log(`=========================================`);
    });
  });
