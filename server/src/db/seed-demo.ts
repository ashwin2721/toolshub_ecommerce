import 'dotenv/config';
import { connectDB, categories, products } from './mongo';
import { demoCategories, demoProducts } from './demoData';

// Standalone demo seeder for a real database. Point MONGODB_URI at your MongoDB
// (e.g. Atlas) first — otherwise this only seeds a throwaway in-memory store and
// has no effect on the running server. For in-memory dev, set SEED_DEMO=true so
// the server itself seeds this catalog on startup.
async function run() {
  await connectDB();

  if ((await categories().countDocuments({})) === 0) {
    await categories().insertMany(demoCategories);
    console.log(`Inserted ${demoCategories.length} categories.`);
  } else {
    console.log('Categories already present — skipped.');
  }

  if ((await products().countDocuments({})) === 0) {
    await products().insertMany(demoProducts);
    console.log(`Inserted ${demoProducts.length} products.`);
  } else {
    console.log('Products already present — skipped.');
  }

  console.log('Demo data ready.');
  process.exit(0);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
