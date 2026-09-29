import 'dotenv/config';
import { connectDB, categories, products } from './mongo';
import { demoCategories, demoProducts } from './demoData';

// Wipes existing products & categories, then seeds the fresh 15-product catalog.
async function run() {
  await connectDB();

  // Remove old products & categories
  await products().deleteMany({});
  console.log('Cleared all existing products.');
  await categories().deleteMany({});
  console.log('Cleared all existing categories.');

  // Insert fresh demo data
  await categories().insertMany(demoCategories);
  console.log(`Inserted ${demoCategories.length} categories.`);

  await products().insertMany(demoProducts);
  console.log(`Inserted ${demoProducts.length} products.`);

  console.log('Done! Fresh 15-product demo catalog is ready.');
  process.exit(0);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
