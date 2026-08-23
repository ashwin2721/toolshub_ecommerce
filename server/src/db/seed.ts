// Seed script: connects to MongoDB (via MONGODB_URI, or the in-memory fallback)
// and inserts the default catalog/users if the collections are empty.
// The same seeding runs automatically on server startup — this script exists so
// `npm run db:seed` can pre-populate a fresh MongoDB (e.g. an Atlas cluster).
import 'dotenv/config';
import { connectDB } from './mongo';

async function seed() {
  console.log('Seeding MongoDB...');
  await connectDB();
  console.log('Seeding completed successfully!');
}

if (require.main === module) {
  seed()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
