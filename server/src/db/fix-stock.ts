import 'dotenv/config';
import { connectDB, products } from './mongo';

async function fixOldProducts() {
  console.log('Connecting to database...');
  await connectDB();

  // Fix old products that used "stock" instead of "stock_quantity"
  const allProducts = await products().find({}).toArray();
  let fixed = 0;
  for (const p of allProducts) {
    if (p.stock_quantity === undefined || p.stock_quantity === null) {
      const qty = p.stock || 50; // use the old "stock" field, or default to 50
      await products().updateOne(
        { _id: p._id },
        { $set: { stock_quantity: qty, rating: p.rating || 4.5, review_count: p.review_count || 10 } }
      );
      fixed++;
    }
  }
  console.log(`Fixed ${fixed} products with missing stock_quantity.`);
  console.log(`Total products: ${await products().countDocuments()}`);
  process.exit(0);
}

fixOldProducts().catch((err) => { console.error(err); process.exit(1); });
