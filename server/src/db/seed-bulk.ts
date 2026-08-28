import 'dotenv/config';
import { connectDB, categories, products } from './mongo';

// Use crypto.randomUUID for unique IDs
import crypto from 'crypto';

const uid = () => crypto.randomUUID();

async function seedBulk() {
  console.log('Connecting to database...');
  await connectDB();

  // ── First, get existing category IDs ──────────────────────────────────────
  const existingCats = await categories().find({}).toArray();
  let catPowerTools: string, catHandTools: string, catSafety: string;
  let catMeasuring: string, catAccessories: string, catGarden: string, catPlumbing: string;

  if (existingCats.length >= 3) {
    catPowerTools = existingCats.find((c: any) => c.name === 'Power Tools')?.id || existingCats[0].id;
    catHandTools = existingCats.find((c: any) => c.name === 'Hand Tools')?.id || existingCats[1].id;
    catSafety = existingCats.find((c: any) => c.name === 'Safety Gear')?.id || existingCats[2].id;
  } else {
    catPowerTools = `cat-${uid()}`;
    catHandTools = `cat-${uid()}`;
    catSafety = `cat-${uid()}`;
    await categories().insertMany([
      { _id: catPowerTools, id: catPowerTools, name: 'Power Tools', slug: 'power-tools', description: 'High performance electric and battery-powered tools.', image_url: 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800', is_active: true, sort_order: 1, product_count: 0, created_at: new Date() },
      { _id: catHandTools, id: catHandTools, name: 'Hand Tools', slug: 'hand-tools', description: 'Reliable manual tools for precision work.', image_url: 'https://images.unsplash.com/photo-1581147036324-c1878fde93f7?auto=format&fit=crop&q=80&w=800', is_active: true, sort_order: 2, product_count: 0, created_at: new Date() },
      { _id: catSafety, id: catSafety, name: 'Safety Gear', slug: 'safety-gear', description: 'Protective equipment for the worksite.', image_url: 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800', is_active: true, sort_order: 3, product_count: 0, created_at: new Date() },
    ]);
  }

  // Add new categories
  catMeasuring = `cat-${uid()}`;
  catAccessories = `cat-${uid()}`;
  catGarden = `cat-${uid()}`;
  catPlumbing = `cat-${uid()}`;

  await categories().insertMany([
    { _id: catMeasuring, id: catMeasuring, name: 'Measuring Tools', slug: 'measuring-tools', description: 'Precision measuring and leveling instruments.', image_url: 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800', is_active: true, sort_order: 4, product_count: 0, created_at: new Date() },
    { _id: catAccessories, id: catAccessories, name: 'Accessories & Bits', slug: 'accessories-bits', description: 'Drill bits, blades, and tool accessories.', image_url: 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800', is_active: true, sort_order: 5, product_count: 0, created_at: new Date() },
    { _id: catGarden, id: catGarden, name: 'Garden Tools', slug: 'garden-tools', description: 'Tools for landscaping and garden maintenance.', image_url: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&q=80&w=800', is_active: true, sort_order: 6, product_count: 0, created_at: new Date() },
    { _id: catPlumbing, id: catPlumbing, name: 'Plumbing Tools', slug: 'plumbing-tools', description: 'Essential tools for plumbing and pipe work.', image_url: 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800', is_active: true, sort_order: 7, product_count: 0, created_at: new Date() },
  ]);

  console.log('Categories ready.');

  // ── 40 Products ───────────────────────────────────────────────────────────
  const makeProduct = (name: string, sku: string, desc: string, price: number, discountPrice: number | null, stock: number, catId: string, catName: string, brandName: string, rating: number, reviewCount: number, imageUrl: string, opts: any = {}) => {
    const id = `prod-${uid()}`;
    return {
      _id: id, id, sku,
      name, slug: name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, ''),
      description: desc,
      brand_id: null, brand_name: brandName,
      category_id: catId, category_name: catName,
      price, discount_price: discountPrice,
      stock_quantity: stock,
      rating, review_count: reviewCount,
      is_active: true,
      is_featured: opts.featured || false,
      is_best_seller: opts.bestSeller || false,
      is_flash_sale: opts.flashSale || false,
      is_new_arrival: opts.newArrival || false,
      features: opts.features || null,
      specifications: opts.specs || null,
      image_urls: [imageUrl],
      compatible_product_ids: null,
      bulk_pricing: null,
      created_at: new Date(),
    };
  };

  const newProducts = [
    // ── Power Tools (10) ────────────────────────────────────────────────────
    makeProduct('Bosch 12V Impact Driver', 'BSH-12V-ID', 'Compact 12V impact driver with 2-speed settings and LED light. Perfect for tight spaces.', 119.99, 99.99, 60, catPowerTools, 'Power Tools', 'Bosch', 4.7, 185, 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800', { featured: true, bestSeller: true }),
    makeProduct('Milwaukee M18 Hammer Drill', 'MLW-M18-HD', 'Heavy-duty 18V hammer drill for concrete and masonry. Includes side handle.', 249.00, 219.00, 35, catPowerTools, 'Power Tools', 'Milwaukee', 4.8, 320, 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800', { featured: true }),
    makeProduct('Ryobi 40V Brushless Blower', 'RYB-40V-BL', 'Powerful cordless leaf blower with variable speed trigger.', 179.00, null, 40, catPowerTools, 'Power Tools', 'Ryobi', 4.5, 98, 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800', { newArrival: true }),
    makeProduct('DeWalt 20V Reciprocating Saw', 'DW-20V-RS', 'Variable speed reciprocating saw with tool-free blade change.', 139.00, 119.00, 25, catPowerTools, 'Power Tools', 'DeWalt', 4.6, 145, 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800', { flashSale: true }),
    makeProduct('Makita 18V Angle Grinder', 'MK-18V-AG', '4-1/2 inch cordless angle grinder with brushless motor technology.', 159.00, null, 30, catPowerTools, 'Power Tools', 'Makita', 4.4, 76, 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Bosch Jigsaw 700W', 'BSH-JS-700', 'Professional-grade jigsaw with orbital action and dust blower.', 89.99, 74.99, 50, catPowerTools, 'Power Tools', 'Bosch', 4.3, 112, 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Milwaukee Rotary Hammer', 'MLW-RH-26', '1-inch SDS Plus rotary hammer with anti-vibration system.', 329.00, 289.00, 15, catPowerTools, 'Power Tools', 'Milwaukee', 4.9, 203, 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800', { bestSeller: true }),
    makeProduct('Craftsman V20 Random Orbital Sander', 'CF-V20-ROS', 'Cordless orbital sander with dust collection bag and variable speed.', 69.99, null, 70, catPowerTools, 'Power Tools', 'Craftsman', 4.2, 54, 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800', { newArrival: true }),
    makeProduct('DeWalt 12-Inch Miter Saw', 'DW-12-MS', 'Sliding compound miter saw with 15-Amp motor and LED cut line.', 449.00, 399.00, 10, catPowerTools, 'Power Tools', 'DeWalt', 4.8, 267, 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800', { featured: true }),
    makeProduct('Ridgid 18V Brad Nailer', 'RDG-18V-BN', 'Cordless 18-gauge brad nailer with dry-fire lockout and LED light.', 199.00, 179.00, 22, catPowerTools, 'Power Tools', 'Ridgid', 4.5, 89, 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800'),

    // ── Hand Tools (8) ──────────────────────────────────────────────────────
    makeProduct('Knipex Pliers Wrench 10-Inch', 'KNP-PW-10', 'German-engineered smooth-jaw pliers wrench. Replaces a full wrench set.', 64.99, 54.99, 80, catHandTools, 'Hand Tools', 'Knipex', 4.9, 412, 'https://images.unsplash.com/photo-1581147036324-c1878fde93f7?auto=format&fit=crop&q=80&w=800', { bestSeller: true }),
    makeProduct('Wera Kraftform Screwdriver Set', 'WRA-KF-SET', '6-piece precision screwdriver set with ergonomic grips and hardened tips.', 42.99, null, 90, catHandTools, 'Hand Tools', 'Wera', 4.7, 198, 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800', { featured: true }),
    makeProduct('Estwing 16oz Claw Hammer', 'EST-16-CH', 'Forged steel construction with shock-absorbing grip. A classic.', 29.99, 24.99, 120, catHandTools, 'Hand Tools', 'Estwing', 4.8, 534, 'https://images.unsplash.com/photo-1581147036324-c1878fde93f7?auto=format&fit=crop&q=80&w=800', { bestSeller: true }),
    makeProduct('Stanley FatMax Tape Measure 25ft', 'ST-FM-25', 'BladeArmor coated tape with 13ft standout and magnetic hook.', 24.99, null, 200, catHandTools, 'Hand Tools', 'Stanley', 4.6, 321, 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Channellock 10-Inch Tongue & Groove', 'CHL-10-TG', 'Precision-machined jaw pliers with laser-hardened teeth.', 19.99, null, 150, catHandTools, 'Hand Tools', 'Channellock', 4.5, 167, 'https://images.unsplash.com/photo-1581147036324-c1878fde93f7?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Klein Tools Wire Stripper', 'KLN-WS-11', 'Multi-purpose electrician wire stripper and cutter for 10-18 AWG.', 17.99, 14.99, 110, catHandTools, 'Hand Tools', 'Klein Tools', 4.7, 243, 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Irwin Quick-Grip Clamp Set', 'IRW-QG-6PK', '6-piece bar clamp set with one-handed operation and quick release.', 49.99, 39.99, 65, catHandTools, 'Hand Tools', 'Irwin', 4.4, 88, 'https://images.unsplash.com/photo-1581147036324-c1878fde93f7?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Snap-on Ratchet Set 3/8-Inch', 'SPN-RS-38', 'Premium 3/8-inch drive ratchet set with 72-tooth gear and chrome finish.', 189.00, null, 20, catHandTools, 'Hand Tools', 'Snap-on', 4.9, 156, 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800', { featured: true }),

    // ── Safety Gear (6) ─────────────────────────────────────────────────────
    makeProduct('Honeywell Safety Glasses Anti-Fog', 'HW-SG-AF', 'Clear anti-fog safety glasses with wraparound protection.', 12.99, 9.99, 300, catSafety, 'Safety Gear', 'Honeywell', 4.5, 432, 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800', { bestSeller: true }),
    makeProduct('Mechanix Wear M-Pact Gloves', 'MCX-MP-GL', 'Impact-resistant work gloves with D3O palm padding and secure fit cuff.', 34.99, 29.99, 85, catSafety, 'Safety Gear', 'Mechanix Wear', 4.7, 276, 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800', { featured: true }),
    makeProduct('3M Half Facepiece Respirator', '3M-HF-RESP', 'Reusable respirator with bayonet connection for P100 and OV cartridges.', 29.99, null, 60, catSafety, 'Safety Gear', '3M', 4.6, 189, 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Carhartt High-Vis Safety Vest', 'CRH-HV-VT', 'ANSI Class 2 high-visibility mesh vest with reflective strips.', 22.99, 18.99, 140, catSafety, 'Safety Gear', 'Carhartt', 4.4, 98, 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Pyramex Hard Hat Ratchet Suspension', 'PYR-HH-RS', 'Full brim hard hat with 4-point ratchet suspension and sweatband.', 19.99, null, 75, catSafety, 'Safety Gear', 'Pyramex', 4.3, 67, 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Timberland PRO Steel Toe Boots', 'TMB-ST-BT', 'Waterproof steel toe work boots with anti-fatigue technology.', 149.00, 129.00, 40, catSafety, 'Safety Gear', 'Timberland PRO', 4.8, 345, 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800', { bestSeller: true }),

    // ── Measuring Tools (6) ─────────────────────────────────────────────────
    makeProduct('Bosch Laser Level Cross-Line', 'BSH-LL-CL', 'Self-leveling green laser with horizontal and vertical lines up to 50ft.', 99.99, 84.99, 45, catMeasuring, 'Measuring Tools', 'Bosch', 4.7, 198, 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800', { featured: true }),
    makeProduct('Fluke Digital Multimeter', 'FLK-DM-117', 'True-RMS multimeter with backlit display and non-contact voltage detection.', 189.00, null, 30, catMeasuring, 'Measuring Tools', 'Fluke', 4.9, 287, 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800', { bestSeller: true }),
    makeProduct('Stabila 48-Inch Box Level', 'STB-48-BL', 'Professional aluminum box beam level with block vials for easy reading.', 69.99, null, 35, catMeasuring, 'Measuring Tools', 'Stabila', 4.6, 112, 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Leica DISTO Laser Distance Meter', 'LCA-DM-D2', 'Measures up to 330ft with Bluetooth connectivity. Accurate to 1/16 inch.', 149.00, 129.00, 20, catMeasuring, 'Measuring Tools', 'Leica', 4.8, 156, 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800', { newArrival: true }),
    makeProduct('Empire 12-Inch Combination Square', 'EMP-12-CS', 'Stainless steel blade with etched graduations and cast zinc head.', 24.99, 19.99, 90, catMeasuring, 'Measuring Tools', 'Empire', 4.4, 78, 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800'),
    makeProduct('General Tools Digital Caliper', 'GEN-DC-6', '6-inch stainless steel digital caliper with LCD display. Metric/Imperial.', 29.99, null, 65, catMeasuring, 'Measuring Tools', 'General Tools', 4.5, 134, 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800'),

    // ── Accessories & Bits (5) ──────────────────────────────────────────────
    makeProduct('DeWalt 100-Piece Drill Bit Set', 'DW-100-DBS', 'Comprehensive set with HSS drill bits, screwdriver bits, and nut drivers.', 39.99, 29.99, 100, catAccessories, 'Accessories & Bits', 'DeWalt', 4.6, 267, 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800', { bestSeller: true }),
    makeProduct('Diablo 10-Inch Miter Saw Blade', 'DBL-10-MSB', '60-tooth fine finish blade with TiCo carbide for ultra-clean cuts.', 44.99, null, 55, catAccessories, 'Accessories & Bits', 'Diablo', 4.8, 189, 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Bosch SDS-Plus Drill Bit Set', 'BSH-SDS-5', '5-piece masonry bit set for rotary hammers. Sizes 3/16 to 1/2 inch.', 34.99, 27.99, 70, catAccessories, 'Accessories & Bits', 'Bosch', 4.5, 98, 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Milwaukee Hole Dozer Bi-Metal Set', 'MLW-HD-9', '9-piece hole saw set with Plug Jack for fast plug removal.', 79.99, 64.99, 40, catAccessories, 'Accessories & Bits', 'Milwaukee', 4.7, 143, 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800', { featured: true }),
    makeProduct('Spax Multi-Material Screw Kit', 'SPX-MM-500', '500-piece assorted screw kit for wood, metal, and plastic applications.', 54.99, 44.99, 80, catAccessories, 'Accessories & Bits', 'Spax', 4.4, 76, 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800'),

    // ── Garden Tools (3) ────────────────────────────────────────────────────
    makeProduct('Fiskars Bypass Pruner Pro', 'FSK-BP-PRO', 'Sharp precision-ground blade with low-friction coating. Lifetime warranty.', 34.99, 28.99, 55, catGarden, 'Garden Tools', 'Fiskars', 4.7, 234, 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&q=80&w=800', { bestSeller: true }),
    makeProduct('Corona Extendable Hedge Shears', 'CRN-EH-32', 'Telescoping handles from 25 to 32 inches with non-stick blade coating.', 44.99, null, 40, catGarden, 'Garden Tools', 'Corona', 4.5, 87, 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&q=80&w=800'),
    makeProduct('Husqvarna 18V Cordless Chainsaw', 'HSQ-18V-CS', 'Lightweight 12-inch bar cordless chainsaw. Ideal for trimming and small trees.', 299.00, 259.00, 15, catGarden, 'Garden Tools', 'Husqvarna', 4.6, 112, 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&q=80&w=800', { newArrival: true }),

    // ── Plumbing Tools (2) ──────────────────────────────────────────────────
    makeProduct('Ridgid Pipe Wrench 14-Inch', 'RDG-PW-14', 'Heavy-duty cast iron pipe wrench with I-beam handle and sharp teeth.', 39.99, null, 45, catPlumbing, 'Plumbing Tools', 'Ridgid', 4.6, 198, 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800', { bestSeller: true }),
    makeProduct('SharkBite Push-Fit Fitting Kit', 'SHB-PF-KIT', '25-piece push-to-connect fitting assortment for copper, PEX, and CPVC.', 89.99, 74.99, 30, catPlumbing, 'Plumbing Tools', 'SharkBite', 4.5, 134, 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800'),
  ];

  console.log(`Inserting ${newProducts.length} products...`);
  await products().insertMany(newProducts);
  console.log(`Successfully seeded ${newProducts.length} new products!`);
  console.log(`Total products in database: ${await products().countDocuments()}`);
  process.exit(0);
}

seedBulk().catch((err) => { console.error(err); process.exit(1); });
