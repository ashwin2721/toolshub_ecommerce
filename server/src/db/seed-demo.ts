import 'dotenv/config';
import { connectDB, categories, products } from './mongo';
import { ObjectId } from 'mongodb';

async function seedDemoData() {
  console.log('Connecting to database...');
  await connectDB();

  console.log('Inserting categories...');
  const catPowerToolsId = new ObjectId().toString();
  const catHandToolsId = new ObjectId().toString();
  const catSafetyId = new ObjectId().toString();

  await categories().insertMany([
    {
      _id: catPowerToolsId,
      id: catPowerToolsId,
      name: 'Power Tools',
      description: 'High performance electric and battery-powered tools.',
      image_url: 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800',
      is_active: true,
      created_at: new Date()
    },
    {
      _id: catHandToolsId,
      id: catHandToolsId,
      name: 'Hand Tools',
      description: 'Reliable manual tools for precision work.',
      image_url: 'https://images.unsplash.com/photo-1581147036324-c1878fde93f7?auto=format&fit=crop&q=80&w=800',
      is_active: true,
      created_at: new Date()
    },
    {
      _id: catSafetyId,
      id: catSafetyId,
      name: 'Safety Gear',
      description: 'Protective equipment for the worksite.',
      image_url: 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800',
      is_active: true,
      created_at: new Date()
    }
  ]);

  console.log('Inserting products...');
  await products().insertMany([
    {
      _id: new ObjectId().toString(),
      id: new ObjectId().toString(),
      category_id: catPowerToolsId,
      name: 'DeWalt 20V MAX Cordless Drill',
      description: 'Compact cordless drill/driver kit. Includes 2 batteries and charger.',
      price: 159.00,
      discount_price: 129.00,
      stock: 45,
      sku: 'DW-20V-DRL',
      image_urls: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800'],
      is_active: true,
      created_at: new Date()
    },
    {
      _id: new ObjectId().toString(),
      id: new ObjectId().toString(),
      category_id: catPowerToolsId,
      name: 'Makita 18V LXT Circular Saw',
      description: 'Powerful 6-1/2" circular saw with brushless motor.',
      price: 199.00,
      discount_price: null,
      stock: 20,
      sku: 'MK-18V-SAW',
      image_urls: ['https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800'],
      is_active: true,
      created_at: new Date()
    },
    {
      _id: new ObjectId().toString(),
      id: new ObjectId().toString(),
      category_id: catHandToolsId,
      name: 'Stanley 100-Piece Mechanics Tool Set',
      description: 'Comprehensive set of sockets, wrenches, and hex keys.',
      price: 89.99,
      discount_price: 75.00,
      stock: 100,
      sku: 'ST-100-MEC',
      image_urls: ['https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800'],
      is_active: true,
      created_at: new Date()
    },
    {
      _id: new ObjectId().toString(),
      id: new ObjectId().toString(),
      category_id: catSafetyId,
      name: '3M WorkTunes Connect Hearing Protector',
      description: 'Bluetooth hearing protection with excellent noise reduction.',
      price: 55.00,
      discount_price: null,
      stock: 30,
      sku: '3M-WT-HP',
      image_urls: ['https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800'],
      is_active: true,
      created_at: new Date()
    }
  ]);

  console.log('Demo data seeded successfully!');
  process.exit(0);
}

seedDemoData().catch(console.error);
