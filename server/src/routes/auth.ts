import { Router } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { query } from '../db';
import { authenticateToken, AuthRequest } from '../middlewares/auth';

const router = Router();

// Read the JWT secret from the environment and fail fast at startup if it is
// missing. No hardcoded fallback — an unset secret is a fatal misconfiguration.
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error('FATAL: JWT_SECRET environment variable is not set. Refusing to start.');
}

// Register Endpoint
router.post('/register', async (req, res) => {
  const { email, password, name, phone } = req.body;
  if (!email || !password || !name) {
    return res.status(400).json({ error: 'Email, password, and name are required' });
  }

  try {
    // Check if user exists
    const existing = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'An account already exists with this email' });
    }

    const userId = `user-${crypto.randomUUID()}`;
    const passwordHash = bcrypt.hashSync(password, 10);

    await query(
      `INSERT INTO users (id, email, password_hash, name, phone, role) 
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [userId, email, passwordHash, name, phone || null, 'customer']
    );

    const token = jwt.sign({ id: userId, email, role: 'customer' }, JWT_SECRET, { expiresIn: '7d' });
    
    res.status(201).json({
      token,
      user: {
        id: userId,
        email,
        name,
        phone,
        role: 'customer',
        createdAt: new Date(),
      }
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
    const result = await query(
      'SELECT id, email, password_hash, name, phone, photo_url, role, is_email_verified, is_blocked, created_at FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'No account found with this email' });
    }

    const user = result.rows[0];
    if (user.is_blocked) {
      return res.status(403).json({ error: 'This account has been disabled' });
    }

    const match = bcrypt.compareSync(password, user.password_hash);
    if (!match) {
      return res.status(400).json({ error: 'Incorrect password. Please try again' });
    }

    // Update last login
    await query('UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1', [user.id]);

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
      }
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get Current User Profile (with addresses)
router.get('/me', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const result = await query(
      'SELECT id, email, name, phone, photo_url, role, is_email_verified, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = result.rows[0];
    // Fetch user addresses
    const addrResult = await query('SELECT * FROM addresses WHERE user_id = $1', [req.user.id]);

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      photoUrl: user.photo_url,
      role: user.role,
      isEmailVerified: user.is_email_verified,
      createdAt: user.created_at,
      addresses: addrResult.rows.map(row => ({
        id: row.id,
        type: row.type,
        fullName: row.full_name,
        phone: row.phone,
        street: row.street,
        city: row.city,
        state: row.state,
        country: row.country,
        pinCode: row.pin_code,
        isDefault: row.is_default
      }))
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Add Address Endpoint
router.post('/addresses', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
  const { type, fullName, phone, street, city, state, country, pinCode, isDefault } = req.body;

  if (!fullName || !phone || !street || !city || !state || !pinCode) {
    return res.status(400).json({ error: 'Missing required address fields' });
  }

  try {
    const addrId = `addr-${crypto.randomUUID()}`;

    if (isDefault) {
      // Set other addresses to not default
      await query('UPDATE addresses SET is_default = false WHERE user_id = $1', [req.user.id]);
    }

    await query(
      `INSERT INTO addresses (id, user_id, type, full_name, phone, street, city, state, country, pin_code, is_default)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [addrId, req.user.id, type || 'home', fullName, phone, street, city, state, country || 'India', pinCode, !!isDefault]
    );

    res.status(201).json({
      id: addrId,
      type,
      fullName,
      phone,
      street,
      city,
      state,
      country,
      pinCode,
      isDefault: !!isDefault
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Delete an Address (only the authenticated user's own address)
router.delete('/addresses/:id', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
  const { id } = req.params;

  try {
    await query('DELETE FROM addresses WHERE id = $1 AND user_id = $2', [id, req.user.id]);
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Set an Address as Default (unsets the user's other addresses)
router.patch('/addresses/:id/default', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
  const { id } = req.params;

  try {
    // Clear the default flag on all of this user's addresses first
    await query('UPDATE addresses SET is_default = false WHERE user_id = $1', [req.user.id]);
    // Then mark the chosen address as default (scoped to this user)
    await query('UPDATE addresses SET is_default = true WHERE id = $1 AND user_id = $2', [id, req.user.id]);
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Forgot Password (privacy-preserving; no Firebase)
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  try {
    const result = await query('SELECT id, email FROM users WHERE email = $1', [email]);
    if (result.rows.length > 0) {
      const user = result.rows[0];
      const resetToken = crypto.randomBytes(32).toString('hex');
      // TODO: Persist this reset token with an expiry and deliver it to the user
      //       by email. Email delivery is not yet implemented.
      console.log(`[Password Reset] Generated reset token for ${user.email}: ${resetToken}`);
    }

    // Always return the same response so account existence is not leaked
    res.json({
      success: true,
      message: 'If an account with that email exists, a reset link has been sent.'
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Delete the Authenticated User's Account
router.delete('/account', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

  try {
    // Addresses and wishlists cascade; orders are detached via ON DELETE SET NULL
    await query('DELETE FROM users WHERE id = $1', [req.user.id]);
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
