// ── MongoDB data layer ──────────────────────────────────────────────────────
// Uses the official `mongodb` driver when MONGODB_URI is set (e.g. an Atlas
// cluster). When it is not set — or the connection fails — the server falls
// back to a lightweight in-memory store implementing the same subset of the
// collection API, so it runs with zero setup for local development (data
// resets on restart, exactly like the previous mock DB).

import { MongoClient, Db } from 'mongodb';
import bcrypt from 'bcrypt';
import { demoCategories, demoProducts } from './demoData';

// ── Minimal collection interface both backends satisfy ──────────────────────
interface Cursor {
  sort(spec: Record<string, 1 | -1>): Cursor;
  skip(n: number): Cursor;
  limit(n: number): Cursor;
  toArray(): Promise<any[]>;
}
export interface Coll {
  findOne(filter?: any): Promise<any | null>;
  find(filter?: any): Cursor;
  insertOne(doc: any): Promise<{ insertedId: any }>;
  insertMany(docs: any[]): Promise<any>;
  updateOne(filter: any, update: any): Promise<{ matchedCount: number; modifiedCount: number }>;
  updateMany(filter: any, update: any): Promise<{ matchedCount: number; modifiedCount: number }>;
  deleteOne(filter: any): Promise<{ deletedCount: number }>;
  deleteMany(filter: any): Promise<{ deletedCount: number }>;
  countDocuments(filter?: any): Promise<number>;
}

// ── Filter / update evaluation for the in-memory backend ────────────────────
function matchField(value: any, cond: any): boolean {
  if (cond instanceof RegExp) return cond.test(String(value ?? ''));
  if (cond !== null && typeof cond === 'object' && !Array.isArray(cond) && !(cond instanceof Date) && !(cond instanceof RegExp)) {
    for (const [op, operand] of Object.entries<any>(cond)) {
      switch (op) {
        case '$gte': if (!(value >= operand)) return false; break;
        case '$lte': if (!(value <= operand)) return false; break;
        case '$gt': if (!(value > operand)) return false; break;
        case '$lt': if (!(value < operand)) return false; break;
        case '$ne': if (value === operand) return false; break;
        case '$in': if (!Array.isArray(operand) || !operand.includes(value)) return false; break;
        case '$exists': if ((value !== undefined) !== !!operand) return false; break;
        case '$regex': {
          const re = operand instanceof RegExp ? operand : new RegExp(operand, cond.$options || '');
          if (!re.test(String(value ?? ''))) return false;
          break;
        }
        case '$options': break; // handled with $regex
        default: return false;
      }
    }
    return true;
  }
  return value === cond;
}

function matches(doc: any, filter: any): boolean {
  if (!filter) return true;
  for (const [key, cond] of Object.entries<any>(filter)) {
    if (key === '$or') {
      if (!Array.isArray(cond) || !cond.some((sub) => matches(doc, sub))) return false;
    } else if (key === '$and') {
      if (!Array.isArray(cond) || !cond.every((sub) => matches(doc, sub))) return false;
    } else if (!matchField(doc[key], cond)) {
      return false;
    }
  }
  return true;
}

function applyUpdate(doc: any, update: any): boolean {
  let modified = false;
  if (update.$set) for (const [k, v] of Object.entries(update.$set)) { doc[k] = v; modified = true; }
  if (update.$inc) for (const [k, v] of Object.entries<any>(update.$inc)) { doc[k] = (doc[k] || 0) + v; modified = true; }
  if (update.$push) for (const [k, v] of Object.entries<any>(update.$push)) { (doc[k] ??= []).push(v); modified = true; }
  return modified;
}

class MemoryCursor implements Cursor {
  constructor(private rows: any[]) {}
  sort(spec: Record<string, 1 | -1>): Cursor {
    const entries = Object.entries(spec);
    this.rows = [...this.rows].sort((a, b) => {
      for (const [k, dir] of entries) {
        const av = a[k], bv = b[k];
        if (av < bv) return -1 * dir;
        if (av > bv) return 1 * dir;
      }
      return 0;
    });
    return this;
  }
  skip(n: number): Cursor { this.rows = this.rows.slice(n); return this; }
  limit(n: number): Cursor { this.rows = this.rows.slice(0, n); return this; }
  async toArray(): Promise<any[]> { return this.rows.map((r) => ({ ...r })); }
}

class MemoryCollection implements Coll {
  private docs: any[] = [];
  async findOne(filter: any = {}): Promise<any | null> {
    const hit = this.docs.find((d) => matches(d, filter));
    return hit ? { ...hit } : null;
  }
  find(filter: any = {}): Cursor {
    return new MemoryCursor(this.docs.filter((d) => matches(d, filter)));
  }
  async insertOne(doc: any) { this.docs.push(doc); return { insertedId: doc._id }; }
  async insertMany(docs: any[]) { this.docs.push(...docs); return { insertedCount: docs.length }; }
  async updateOne(filter: any, update: any) {
    const doc = this.docs.find((d) => matches(d, filter));
    if (!doc) return { matchedCount: 0, modifiedCount: 0 };
    const mod = applyUpdate(doc, update);
    return { matchedCount: 1, modifiedCount: mod ? 1 : 0 };
  }
  async updateMany(filter: any, update: any) {
    let n = 0;
    for (const d of this.docs) if (matches(d, filter)) { applyUpdate(d, update); n++; }
    return { matchedCount: n, modifiedCount: n };
  }
  async deleteOne(filter: any) {
    const i = this.docs.findIndex((d) => matches(d, filter));
    if (i === -1) return { deletedCount: 0 };
    this.docs.splice(i, 1);
    return { deletedCount: 1 };
  }
  async deleteMany(filter: any) {
    const before = this.docs.length;
    this.docs = this.docs.filter((d) => !matches(d, filter));
    return { deletedCount: before - this.docs.length };
  }
  async countDocuments(filter: any = {}) { return this.docs.filter((d) => matches(d, filter)).length; }
}

// ── Backend selection ───────────────────────────────────────────────────────
let db: Db | null = null;
let memory = false;
const memStore: Record<string, MemoryCollection> = {};

export function isMemoryMode() { return memory; }

function coll(name: string): Coll {
  if (memory || !db) return (memStore[name] ??= new MemoryCollection());
  return db.collection(name) as unknown as Coll;
}

export const users = () => coll('users');
export const products = () => coll('products');
export const categories = () => coll('categories');
export const banners = () => coll('banners');
export const orders = () => coll('orders');
export const coupons = () => coll('coupons');
export const reviews = () => coll('reviews');
export const supportTickets = () => coll('support_tickets');

// Fresh install: seed ONLY a single admin account so the admin panel is
// reachable. No demo products / categories / banners / customers — the store
// starts empty and the admin adds real data. Credentials are configurable via
// ADMIN_EMAIL / ADMIN_PASSWORD in the environment.
async function seedIfEmpty() {
  // Always ensure an admin account exists so the admin panel is reachable.
  if ((await users().countDocuments({ role: 'admin' })) === 0) {
    const email = (process.env.ADMIN_EMAIL || 'admin@toolshub.com').toLowerCase();
    const password = process.env.ADMIN_PASSWORD || 'admin123';
    await users().insertOne({
      _id: 'user-admin',
      id: 'user-admin',
      email,
      password_hash: bcrypt.hashSync(password, 10),
      name: 'Admin',
      phone: null,
      photo_url: null,
      role: 'admin',
      is_email_verified: true,
      is_blocked: false,
      addresses: [],
      created_at: new Date(),
    });
    console.log(`Seeded admin account (${email}).`);
  }

  // Optionally seed a demo catalog for development convenience. Off by default
  // (the store stays empty); set SEED_DEMO=true in the environment to enable.
  if (process.env.SEED_DEMO === 'true') {
    if ((await categories().countDocuments({})) === 0) {
      await categories().insertMany(demoCategories);
    }
    if ((await products().countDocuments({})) === 0) {
      await products().insertMany(demoProducts);
      console.log(`Seeded ${demoProducts.length} demo products.`);
    }
  }
}

async function ensureIndexes() {
  if (memory || !db) return;
  try {
    await db.collection('users').createIndex({ email: 1 }, { unique: true });
    await db.collection('products').createIndex({ category_id: 1 });
    await db.collection('orders').createIndex({ user_id: 1 });
  } catch (e: any) {
    console.warn(`Index creation skipped: ${e.message}`);
  }
}

export async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (uri) {
    try {
      const client = new MongoClient(uri, { serverSelectionTimeoutMS: 4000 });
      await client.connect();
      await client.db().command({ ping: 1 });
      db = client.db(process.env.MONGODB_DB || 'toolshub');
      console.log('Successfully connected to MongoDB.');
    } catch (e: any) {
      console.warn('\n================================================================');
      console.warn('WARNING: Failed to connect to MongoDB.');
      console.warn(`Reason: ${e.message}`);
      console.warn('FAILING OVER: Server will run with an IN-MEMORY store.');
      console.warn('================================================================\n');
      memory = true;
    }
  } else {
    memory = true;
    console.warn('MONGODB_URI not set — using in-memory store (data resets on restart).');
  }
  await ensureIndexes();
  await seedIfEmpty();
}

export async function ping(): Promise<boolean> {
  if (memory || !db) return true;
  await db.command({ ping: 1 });
  return true;
}
