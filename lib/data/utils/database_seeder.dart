import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/product_model.dart';

class DatabaseSeeder {
  static Future<void> seed(FirebaseFirestore firestore) async {
    final batch = firestore.batch();

    // ─── 1. SEED CATEGORIES ───────────────────────────────────────────────────
    final categories = [
      {
        'id': 'power-tools',
        'name': 'Power Tools',
        'slug': 'power-tools',
        'description': 'High-performance drills, saws, grinders, and sanders for heavy duty jobs.',
        'imageUrl': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80',
        'isActive': true,
        'sortOrder': 1,
        'productCount': 5,
      },
      {
        'id': 'hand-tools',
        'name': 'Hand Tools',
        'slug': 'hand-tools',
        'description': 'Professional wrenches, screwdrivers, pliers, and hammers built to last.',
        'imageUrl': 'https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80',
        'isActive': true,
        'sortOrder': 2,
        'productCount': 4,
      },
      {
        'id': 'measuring-tools',
        'name': 'Measuring Tools',
        'slug': 'measuring-tools',
        'description': 'Precision laser measures, spirit levels, calipers, and tape measures.',
        'imageUrl': 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=500&auto=format&fit=crop&q=80',
        'isActive': true,
        'sortOrder': 3,
        'productCount': 2,
      },
      {
        'id': 'safety-gear',
        'name': 'Safety Gear',
        'slug': 'safety-gear',
        'description': 'Protective goggles, hard hats, gloves, and high-visibility apparel.',
        'imageUrl': 'https://images.unsplash.com/photo-1590486803833-ffc6f78d2c4a?w=500&auto=format&fit=crop&q=80',
        'isActive': true,
        'sortOrder': 4,
        'productCount': 2,
      },
      {
        'id': 'tool-storage',
        'name': 'Tool Storage',
        'slug': 'tool-storage',
        'description': 'Heavy-duty toolboxes, rolling cabinets, tool bags, and organisers.',
        'imageUrl': 'https://images.unsplash.com/photo-1581244277943-fe4a9c777189?w=500&auto=format&fit=crop&q=80',
        'isActive': true,
        'sortOrder': 5,
        'productCount': 2,
      },
    ];

    for (final cat in categories) {
      final ref = firestore.collection(AppConstants.categoriesCollection).doc(cat['id'] as String);
      batch.set(ref, cat);
    }

    // ─── 2. SEED BANNERS ─────────────────────────────────────────────────────
    final banners = [
      {
        'title': 'Mega Monsoon Sale',
        'subtitle': 'Up to 40% Off on Power Tools',
        'imageUrl': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=1200&auto=format&fit=crop&q=80',
        'actionUrl': '/products?category=power-tools',
        'isActive': true,
        'sortOrder': 1,
      },
      {
        'title': 'Stanley Premium Hand Tools',
        'subtitle': 'Starting from just ₹199',
        'imageUrl': 'https://images.unsplash.com/photo-1530124566582-ab0510491570?w=1200&auto=format&fit=crop&q=80',
        'actionUrl': '/products?brand=stanley',
        'isActive': true,
        'sortOrder': 2,
      },
      {
        'title': 'Safety Gear Essentials',
        'subtitle': 'Ensure protection at every worksite',
        'imageUrl': 'https://images.unsplash.com/photo-1590486803833-ffc6f78d2c4a?w=1200&auto=format&fit=crop&q=80',
        'actionUrl': '/products?category=safety-gear',
        'isActive': true,
        'sortOrder': 3,
      },
    ];

    for (int i = 0; i < banners.length; i++) {
      final ref = firestore.collection(AppConstants.bannersCollection).doc('banner_$i');
      batch.set(ref, banners[i]);
    }

    // ─── 3. SEED PRODUCTS ────────────────────────────────────────────────────
    final now = DateTime.now();
    
    // New Accessory Products for Compatibility Matrix
    final drillBits = ProductModel(
      id: 'prod-bosch-bits',
      sku: 'BOS-BIT-SET-25',
      name: 'Bosch 25-Piece Drill and Screwdriver Bit Set',
      slug: 'bosch-25-piece-drill-bit-set',
      description: 'A comprehensive set of high-grade bits for drilling and fastening. Supplied in a robust storage case, suitable for use with all standard drill brands.',
      brandId: 'bosch',
      brandName: 'Bosch',
      categoryId: 'hand-tools',
      categoryName: 'Hand Tools',
      price: 1500.0,
      discountPrice: 1299.0,
      stockQuantity: 100,
      rating: 4.6,
      reviewCount: 45,
      isActive: true,
      createdAt: now,
      imageUrls: const [
        'https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80'
      ],
      features: const [
        'Includes magnetic universal holder for quick bit changes',
        'Durable bits for all standard screw types and sizes',
        'Housed in a practical and robust case'
      ],
      specifications: '• Pieces in set: 25\n• Holder type: Magnetic\n• Compatibility: All drill chucks',
      bulkPricing: const {
        '10': 0.05,
        '30': 0.10,
      },
    );

    final batteryPack = ProductModel(
      id: 'prod-dewalt-battery',
      sku: 'DEW-BAT-20V-5',
      name: 'DeWalt 20V MAX 5.0Ah Lithium Ion Battery Pack',
      slug: 'dewalt-20v-max-5ah-battery-pack',
      description: 'Keep your cordless power tools running longer with this heavy-duty 20V MAX 5.0Ah XR Lithium Ion battery. Features a 3-LED state of charge fuel gauge for instant capacity feedback.',
      brandId: 'dewalt',
      brandName: 'DeWalt',
      categoryId: 'power-tools',
      categoryName: 'Power Tools',
      price: 4999.0,
      discountPrice: 3999.0,
      stockQuantity: 50,
      rating: 4.7,
      reviewCount: 32,
      isActive: true,
      createdAt: now,
      imageUrls: const [
        'https://images.unsplash.com/photo-1608613304899-ea8098577e38?w=500&auto=format&fit=crop&q=80'
      ],
      features: const [
        '5.0Ah high capacity fuel cell pack for extended runtime',
        '3-LED fuel gauge system allows immediate feedback on state of charge',
        'No memory effect and virtually no self-discharge'
      ],
      specifications: '• Voltage: 20V MAX\n• Capacity: 5.0 Ah\n• Chemistry: Lithium Ion\n• Fuel Gauge: 3-LED',
    );

    final sawBlade = ProductModel(
      id: 'prod-makita-blade',
      sku: 'MAK-BLADE-714',
      name: 'Makita 7-1/4 Inch 24T Carbide-Tipped Saw Blade',
      slug: 'makita-7-1-4-inch-saw-blade',
      description: 'Industrial saw blade engineered for framing and ripping cuts. Thin-kerf design delivers fast and smooth cuts with reduced power draw.',
      brandId: 'makita',
      brandName: 'Makita',
      categoryId: 'power-tools',
      categoryName: 'Power Tools',
      price: 950.0,
      discountPrice: 799.0,
      stockQuantity: 120,
      rating: 4.5,
      reviewCount: 22,
      isActive: true,
      createdAt: now,
      imageUrls: const [
        'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80'
      ],
      features: const [
        '24 Carbide-tipped teeth for durable and fast cutting',
        'Thin-kerf design for longer battery life on cordless saws',
        'Anti-vibration slots reduce noise and heat build-up'
      ],
      specifications: '• Diameter: 7-1/4 inch\n• Teeth: 24 ATB\n• Arbor: 5/8 inch\n• Max RPM: 8,300 RPM',
    );

    final products = [
      drillBits,
      batteryPack,
      sawBlade,
      
      // Power Tools
      ProductModel(
        id: 'prod-bosch-drill',
        sku: 'BOS-GSB-13RE',
        name: 'Bosch Professional Impact Drill GSB 13 RE',
        slug: 'bosch-impact-drill-gsb-13-re',
        description: 'The GSB 13 RE Professional is an entry-level corded 1-gear impact drill. Its 1.7 kg lightweight design and small housing size offer convenient handling and easy maneuverability. It is also exceptionally robust, featuring a durable metal keyless chuck.',
        brandId: 'bosch',
        brandName: 'Bosch',
        categoryId: 'power-tools',
        categoryName: 'Power Tools',
        price: 4500.0,
        discountPrice: 3899.0,
        stockQuantity: 45,
        rating: 4.5,
        reviewCount: 124,
        isActive: true,
        isFeatured: true,
        isBestSeller: true,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'Compact design with soft grip for comfortable handling',
          'Robust metal keyless chuck for fast bit changes',
          'Electronic control for exact pilot drilling',
          'Speed pre-selection with setting wheel'
        ],
        specifications: '• Rated input power: 600 W\n• Weight: 1.7 kg\n• No-load speed: 0 – 2,800 rpm\n• Chuck capacity: 1.5 – 13 mm\n• Impact rate: 0 – 44,800 bpm',
        compatibleProductIds: const ['prod-bosch-bits'],
      ),
      ProductModel(
        id: 'prod-dewalt-drill',
        sku: 'DEW-DCD771C2',
        name: 'DeWalt 20V MAX Cordless Drill Driver Kit',
        slug: 'dewalt-20v-max-cordless-drill-driver',
        brandId: 'dewalt',
        brandName: 'DeWalt',
        categoryId: 'power-tools',
        categoryName: 'Power Tools',
        description: 'The DCD771C2 20V MAX Lithium Ion Compact Drill/Driver Kit is lightweight and compact for working in tight spaces for long periods of time. High-speed transmission delivers 2-speed variations allowing users to choose the level of performance needed for various applications.',
        price: 8999.0,
        discountPrice: 7999.0,
        stockQuantity: 30,
        rating: 4.8,
        reviewCount: 92,
        isActive: true,
        isFeatured: true,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1608613304899-ea8098577e38?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'High performance motor delivers 300 unit watts out (UWO) of power capability',
          'High speed transmission delivers two speeds (0-450 & 1,500 rpm)',
          'Ergonomic handle delivers comfort and control',
          '1/2-inch single sleeve ratcheting chuck provides tight bit gripping strength'
        ],
        specifications: '• Voltage: 20V MAX\n• Max Power: 300 UWO\n• Max RPM: 1,500 RPM\n• Chuck Size: 1/2 inch\n• Clutch Settings: 16',
        compatibleProductIds: const ['prod-dewalt-battery', 'prod-bosch-bits'],
      ),
      ProductModel(
        id: 'prod-makita-saw',
        sku: 'MAK-5007F',
        name: 'Makita 7-1/4 Inch Circular Saw 5007F',
        slug: 'makita-7-1-4-inch-circular-saw',
        brandId: 'makita',
        brandName: 'Makita',
        categoryId: 'power-tools',
        categoryName: 'Power Tools',
        description: 'Makita’s 5007F 7-1/4-Inch Circular Saw features a powerful 15.0 AMP motor and a high power-to-weight ratio, with all ball bearing construction and a heavy gauge aluminum wraparound base for engineered durability and straighter cuts.',
        price: 11200.0,
        discountPrice: 9499.0,
        stockQuantity: 15,
        rating: 4.6,
        reviewCount: 57,
        isActive: true,
        isFeatured: false,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'Powerful 15.0 AMP motor delivers 5,800 RPM for proven performance',
          'Lower guard design improves performance when making bevel and narrow cuts',
          'Large cutting capacity (2-3/8 inches at 90°, 1-3/4 inches at 45°)',
          'Two built-in L.E.D. lights illuminate the line of cut for increased accuracy'
        ],
        specifications: '• Amperage: 15.0 A\n• Blade Diameter: 7-1/4 inch\n• No Load Speed: 5,800 RPM\n• Max Cutting Depth at 90°: 2-3/8 inch\n• Weight: 4.8 kg',
        compatibleProductIds: const ['prod-makita-blade'],
      ),
      // Hand Tools
      ProductModel(
        id: 'prod-stanley-screwdriver',
        sku: 'STA-65-242',
        name: 'Stanley 10-Piece Cushion Grip Screwdriver Set',
        slug: 'stanley-10-piece-screwdrivers-set',
        brandId: 'stanley',
        brandName: 'Stanley',
        categoryId: 'hand-tools',
        categoryName: 'Hand Tools',
        description: 'The Stanley 10-Piece Cushion Grip Screwdriver Set features chrome vanadium blades that resist bending and corrosion, and cushion-grip handles for high comfort and torque. Tips are magnetized for easy handling of screws.',
        price: 1200.0,
        discountPrice: 999.0,
        stockQuantity: 100,
        rating: 4.4,
        reviewCount: 310,
        isActive: true,
        isFeatured: true,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'Cushion-grip handles for comfort and control',
          'Chrome-plated bars for corrosion resistance',
          'Magnetic tips for easy pickup and retention of screws',
          'Includes most popular slotted and Phillips sizes'
        ],
        specifications: '• Material: Chrome Vanadium Steel\n• Handle Material: Rubber (Cushion Grip)\n• Pieces in Set: 10\n• Tip Types: Slotted & Phillips',
        bulkPricing: const {
          '10': 0.05,
          '50': 0.12,
        },
      ),
      ProductModel(
        id: 'prod-taparia-spanner',
        sku: 'TAP-1171',
        name: 'Taparia Adjustable Spanner Wrench 1171',
        slug: 'taparia-adjustable-spanner-wrench',
        brandId: 'taparia',
        brandName: 'Taparia',
        categoryId: 'hand-tools',
        categoryName: 'Hand Tools',
        description: 'Precision marked scale on head indicates jaw opening. Chrome plated and fully polished to resist rust. Manufactured from high grade forge steel and heat treated for longer service life.',
        price: 850.0,
        discountPrice: 650.0,
        stockQuantity: 150,
        rating: 4.3,
        reviewCount: 420,
        isActive: true,
        isFlashSale: true,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'Manufactured from high-grade carbon steel',
          'Accurately marked scale on head for easy jaw preset',
          'Rust resistant chrome finish',
          'Left-hand thumb wheel movement for quick size changes'
        ],
        specifications: '• Length: 300 mm (12 inch)\n• Max Jaw Opening: 36 mm\n• Material: Carbon Steel\n• Weight: 650 g',
        bulkPricing: const {
          '10': 0.05,
          '50': 0.12,
        },
      ),
      ProductModel(
        id: 'prod-stanley-hammer',
        sku: 'STA-51-071',
        name: 'Stanley Claw Hammer Steel Shaft 16oz',
        slug: 'stanley-claw-hammer-16oz',
        brandId: 'stanley',
        brandName: 'Stanley',
        categoryId: 'hand-tools',
        categoryName: 'Hand Tools',
        description: 'Exceeds ANSI specifications. Heat treated steel shaft claw hammer. Custom rubber grip offers excellent shock absorption and slip resistance.',
        price: 750.0,
        discountPrice: 599.0,
        stockQuantity: 80,
        rating: 4.5,
        reviewCount: 88,
        isActive: true,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1530124566582-ab0510491570?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'Heat-treated carbon steel head for strength and durability',
          'Tubular steel shaft for lightweight strength',
          'Claw design for easy nail extraction',
          'Shock-absorbing rubber handle sleeve'
        ],
        specifications: '• Head Weight: 16 oz (450 g)\n• Shaft Material: Tubular Steel\n• Grip Material: Rubberized Sleeve\n• Total Length: 330 mm',
      ),
      // Measuring Tools
      ProductModel(
        id: 'prod-bosch-laser',
        sku: 'BOS-GLM-50C',
        name: 'Bosch Bluetooth Laser Measure GLM 50 C',
        slug: 'bosch-bluetooth-laser-measure',
        brandId: 'bosch',
        brandName: 'Bosch',
        categoryId: 'measuring-tools',
        categoryName: 'Measuring Tools',
        description: 'The Bosch GLM 50 C Bluetooth Laser Measure features a color display with backlighting, inclinometer for angle measurements, and Bluetooth connectivity for transfer of data to the MeasureOn App.',
        price: 7500.0,
        discountPrice: 6499.0,
        stockQuantity: 25,
        rating: 4.7,
        reviewCount: 46,
        isActive: true,
        isFeatured: true,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'Bluetooth functionality to transfer measurements to free MeasureOn app',
          'Color display with backlighting for high visibility',
          'Inclinometer allows for angle measurements and indirect height readings',
          'Includes target plate, hand strap, and protective pouch'
        ],
        specifications: '• Measurement Range: 0.05 – 50.00 m\n• Measurement Accuracy: ± 1.5 mm\n• Laser Diode: 635 nm, < 1 mW (Class 2)\n• Power Supply: 2 x 1.5 V LR03 (AAA)\n• Weight: 100 g',
      ),
      ProductModel(
        id: 'prod-stanley-tape',
        sku: 'STA-30-696',
        name: 'Stanley 5m Tylon Tape Measure',
        slug: 'stanley-5m-tylon-tape-measure',
        brandId: 'stanley',
        brandName: 'Stanley',
        categoryId: 'measuring-tools',
        categoryName: 'Measuring Tools',
        description: 'Tylon coated blade provides anti-glare readings and 1.5x greater abrasion resistance than standard lacquer. Ergonomic bi-material case delivers comfortable grip and lock button accessibility.',
        price: 350.0,
        discountPrice: 280.0,
        stockQuantity: 200,
        rating: 4.6,
        reviewCount: 190,
        isActive: true,
        isBestSeller: true,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'Tylon blade coating for high readability and durability',
          'Ergonomic, shock-resistant bi-material case',
          'Tru-zero hook for accurate inside and outside measurements',
          'Belt clip for convenient carrying'
        ],
        specifications: '• Blade Length: 5 m\n• Blade Width: 19 mm\n• Measurement System: Metric & Imperial\n• Case Material: Bi-material (ABS + Rubber)',
      ),
      // Safety Gear
      ProductModel(
        id: 'prod-3m-goggles',
        sku: '3M-PRO-GLASSES',
        name: '3M Virtua AP Protective Safety Glasses',
        slug: '3m-virtua-ap-safety-glasses',
        brandId: '3m',
        brandName: '3M',
        categoryId: 'safety-gear',
        categoryName: 'Safety Gear',
        description: 'High-quality lightweight polycarbonate safety glasses with wrap-around lens design, offering excellent side coverage and impact protection. Anti-scratch coating ensures long life.',
        price: 450.0,
        discountPrice: 350.0,
        stockQuantity: 300,
        rating: 4.4,
        reviewCount: 85,
        isActive: true,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1590486803833-ffc6f78d2c4a?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'Clear polycarbonate lenses absorb 99.9% UVA and UVB rays',
          'Meets ANSI Z87.1-2015 high impact standards',
          'Anti-scratch coating for durability',
          'Lightweight construction (less than 30g)'
        ],
        specifications: '• Lens Color: Clear\n• Frame Style: Frameless\n• UV Protection: 99.9%\n• Standards: ANSI Z87.1-2015',
        bulkPricing: const {
          '10': 0.10,
          '50': 0.20,
        },
      ),
      // Tool Storage
      ProductModel(
        id: 'prod-dewalt-chest',
        sku: 'DEW-ROLL-CHEST',
        name: 'DeWalt Heavy Duty Rolling Tool Chest Cabinet',
        slug: 'dewalt-heavy-duty-rolling-tool-chest',
        brandId: 'dewalt',
        brandName: 'DeWalt',
        categoryId: 'tool-storage',
        categoryName: 'Tool Storage',
        description: 'Industrial grade 5-drawer rolling tool chest cabinet featuring heavy-duty ball bearing slides, 5x2-inch casters supporting up to 500 kg, and a secure internal keyed locking system.',
        price: 18500.0,
        discountPrice: 15999.0,
        stockQuantity: 8,
        rating: 4.9,
        reviewCount: 34,
        isActive: true,
        isBestSeller: true,
        isFeatured: true,
        createdAt: now,
        imageUrls: const [
          'https://images.unsplash.com/photo-1581244277943-fe4a9c777189?w=500&auto=format&fit=crop&q=80'
        ],
        features: const [
          'Heavy-duty ball-bearing drawer slides support up to 45 kg per drawer',
          'Robust internal keyed lock system protects your tools',
          '5x2-inch heavy-duty casters (2 locking swivel, 2 rigid)',
          'Top wooden workspace provides additional utility area'
        ],
        specifications: '• Dimensions: 68 cm W x 46 cm D x 85 cm H\n• Number of Drawers: 5\n• Weight Capacity: 500 kg\n• Weight: 38 kg\n• Color: DeWalt Yellow & Black',
      ),
    ];

    for (final prod in products) {
      final ref = firestore.collection(AppConstants.productsCollection).doc(prod.id);
      batch.set(ref, prod.toMap());
    }

    await batch.commit();
  }
}
