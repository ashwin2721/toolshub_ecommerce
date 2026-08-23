import { Router } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { users } from '../db/mongo';
import { authenticateToken, requireAdmin, AuthRequest } from '../middlewares/auth';

const router = Router();

// Read the JWT secret from the environment and fail fast at startup if it is
// missing. No hardcoded fallback — an unset secret is a fatal misconfiguration.
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error('FATAL: JWT_SECRET environment variable is not set. Refusing to start.');
}

// Map an embedded address subdocument to the camelCase API shape.
const mapAddress = (a: any) => ({
  id: a.id,
  type: a.type,
  fullName: a.full_name,
  phone: a.phone,
  street: a.street,
  city: a.city,
  state: a.state,
  country: a.country,
  pinCode: a.pin_code,
  isDefault: a.is_default,
});

// Register Endpoint
router.post('/register', async (req, res) => {
  const { email, password, name, phone } = req.body;
  if (!email || !password || !name) {
    return res.status(400).json({ error: 'Email, password, and name are required' });
  }

  try {
    const existing = await users().findOne({ email });
    if (existing) {
      return res.status(400).json({ error: 'An account already exists with this email' });
    }

    const userId = `user-${crypto.randomUUID()}`;
    const passwordHash = bcrypt.hashSync(password, 10);
    const now = new Date();

    await users().insertOne({
      _id: userId,
      id: userId,
      email,
      password_hash: passwordHash,
      name,
      phone: phone || null,
      photo_url: null,
      role: 'customer',
      is_email_verified: false,
      is_blocked: false,
      addresses: [],
      created_at: now,
    });

    const token = jwt.sign({ id: userId, email, role: 'customer' }, JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({
      token,
      user: { id: userId, email, name, phone, role: 'customer', createdAt: now },
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Login Endpoint
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    const user = await users().findOne({ email });
    if (!user) {
      return res.status(400).json({ error: 'No account found with this email' });
    }
    if (user.is_blocked) {
      return res.status(403).json({ error: 'This account has been disabled' });
    }

    const match = bcrypt.compareSync(password, user.password_hash);
    if (!match) {
      return res.status(400).json({ error: 'Incorrect password. Please try again' });
    }

    await users().updateOne({ _id: user._id }, { $set: { last_login_at: new Date() } });

    const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        photoUrl: user.photo_url,
        role: user.role,
        isEmailVerified: user.is_email_verified,
        createdAt: user.created_at,
      },
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get Current User Profile (with addresses)
router.get('/me', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const user = await users().findOne({ _id: req.user.id });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      photoUrl: user.photo_url,
      role: user.role,
      isEmailVerified: user.is_email_verified,
      createdAt: user.created_at,
      addresses: (user.addresses || []).map(mapAddress),
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Add Address Endpoint (addresses are embedded in the user document)
router.post('/addresses', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
  const { type, fullName, phone, street, city, state, country, pinCode, isDefault } = req.body;

  if (!fullName || !phone || !street || !city || !state || !pinCode) {
    return res.status(400).json({ error: 'Missing required address fields' });
  }

  try {
    const user = await users().findOne({ _id: req.user.id });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const addrId = `addr-${crypto.randomUUID()}`;
    const newAddr = {
      id: addrId,
      type: type || 'home',
      full_name: fullName,
      phone,
      street,
      city,
      state,
      country: country || 'India',
      pin_code: pinCode,
      is_default: !!isDefault,
    };

    let addresses: any[] = user.addresses || [];
    if (isDefault) addresses = addresses.map((a) => ({ ...a, is_default: false }));
    addresses.push(newAddr);
    await users().updateOne({ _id: req.user.id }, { $set: { addresses } });

    res.status(201).json({
      id: addrId, type, fullName, phone, street, city, state, country, pinCode, isDefault: !!isDefault,
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Delete an Address (only the authenticated user's own address)
router.delete('/addresses/:id', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const user = await users().findOne({ _id: req.user.id });
    if (user) {
      const addresses = (user.addresses || []).filter((a: any) => a.id !== req.params.id);
      await users().updateOne({ _id: req.user.id }, { $set: { addresses } });
    }
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Set an Address as Default (unsets the user's other addresses)
router.patch('/addresses/:id/default', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const user = await users().findOne({ _id: req.user.id });
    if (user) {
      const addresses = (user.addresses || []).map((a: any) => ({ ...a, is_default: a.id === req.params.id }));
      await users().updateOne({ _id: req.user.id }, { $set: { addresses } });
    }
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Forgot Password (privacy-preserving; no account existence leak)
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  try {
    const user = await users().findOne({ email });
    if (user) {
      const resetToken = crypto.randomBytes(32).toString('hex');
      // TODO: Persist this reset token with an expiry and email it to the user.
      console.log(`[Password Reset] Generated reset token for ${user.email}: ${resetToken}`);
    }
    res.json({
      success: true,
      message: 'If an account with that email exists, a reset link has been sent.',
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new Admin account — admins only (an admin promotes/creates admins).
router.post('/admins', authenticateToken, requireAdmin, async (req: AuthRequest, res) => {
  const { name, email, password, phone } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email, and password are required' });
  }
  if (String(password).length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  try {
    const existing = await users().findOne({ email });
    if (existing) {
      return res.status(400).json({ error: 'An account already exists with this email' });
    }

    const userId = `user-${crypto.randomUUID()}`;
    const now = new Date();
    await users().insertOne({
      _id: userId,
      id: userId,
      email,
      password_hash: bcrypt.hashSync(password, 10),
      name,
      phone: phone || null,
      photo_url: null,
      role: 'admin',
      is_email_verified: true,
      is_blocked: false,
      addresses: [],
      created_at: now,
    });

    res.status(201).json({ id: userId, email, name, role: 'admin', createdAt: now });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Delete the Authenticated User's Account
router.delete('/account', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  try {
    await users().deleteOne({ _id: req.user.id });
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
