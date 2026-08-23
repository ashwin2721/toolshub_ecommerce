import bcrypt from 'bcrypt';
import pool, { initDatabase } from './index';

async function seed() {
  console.log('Starting database seeding...');
  
  // 1. Initialize tables (drops existing, creates new)
  await initDatabase();
  
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 2. Seed Default Users
    console.log('Seeding default users...');
    const adminPasswordHash = bcrypt.hashSync('admin123', 10);
    const customerPasswordHash = bcrypt.hashSync('user123', 10);

    await client.query(
      `INSERT INTO users (id, email, password_hash, name, role, is_email_verified) 
       VALUES ($1, $2, $3, $4, $5, $6), ($7, $8, $9, $10, $11, $12)`,
      [
        'user-admin', 'admin@toolshub.com', adminPasswordHash, 'Admin User', 'admin', true,
        'user-customer', 'user@toolshub.com', customerPasswordHash, 'Customer User', 'customer', true
      ]
    );

    // 3. Seed Categories
    console.log('Seeding categories...');
    const categories = [
      {
        id: 'power-tools',
        name: 'Power Tools',
        slug: 'power-tools',
        description: 'High-performance drills, saws, grinders, and sanders for heavy duty jobs.',
        image_url: 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80',
        is_active: true,
        sort_order: 1,
        product_count: 6
      },
      {
        id: 'hand-tools',
        name: 'Hand Tools',
        slug: 'hand-tools',
        description: 'Professional wrenches, screwdrivers, pliers, and hammers built to last.',
        image_url: 'https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80',
        is_active: true,
        sort_order: 2,
        product_count: 6
      },
      {
        id: 'measuring-tools',
        name: 'Measuring Tools',
        slug: 'measuring-tools',
        description: 'Precision laser measures, spirit levels, calipers, and tape measures.',
        image_url: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=500&auto=format&fit=crop&q=80',
        is_active: true,
        sort_order: 3,
        product_count: 3
      },
      {
        id: 'safety-gear',
        name: 'Safety Gear',
        slug: 'safety-gear',
        description: 'Protective goggles, hard hats, gloves, and high-visibility apparel.',
        image_url: 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=500&auto=format&fit=crop&q=80',
        is_active: true,
        sort_order: 4,
        product_count: 3
      },
      {
        id: 'tool-storage',
        name: 'Tool Storage',
        slug: 'tool-storage',
        description: 'Heavy-duty toolboxes, rolling cabinets, tool bags, and organisers.',
        image_url: 'https://images.unsplash.com/photo-1581244277943-fe4a9c777189?w=500&auto=format&fit=crop&q=80',
        is_active: true,
        sort_order: 5,
        product_count: 3
      }
    ];

    for (const cat of categories) {
      await client.query(
        `INSERT INTO categories (id, name, slug, description, image_url, is_active, sort_order, product_count) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [cat.id, cat.name, cat.slug, cat.description, cat.image_url, cat.is_active, cat.sort_order, cat.product_count]
      );
    }

    // 4. Seed Banners
    console.log('Seeding banners...');
    const banners = [
      {
        title: 'Mega Monsoon Sale',
        subtitle: 'Up to 40% Off on Power Tools',
        image_url: 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=1200&auto=format&fit=crop&q=80',
        action_url: '/products?category=power-tools',
        is_active: true,
        sort_order: 1
      },
      {
        title: 'Stanley Premium Hand Tools',
        subtitle: 'Starting from just ₹199',
        image_url: 'https://images.unsplash.com/photo-1530124566582-ab0510491570?w=1200&auto=format&fit=crop&q=80',
        action_url: '/products?brand=stanley',
        is_active: true,
        sort_order: 2
      },
      {
        title: 'Safety Gear Essentials',
        subtitle: 'Ensure protection at every worksite',
        image_url: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=1200&auto=format&fit=crop&q=80',
        action_url: '/products?category=safety-gear',
        is_active: true,
        sort_order: 3
      }
    ];

    for (const b of banners) {
      await client.query(
        `INSERT INTO banners (title, subtitle, image_url, action_url, is_active, sort_order) 
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [b.title, b.subtitle, b.image_url, b.action_url, b.is_active, b.sort_order]
      );
    }

    // 5. Seed Products
    console.log('Seeding products...');
    const products = [
      {
        id: 'prod-bosch-bits',
        sku: 'BOS-BIT-SET-25',
        name: 'Bosch 25-Piece Drill and Screwdriver Bit Set',
        slug: 'bosch-25-piece-drill-bit-set',
        description: 'A comprehensive set of high-grade bits for drilling and fastening. Supplied in a robust storage case, suitable for use with all standard drill brands.',
        brand_id: 'bosch',
        brand_name: 'Bosch',
        category_id: 'hand-tools',
        category_name: 'Hand Tools',
        price: 1500.0,
        discount_price: 1299.0,
        stock_quantity: 100,
        rating: 4.6,
        review_count: 45,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Includes magnetic universal holder for quick bit changes',
          'Durable bits for all standard screw types and sizes',
          'Housed in a practical and robust case'
        ],
        specifications: '• Pieces in set: 25\n• Holder type: Magnetic\n• Compatibility: All drill chucks',
        image_urls: ['https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: { '10': 0.05, '30': 0.10 }
      },
      {
        id: 'prod-dewalt-battery',
        sku: 'DEW-BAT-20V-5',
        name: 'DeWalt 20V MAX 5.0Ah Lithium Ion Battery Pack',
        slug: 'dewalt-20v-max-5ah-battery-pack',
        description: 'Keep your cordless power tools running longer with this heavy-duty 20V MAX 5.0Ah XR Lithium Ion battery. Features a 3-LED state of charge fuel gauge for instant capacity feedback.',
        brand_id: 'dewalt',
        brand_name: 'DeWalt',
        category_id: 'power-tools',
        category_name: 'Power Tools',
        price: 4999.0,
        discount_price: 3999.0,
        stock_quantity: 50,
        rating: 4.7,
        review_count: 32,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          '5.0Ah high capacity fuel cell pack for extended runtime',
          '3-LED fuel gauge system allows immediate feedback on state of charge',
          'No memory effect and virtually no self-discharge'
        ],
        specifications: '• Voltage: 20V MAX\n• Capacity: 5.0 Ah\n• Chemistry: Lithium Ion\n• Fuel Gauge: 3-LED',
        image_urls: ['https://images.unsplash.com/photo-1608613304899-ea8098577e38?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-makita-blade',
        sku: 'MAK-BLADE-714',
        name: 'Makita 7-1/4 Inch 24T Carbide-Tipped Saw Blade',
        slug: 'makita-7-1-4-inch-saw-blade',
        description: 'Industrial saw blade engineered for framing and ripping cuts. Thin-kerf design delivers fast and smooth cuts with reduced power draw.',
        brand_id: 'makita',
        brand_name: 'Makita',
        category_id: 'power-tools',
        category_name: 'Power Tools',
        price: 950.0,
        discount_price: 799.0,
        stock_quantity: 120,
        rating: 4.5,
        review_count: 22,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          '24 Carbide-tipped teeth for durable and fast cutting',
          'Thin-kerf design for longer battery life on cordless saws',
          'Anti-vibration slots reduce noise and heat build-up'
        ],
        specifications: '• Diameter: 7-1/4 inch\n• Teeth: 24 ATB\n• Arbor: 5/8 inch\n• Max RPM: 8,300 RPM',
        image_urls: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-bosch-drill',
        sku: 'BOS-GSB-13RE',
        name: 'Bosch Professional Impact Drill GSB 13 RE',
        slug: 'bosch-impact-drill-gsb-13-re',
        description: 'The GSB 13 RE Professional is an entry-level corded 1-gear impact drill. Its 1.7 kg lightweight design and small housing size offer convenient handling and easy maneuverability. It is also exceptionally robust, featuring a durable metal keyless chuck.',
        brand_id: 'bosch',
        brand_name: 'Bosch',
        category_id: 'power-tools',
        category_name: 'Power Tools',
        price: 4500.0,
        discount_price: 3899.0,
        stock_quantity: 45,
        rating: 4.5,
        review_count: 124,
        is_active: true,
        is_featured: true,
        is_best_seller: true,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Compact design with soft grip for comfortable handling',
          'Robust metal keyless chuck for fast bit changes',
          'Electronic control for exact pilot drilling',
          'Speed pre-selection with setting wheel'
        ],
        specifications: '• Rated input power: 600 W\n• Weight: 1.7 kg\n• No-load speed: 0 – 2,800 rpm\n• Chuck capacity: 1.5 – 13 mm\n• Impact rate: 0 – 44,800 bpm',
        image_urls: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: ['prod-bosch-bits'],
        bulk_pricing: {}
      },
      {
        id: 'prod-dewalt-drill',
        sku: 'DEW-DCD771C2',
        name: 'DeWalt 20V MAX Cordless Drill Driver Kit',
        slug: 'dewalt-20v-max-cordless-drill-driver',
        brand_id: 'dewalt',
        brand_name: 'DeWalt',
        category_id: 'power-tools',
        category_name: 'Power Tools',
        description: 'The DCD771C2 20V MAX Lithium Ion Compact Drill/Driver Kit is lightweight and compact for working in tight spaces for long periods of time. High-speed transmission delivers 2-speed variations allowing users to choose the level of performance needed for various applications.',
        price: 8999.0,
        discount_price: 7999.0,
        stock_quantity: 30,
        rating: 4.8,
        review_count: 92,
        is_active: true,
        is_featured: true,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'High performance motor delivers 300 unit watts out (UWO) of power capability',
          'High speed transmission delivers two speeds (0-450 & 1,500 rpm)',
          'Ergonomic handle delivers comfort and control',
          '1/2-inch single sleeve ratcheting chuck provides tight bit gripping strength'
        ],
        specifications: '• Voltage: 20V MAX\n• Max Power: 300 UWO\n• Max RPM: 1,500 RPM\n• Chuck Size: 1/2 inch\n• Clutch Settings: 16',
        image_urls: ['https://images.unsplash.com/photo-1608613304899-ea8098577e38?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: ['prod-dewalt-battery', 'prod-bosch-bits'],
        bulk_pricing: {}
      },
      {
        id: 'prod-makita-saw',
        sku: 'MAK-5007F',
        name: 'Makita 7-1/4 Inch Circular Saw 5007F',
        slug: 'makita-7-1-4-inch-circular-saw',
        description: 'Makita’s 5007F 7-1/4-Inch Circular Saw features a powerful 15.0 AMP motor and a high power-to-weight ratio, with all ball bearing construction and a heavy gauge aluminum wraparound base for engineered durability and straighter cuts.',
        brand_id: 'makita',
        brand_name: 'Makita',
        category_id: 'power-tools',
        category_name: 'Power Tools',
        price: 11200.0,
        discount_price: 9499.0,
        stock_quantity: 15,
        rating: 4.6,
        review_count: 57,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Powerful 15.0 AMP motor delivers 5,800 RPM for proven performance',
          'Lower guard design improves performance when making bevel and narrow cuts',
          'Large cutting capacity (2-3/8 inches at 90°, 1-3/4 inches at 45°)',
          'Two built-in L.E.D. lights illuminate the line of cut for increased accuracy'
        ],
        specifications: '• Amperage: 15.0 A\n• Blade Diameter: 7-1/4 inch\n• No Load Speed: 5,800 RPM\n• Max Cutting Depth at 90°: 2-3/8 inch\n• Weight: 4.8 kg',
        image_urls: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: ['prod-makita-blade'],
        bulk_pricing: {}
      },
      {
        id: 'prod-stanley-screwdriver',
        sku: 'STA-65-242',
        name: 'Stanley 10-Piece Cushion Grip Screwdriver Set',
        slug: 'stanley-10-piece-screwdrivers-set',
        description: 'The Stanley 10-Piece Cushion Grip Screwdriver Set features chrome vanadium blades that resist bending and corrosion, and cushion-grip handles for high comfort and torque. Tips are magnetized for easy handling of screws.',
        brand_id: 'stanley',
        brand_name: 'Stanley',
        category_id: 'hand-tools',
        category_name: 'Hand Tools',
        price: 1200.0,
        discount_price: 999.0,
        stock_quantity: 100,
        rating: 4.4,
        review_count: 310,
        is_active: true,
        is_featured: true,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Cushion-grip handles for comfort and control',
          'Chrome-plated bars for corrosion resistance',
          'Magnetic tips for easy pickup and retention of screws',
          'Includes most popular slotted and Phillips sizes'
        ],
        specifications: '• Material: Chrome Vanadium Steel\n• Handle Material: Rubber (Cushion Grip)\n• Pieces in Set: 10\n• Tip Types: Slotted & Phillips',
        image_urls: ['https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: { '10': 0.05, '50': 0.12 }
      },
      {
        id: 'prod-taparia-spanner',
        sku: 'TAP-1171',
        name: 'Taparia Adjustable Spanner Wrench 1171',
        slug: 'taparia-adjustable-spanner-wrench',
        description: 'Precision marked scale on head indicates jaw opening. Chrome plated and fully polished to resist rust. Manufactured from high grade forge steel and heat treated for longer service life.',
        brand_id: 'taparia',
        brand_name: 'Taparia',
        category_id: 'hand-tools',
        category_name: 'Hand Tools',
        price: 850.0,
        discount_price: 650.0,
        stock_quantity: 150,
        rating: 4.3,
        review_count: 420,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: true,
        is_new_arrival: false,
        features: [
          'Manufactured from high-grade carbon steel',
          'Accurately marked scale on head for easy jaw preset',
          'Rust resistant chrome finish',
          'Left-hand thumb wheel movement for quick size changes'
        ],
        specifications: '• Length: 300 mm (12 inch)\n• Max Jaw Opening: 36 mm\n• Material: Carbon Steel\n• Weight: 650 g',
        image_urls: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: { '10': 0.05, '50': 0.12 }
      },
      {
        id: 'prod-stanley-hammer',
        sku: 'STA-51-071',
        name: 'Stanley Claw Hammer Steel Shaft 16oz',
        slug: 'stanley-claw-hammer-16oz',
        description: 'Exceeds ANSI specifications. Heat treated steel shaft claw hammer. Custom rubber grip offers excellent shock absorption and slip resistance.',
        brand_id: 'stanley',
        brand_name: 'Stanley',
        category_id: 'hand-tools',
        category_name: 'Hand Tools',
        price: 750.0,
        discount_price: 599.0,
        stock_quantity: 80,
        rating: 4.5,
        review_count: 88,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Heat-treated carbon steel head for strength and durability',
          'Tubular steel shaft for lightweight strength',
          'Claw design for easy nail extraction',
          'Shock-absorbing rubber handle sleeve'
        ],
        specifications: '• Head Weight: 16 oz (450 g)\n• Shaft Material: Tubular Steel\n• Grip Material: Rubberized Sleeve\n• Total Length: 330 mm',
        image_urls: ['https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-bosch-laser',
        sku: 'BOS-GLM-50C',
        name: 'Bosch Bluetooth Laser Measure GLM 50 C',
        slug: 'bosch-bluetooth-laser-measure',
        description: 'The Bosch GLM 50 C Bluetooth Laser Measure features a color display with backlighting, inclinometer for angle measurements, and Bluetooth connectivity for transfer of data to the MeasureOn App.',
        brand_id: 'bosch',
        brand_name: 'Bosch',
        category_id: 'measuring-tools',
        category_name: 'Measuring Tools',
        price: 7500.0,
        discount_price: 6499.0,
        stock_quantity: 25,
        rating: 4.7,
        review_count: 46,
        is_active: true,
        is_featured: true,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Bluetooth functionality to transfer measurements to free MeasureOn app',
          'Color display with backlighting for high visibility',
          'Inclinometer allows for angle measurements and indirect height readings',
          'Includes target plate, hand strap, and protective pouch'
        ],
        specifications: '• Measurement Range: 0.05 – 50.00 m\n• Measurement Accuracy: ± 1.5 mm\n• Laser Diode: 635 nm, < 1 mW (Class 2)\n• Power Supply: 2 x 1.5 V LR03 (AAA)\n• Weight: 100 g',
        image_urls: ['https://images.unsplash.com/photo-1513694203232-719a280e022f?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-stanley-tape',
        sku: 'STA-30-696',
        name: 'Stanley 5m Tylon Tape Measure',
        slug: 'stanley-5m-tylon-tape-measure',
        description: 'Tylon coated blade provides anti-glare readings and 1.5x greater abrasion resistance than standard lacquer. Ergonomic bi-material case delivers comfortable grip and lock button accessibility.',
        brand_id: 'stanley',
        brand_name: 'Stanley',
        category_id: 'measuring-tools',
        category_name: 'Measuring Tools',
        price: 350.0,
        discount_price: 280.0,
        stock_quantity: 200,
        rating: 4.6,
        review_count: 190,
        is_active: true,
        is_featured: false,
        is_best_seller: true,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Tylon blade coating for high readability and durability',
          'Ergonomic, shock-resistant bi-material case',
          'Tru-zero hook for accurate inside and outside measurements',
          'Belt clip for convenient carrying'
        ],
        specifications: '• Blade Length: 5 m\n• Blade Width: 19 mm\n• Measurement System: Metric & Imperial\n• Case Material: Bi-material (ABS + Rubber)',
        image_urls: ['https://images.unsplash.com/photo-1513694203232-719a280e022f?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-3m-goggles',
        sku: '3M-PRO-GLASSES',
        name: '3M Virtua AP Protective Safety Glasses',
        slug: '3m-virtua-ap-safety-glasses',
        description: 'High-quality lightweight polycarbonate safety glasses with wrap-around lens design, offering excellent side coverage and impact protection. Anti-scratch coating ensures long life.',
        brand_id: '3m',
        brand_name: '3M',
        category_id: 'safety-gear',
        category_name: 'Safety Gear',
        price: 450.0,
        discount_price: 350.0,
        stock_quantity: 300,
        rating: 4.4,
        review_count: 85,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Clear polycarbonate lenses absorb 99.9% UVA and UVB rays',
          'Meets ANSI Z87.1-2015 high impact standards',
          'Anti-scratch coating for durability',
          'Lightweight construction (less than 30g)'
        ],
        specifications: '• Lens Color: Clear\n• Frame Style: Frameless\n• UV Protection: 99.9%\n• Standards: ANSI Z87.1-2015',
        image_urls: ['https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: { '10': 0.10, '50': 0.20 }
      },
      {
        id: 'prod-dewalt-chest',
        sku: 'DEW-ROLL-CHEST',
        name: 'DeWalt Heavy Duty Rolling Tool Chest Cabinet',
        slug: 'dewalt-heavy-duty-rolling-tool-chest',
        description: 'Industrial grade 5-drawer rolling tool chest cabinet featuring heavy-duty ball bearing slides, 5x2-inch casters supporting up to 500 kg, and a secure internal keyed locking system.',
        brand_id: 'dewalt',
        brand_name: 'DeWalt',
        category_id: 'tool-storage',
        category_name: 'Tool Storage',
        price: 18500.0,
        discount_price: 15999.0,
        stock_quantity: 8,
        rating: 4.9,
        review_count: 34,
        is_active: true,
        is_featured: true,
        is_best_seller: true,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Heavy-duty ball-bearing drawer slides support up to 45 kg per drawer',
          'Robust internal keyed lock system protects your tools',
          '5x2-inch heavy-duty casters (2 locking swivel, 2 rigid)',
          'Top wooden workspace provides additional utility area'
        ],
        specifications: '• Dimensions: 68 cm W x 46 cm D x 85 cm H\n• Number of Drawers: 5\n• Weight Capacity: 500 kg\n• Weight: 38 kg\n• Color: DeWalt Yellow & Black',
        image_urls: ['https://images.unsplash.com/photo-1581244277943-fe4a9c777189?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-makita-grinder',
        sku: 'MAK-GA4030',
        name: 'Makita Cordless Angle Grinder 4-Inch',
        slug: 'makita-cordless-angle-grinder-4-inch',
        description: 'Makita 4-Inch Angle Grinder combines power with comfort and safety features for longer-lasting industrial performance. Features a barrel grip design and paddle switch.',
        brand_id: 'makita',
        brand_name: 'Makita',
        category_id: 'power-tools',
        category_name: 'Power Tools',
        price: 6999.0,
        discount_price: 5899.0,
        stock_quantity: 40,
        rating: 4.7,
        review_count: 48,
        is_active: true,
        is_featured: true,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: true,
        features: [
          'Powerful 6.0 AMP motor delivers 11,000 RPM',
          'Compact and lightweight design (1.7 kg) for comfort',
          'Labyrinth construction seals and protects the motor and bearings',
          'Paddle switch layout for secure and comfortable holding'
        ],
        specifications: '• Wheel Diameter: 4 inch\n• No Load Speed: 11,000 RPM\n• Spindle Thread: M10 x 1.25\n• Weight: 1.7 kg\n• Power Source: Cordless Battery (sold separately)',
        image_urls: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: ['prod-dewalt-battery'],
        bulk_pricing: {}
      },
      {
        id: 'prod-bosch-screwdriver-set',
        sku: 'BOS-SCREW-SET-46',
        name: 'Bosch 46-Piece Screwdriver and Nutsetter Set',
        slug: 'bosch-46-piece-screwdriver-nutsetter-set',
        description: 'All-in-one universal screwdriver bit and nutsetter set from Bosch. Made of durable, high-quality steel alloy, perfect for everyday manual and power tool repairs.',
        brand_id: 'bosch',
        brand_name: 'Bosch',
        category_id: 'hand-tools',
        category_name: 'Hand Tools',
        price: 1800.0,
        discount_price: 1499.0,
        stock_quantity: 85,
        rating: 4.5,
        review_count: 34,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'High-grade alloy steel bits for extreme lifetime',
          'Includes high-torque hand screwdriver stubby handle',
          'Nutsetters for hex screws and small socket applications'
        ],
        specifications: '• Total Pieces: 46\n• Bits length: 25 mm\n• Magnetic adapter: Yes\n• Carrying Case: Plastic Organizer',
        image_urls: ['https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-taparia-pliers',
        sku: 'TAP-PLIER-3SET',
        name: 'Taparia 3-Piece Plier Combination Set',
        slug: 'taparia-3-piece-plier-combination-set',
        description: 'Heavy duty insulated combination pliers, side cutter, and long nose pliers set. Ideal for electrical work, wire stripping, and household repairs.',
        brand_id: 'taparia',
        brand_name: 'Taparia',
        category_id: 'hand-tools',
        category_name: 'Hand Tools',
        price: 950.0,
        discount_price: 799.0,
        stock_quantity: 110,
        rating: 4.4,
        review_count: 112,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: true,
        is_new_arrival: false,
        features: [
          'High-grade steel body with induction hardened cutting edges',
          'Heavy insulation sleeves tested up to 1000V',
          'Ergonomic grips prevent hand fatigue during long jobs'
        ],
        specifications: '• Included Pliers: Combination 8-inch, Long Nose 6-inch, Side Cutter 6-inch\n• Material: High Grade Alloy Steel\n• Insulation: 1000V tested',
        image_urls: ['https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-dewalt-laser-level',
        sku: 'DEW-LAS-LEVEL-360',
        name: 'DeWalt 360-Degree Red Beam Laser Level',
        slug: 'dewalt-360-degree-red-beam-laser-level',
        description: 'Self-leveling 360-degree laser level projecting clear vertical and horizontal lines. Built with dust and water resistance, making it highly robust for construction sites.',
        brand_id: 'dewalt',
        brand_name: 'DeWalt',
        category_id: 'measuring-tools',
        category_name: 'Measuring Tools',
        price: 12500.0,
        discount_price: 9999.0,
        stock_quantity: 18,
        rating: 4.8,
        review_count: 18,
        is_active: true,
        is_featured: true,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: true,
        features: [
          'Full 360-degree laser projection for layout coverage',
          'Integrated magnetic pivot bracket easily mounts on metal surfaces',
          'Overmolded housing holds calibration on tough job sites'
        ],
        specifications: '• Working Range: 15 m\n• Accuracy: +/- 4 mm at 10 m\n• Indoor/Outdoor: Indoor use\n• Thread Mount: 1/4 inch & 5/8 inch',
        image_urls: ['https://images.unsplash.com/photo-1513694203232-719a280e022f?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-3m-respirator',
        sku: '3M-RESP-6200',
        name: '3M Professional Half Facepiece Respirator Set',
        slug: '3m-half-facepiece-respirator-6200',
        description: 'Reusable facepiece respirator mask designed for protection against paint sprays, dust, gypsum, and chemical particles. Lightweight design and comfortable head harness.',
        brand_id: '3m',
        brand_name: '3M',
        category_id: 'safety-gear',
        category_name: 'Safety Gear',
        price: 1999.0,
        discount_price: 1699.0,
        stock_quantity: 65,
        rating: 4.6,
        review_count: 65,
        is_active: true,
        is_featured: false,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Soft, lightweight elastomer material for skin comfort',
          'Dual-filter design reduces breathing resistance',
          'Adjustable head cradle strap for optimal fit'
        ],
        specifications: '• Material: Thermoplastic Elastomer\n• Cartridge/Filters: Includes organic vapor cartridges & particulate filters\n• Reusable: Yes\n• Standard: NIOSH approved',
        image_urls: ['https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      },
      {
        id: 'prod-stanley-toolbag',
        sku: 'STA-BAG-16HD',
        name: 'Stanley Heavy Duty 16-Inch Tool Bag Organizer',
        slug: 'stanley-heavy-duty-tool-bag-16',
        description: 'Tough 600 denier nylon fabric tool bag with multiple internal and external pockets. Heavy duty injection molded waterproof base protects tools from wet surfaces.',
        brand_id: 'stanley',
        brand_name: 'Stanley',
        category_id: 'tool-storage',
        category_name: 'Tool Storage',
        price: 2500.0,
        discount_price: 1999.0,
        stock_quantity: 78,
        rating: 4.5,
        review_count: 78,
        is_active: true,
        is_featured: true,
        is_best_seller: false,
        is_flash_sale: false,
        is_new_arrival: false,
        features: [
          'Constructed from heavy duty 600D nylon fabric',
          'Waterproof rigid plastic base keeps tools dry',
          'Reinforced corners and padded shoulder straps'
        ],
        specifications: '• Size: 16 inch (40 cm)\n• Pockets: 10 internal, 8 external\n• Closure Type: Heavy duty zipper\n• Weight Capacity: 25 kg',
        image_urls: ['https://images.unsplash.com/photo-1581244277943-fe4a9c777189?w=500&auto=format&fit=crop&q=80'],
        compatible_product_ids: [],
        bulk_pricing: {}
      }
    ];

    for (const p of products) {
      await client.query(
        `INSERT INTO products (
          id, sku, name, slug, description, brand_id, brand_name, 
          category_id, category_name, price, discount_price, stock_quantity, 
          rating, review_count, is_active, is_featured, is_best_seller, 
          is_flash_sale, is_new_arrival, features, specifications, 
          image_urls, compatible_product_ids, bulk_pricing
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24)`,
        [
          p.id, p.sku, p.name, p.slug, p.description, p.brand_id, p.brand_name,
          p.category_id, p.category_name, p.price, p.discount_price, p.stock_quantity,
          p.rating, p.review_count, p.is_active, p.is_featured, p.is_best_seller,
          p.is_flash_sale, p.is_new_arrival, p.features, p.specifications,
          p.image_urls, p.compatible_product_ids, JSON.stringify(p.bulk_pricing)
        ]
      );
    }

    await client.query('COMMIT');
    console.log('Seeding completed successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error during seeding database:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Run the script if executing this file directly
if (require.main === module) {
  seed()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
