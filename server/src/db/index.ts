import { Pool } from 'pg';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import { processMockQuery } from './mockDb';

// Load environment variables from the server/.env file
dotenv.config({ path: path.join(__dirname, '../.env') });

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  connectionTimeoutMillis: 3000,
});

let useMockDb = false;

// Test connection asynchronously on startup
pool.query('SELECT NOW()')
  .then(() => {
    console.log('Successfully connected to Neon PostgreSQL Database.');
  })
  .catch((err) => {
    console.warn('\n================================================================');
    console.warn('WARNING: Failed to connect to Neon PostgreSQL Database.');
    console.warn(`Reason: ${err.message}`);
    console.warn('FAILING OVER: Server will run in OFFLINE/MOCK Database mode.');
    console.warn('================================================================\n');
    useMockDb = true;
  });

export const query = async (text: string, params?: any[]) => {
  if (useMockDb) {
    return processMockQuery(text, params);
  }
  try {
    return await pool.query(text, params);
  } catch (err: any) {
    console.error(`DB Query Error: ${err.message}. Falling back to Mock DB query.`);
    return processMockQuery(text, params);
  }
};

// Mock connection pool wrapper for transactions
const poolWrapper = {
  query: (text: string, params?: any[]) => query(text, params),
  connect: async () => {
    if (useMockDb) {
      return {
        query: async (t: string, p?: any[]) => processMockQuery(t, p),
        release: () => {}
      };
    }
    try {
      const client = await pool.connect();
      // Wrap the client's query function to failover to mock data on error
      const originalQuery = client.query.bind(client);
      client.query = (async (t: any, p: any) => {
        try {
          return await originalQuery(t, p);
        } catch (err: any) {
          console.error(`Client Query Error: ${err.message}. Falling back to Mock DB.`);
          const queryText = typeof t === 'string' ? t : t.text;
          const queryParams = p || t.values;
          return processMockQuery(queryText, queryParams);
        }
      }) as any;
      return client;
    } catch (err: any) {
      console.warn(`Failed to connect client from pool (${err.message}), using Mock client.`);
      return {
        query: async (t: string, p?: any[]) => processMockQuery(t, p),
        release: () => {}
      };
    }
  },
  end: () => pool.end()
};

export async function initDatabase() {
  if (useMockDb) {
    console.log('Skipping schema init since we are in Mock mode.');
    return;
  }
  try {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf8');
    await pool.query(sql);
    console.log('Database schema initialized successfully.');
  } catch (error) {
    console.error('Failed to initialize database schema:', error);
    throw error;
  }
}

export default poolWrapper;
