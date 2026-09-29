// Shared demo catalog used by both the standalone seed script (seed-demo.ts)
// and the server's startup seeding (when SEED_DEMO=true). Fields match the
// product/category schema the API and app expect (snake_case, _id === id).

// ── Categories ─────────────────────────────────────────────────────────────────
export const demoCategories = [
  {
    _id: 'cat-power-tools', id: 'cat-power-tools',
    name: 'Power Tools', slug: 'power-tools',
    description: 'High performance electric and battery-powered tools for professionals.',
    image_url: 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800',
    is_active: true, sort_order: 1, product_count: 4, created_at: new Date(),
  },
  {
    _id: 'cat-hand-tools', id: 'cat-hand-tools',
    name: 'Hand Tools', slug: 'hand-tools',
    description: 'Reliable manual tools for precision work and everyday repairs.',
    image_url: 'https://images.unsplash.com/photo-1581147036324-c1878fde93f7?auto=format&fit=crop&q=80&w=800',
    is_active: true, sort_order: 2, product_count: 4, created_at: new Date(),
  },
  {
    _id: 'cat-safety-gear', id: 'cat-safety-gear',
    name: 'Safety Gear', slug: 'safety-gear',
    description: 'Protective equipment for the worksite and workshop.',
    image_url: 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800',
    is_active: true, sort_order: 3, product_count: 3, created_at: new Date(),
  },
  {
    _id: 'cat-measuring', id: 'cat-measuring',
    name: 'Measuring Tools', slug: 'measuring-tools',
    description: 'Precision measuring and leveling instruments for accurate work.',
    image_url: 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800',
    is_active: true, sort_order: 4, product_count: 2, created_at: new Date(),
  },
  {
    _id: 'cat-garden', id: 'cat-garden',
    name: 'Garden Tools', slug: 'garden-tools',
    description: 'Tools for landscaping, gardening, and outdoor maintenance.',
    image_url: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&q=80&w=800',
    is_active: true, sort_order: 5, product_count: 2, created_at: new Date(),
  },
];

// ── Helper ─────────────────────────────────────────────────────────────────────
const product = (p: any) => ({
  rating: 4.5, review_count: 0, is_active: true,
  is_featured: false, is_best_seller: false, is_flash_sale: false, is_new_arrival: false,
  features: [], specifications: '', compatible_product_ids: [], bulk_pricing: {},
  low_stock_threshold: 5,
  created_at: new Date(),
  ...p,
});

// ── 15 Products ────────────────────────────────────────────────────────────────
export const demoProducts = [

  // ═══════════════════════════════════════════════════════════════════════════
  // POWER TOOLS (4)
  // ═══════════════════════════════════════════════════════════════════════════

  product({
    _id: 'prod-demo-cordless-drill', id: 'prod-demo-cordless-drill',
    sku: 'DW-20V-DRL', name: 'DeWalt 20V MAX Cordless Drill/Driver Kit',
    slug: 'dewalt-20v-max-cordless-drill',
    description: 'Compact, lightweight cordless drill/driver with a high-performance motor delivering 300 unit watts. Includes two 20V MAX batteries, charger, and carrying bag. Perfect for drilling into wood, metal, and plastic.',
    brand_id: 'dewalt', brand_name: 'DeWalt',
    category_id: 'cat-power-tools', category_name: 'Power Tools',
    price: 8999, discount_price: 7499, stock_quantity: 45,
    image_urls: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800'],
    rating: 4.7, review_count: 234,
    is_featured: true, is_best_seller: true,
  }),

  product({
    _id: 'prod-demo-circular-saw', id: 'prod-demo-circular-saw',
    sku: 'MK-18V-SAW', name: 'Makita 18V LXT Brushless Circular Saw',
    slug: 'makita-18v-lxt-circular-saw',
    description: 'Powerful 6-1/2" blade circular saw with a brushless motor for efficient cuts. Features an electric brake for faster blade stops, LED light for improved visibility, and rubberized soft grip for comfort. Cuts 2x lumber at 45° and 90°.',
    brand_id: 'makita', brand_name: 'Makita',
    category_id: 'cat-power-tools', category_name: 'Power Tools',
    price: 11200, discount_price: null, stock_quantity: 20,
    image_urls: ['https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800'],
    rating: 4.8, review_count: 189,
    is_new_arrival: true,
  }),

  product({
    _id: 'prod-demo-angle-grinder', id: 'prod-demo-angle-grinder',
    sku: 'BOS-AG-750', name: 'Bosch 750W Professional Angle Grinder',
    slug: 'bosch-750w-angle-grinder',
    description: 'Slim grip 4-1/2" angle grinder with a powerful 750W motor. Two-position side handle for comfort and control. Ideal for cutting, grinding, and polishing metal, stone, and concrete surfaces.',
    brand_id: 'bosch', brand_name: 'Bosch',
    category_id: 'cat-power-tools', category_name: 'Power Tools',
    price: 3450, discount_price: 2899, stock_quantity: 60,
    image_urls: ['https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=800'],
    rating: 4.5, review_count: 312,
    is_featured: true,
  }),

  product({
    _id: 'prod-demo-jigsaw', id: 'prod-demo-jigsaw',
    sku: 'MIL-JS-650', name: 'Milwaukee M18 FUEL Jigsaw',
    slug: 'milwaukee-m18-fuel-jigsaw',
    description: 'Cordless top-handle jigsaw with POWERSTATE brushless motor for up to 3,500 SPM. REDLINK electronics provide optimized performance and overload protection. Firestrike orbital action for fast, aggressive cuts in wood.',
    brand_id: 'milwaukee', brand_name: 'Milwaukee',
    category_id: 'cat-power-tools', category_name: 'Power Tools',
    price: 13500, discount_price: 11999, stock_quantity: 15,
    image_urls: ['https://images.unsplash.com/photo-1513467535987-fd81bc7d62f8?auto=format&fit=crop&q=80&w=800'],
    rating: 4.6, review_count: 97,
    is_flash_sale: true,
  }),

  // ═══════════════════════════════════════════════════════════════════════════
  // HAND TOOLS (4)
  // ═══════════════════════════════════════════════════════════════════════════

  product({
    _id: 'prod-demo-mechanics-set', id: 'prod-demo-mechanics-set',
    sku: 'ST-100-MEC', name: 'Stanley 145-Piece Mechanics Tool Set',
    slug: 'stanley-145-piece-mechanics-tool-set',
    description: 'Comprehensive chrome vanadium set including 72-tooth ratchets, deep and shallow sockets (SAE & metric), combination wrenches, hex keys, and extension bars. Packaged in a blow-molded carrying case.',
    brand_id: 'stanley', brand_name: 'Stanley',
    category_id: 'cat-hand-tools', category_name: 'Hand Tools',
    price: 4599, discount_price: 3799, stock_quantity: 100,
    image_urls: ['https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800'],
    rating: 4.4, review_count: 518,
    is_featured: true, is_best_seller: true,
  }),

  product({
    _id: 'prod-demo-claw-hammer', id: 'prod-demo-claw-hammer',
    sku: 'EST-E3-20S', name: 'Estwing 20 oz Straight Claw Hammer',
    slug: 'estwing-20oz-straight-claw-hammer',
    description: 'Forged in one piece from solid American steel. Fully polished head and neck with a shock-reducing vinyl grip. The straight claw design is ideal for framing, ripping, and demolition work.',
    brand_id: 'estwing', brand_name: 'Estwing',
    category_id: 'cat-hand-tools', category_name: 'Hand Tools',
    price: 2199, discount_price: null, stock_quantity: 75,
    image_urls: ['https://images.unsplash.com/photo-1586864387789-628af9feed72?auto=format&fit=crop&q=80&w=800'],
    rating: 4.9, review_count: 1203,
  }),

  product({
    _id: 'prod-demo-pliers-set', id: 'prod-demo-pliers-set',
    sku: 'KNP-3PC-SET', name: 'Knipex 3-Piece Pliers Wrench Set',
    slug: 'knipex-3-piece-pliers-wrench-set',
    description: 'German-engineered precision pliers in 7", 10", and 12" sizes. Smooth, parallel jaws replace an entire set of wrenches. Push-button adjustment for exact jaw widths. Chrome vanadium electric steel, oil-hardened.',
    brand_id: 'knipex', brand_name: 'Knipex',
    category_id: 'cat-hand-tools', category_name: 'Hand Tools',
    price: 7800, discount_price: 6999, stock_quantity: 35,
    image_urls: ['https://images.unsplash.com/photo-1581147036324-c1878fde93f7?auto=format&fit=crop&q=80&w=800'],
    rating: 4.8, review_count: 412,
    is_new_arrival: true,
  }),

  product({
    _id: 'prod-demo-screwdriver-set', id: 'prod-demo-screwdriver-set',
    sku: 'WH-SD-25', name: 'Wera Kraftform 25-Piece Screwdriver Set',
    slug: 'wera-25-piece-screwdriver-set',
    description: 'Multi-component Kraftform handle for fast, ergonomic tightening. Hard tip for an exact fit. Includes Phillips, Pozidriv, slotted, Torx, and hex drivers in a sturdy wall-mounted rack.',
    brand_id: 'wera', brand_name: 'Wera',
    category_id: 'cat-hand-tools', category_name: 'Hand Tools',
    price: 5200, discount_price: 4499, stock_quantity: 50,
    image_urls: ['https://images.unsplash.com/photo-1426927308491-6380b6a9936f?auto=format&fit=crop&q=80&w=800'],
    rating: 4.7, review_count: 287,
  }),

  // ═══════════════════════════════════════════════════════════════════════════
  // SAFETY GEAR (3)
  // ═══════════════════════════════════════════════════════════════════════════

  product({
    _id: 'prod-demo-hearing-protector', id: 'prod-demo-hearing-protector',
    sku: '3M-WT-HP', name: '3M WorkTunes Connect Hearing Protector',
    slug: '3m-worktunes-connect-hearing-protector',
    description: 'Bluetooth-enabled hearing protection earmuff with AM/FM radio. 24 dB noise reduction rating. Hi-Fi sound, 40+ hours battery life, and an integrated microphone for hands-free calls on the jobsite.',
    brand_id: '3m', brand_name: '3M',
    category_id: 'cat-safety-gear', category_name: 'Safety Gear',
    price: 3299, discount_price: null, stock_quantity: 30,
    image_urls: ['https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800'],
    rating: 4.3, review_count: 156,
    is_flash_sale: true,
  }),

  product({
    _id: 'prod-demo-safety-goggles', id: 'prod-demo-safety-goggles',
    sku: 'DW-SG-PRO', name: 'DeWalt Anti-Fog Safety Goggles',
    slug: 'dewalt-anti-fog-safety-goggles',
    description: 'Dual-mold rubber conforms to the face for a secure, comfortable seal. Tough polycarbonate lens with anti-fog coating meets ANSI Z87.1+ impact protection. Adjustable elastic headband fits over hard hats.',
    brand_id: 'dewalt', brand_name: 'DeWalt',
    category_id: 'cat-safety-gear', category_name: 'Safety Gear',
    price: 899, discount_price: 699, stock_quantity: 120,
    image_urls: ['https://images.unsplash.com/photo-1585771724684-38269d6639fd?auto=format&fit=crop&q=80&w=800'],
    rating: 4.5, review_count: 89,
  }),

  product({
    _id: 'prod-demo-work-gloves', id: 'prod-demo-work-gloves',
    sku: 'MCX-CG-XL', name: 'Mechanix Wear Original Work Gloves',
    slug: 'mechanix-wear-original-work-gloves',
    description: 'Form-fitting TrekDry material keeps hands cool and comfortable. Seamless palm with a single layer of clarino for maximum dexterity. Reinforced thumb and index finger for added durability.',
    brand_id: 'mechanix', brand_name: 'Mechanix Wear',
    category_id: 'cat-safety-gear', category_name: 'Safety Gear',
    price: 1599, discount_price: 1299, stock_quantity: 200,
    image_urls: ['https://images.unsplash.com/photo-1622905810727-0330951a4430?auto=format&fit=crop&q=80&w=800'],
    rating: 4.6, review_count: 743,
    is_best_seller: true,
  }),

  // ═══════════════════════════════════════════════════════════════════════════
  // MEASURING TOOLS (2)
  // ═══════════════════════════════════════════════════════════════════════════

  product({
    _id: 'prod-demo-laser-level', id: 'prod-demo-laser-level',
    sku: 'BOS-GLL-50', name: 'Bosch Self-Leveling Cross-Line Laser Level',
    slug: 'bosch-self-leveling-laser-level',
    description: 'Projects bright, visible horizontal and vertical laser lines with an accuracy of ±1/8" at 30 ft. Smart pendulum self-leveling system within ±4°. Includes flexible mounting device and protective pouch.',
    brand_id: 'bosch', brand_name: 'Bosch',
    category_id: 'cat-measuring', category_name: 'Measuring Tools',
    price: 6800, discount_price: 5999, stock_quantity: 25,
    image_urls: ['https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=800'],
    rating: 4.4, review_count: 178,
    is_featured: true,
  }),

  product({
    _id: 'prod-demo-tape-measure', id: 'prod-demo-tape-measure',
    sku: 'ST-TM-25', name: 'Stanley FatMax 25 ft Tape Measure',
    slug: 'stanley-fatmax-25ft-tape-measure',
    description: 'Extra-wide 1-1/4" blade stands out up to 13 ft for easy overhead and long-reach measurements. Mylar polyester film blade coating for durability. BladeArmor coating on the first 6" for added protection.',
    brand_id: 'stanley', brand_name: 'Stanley',
    category_id: 'cat-measuring', category_name: 'Measuring Tools',
    price: 1499, discount_price: null, stock_quantity: 150,
    image_urls: ['https://images.unsplash.com/photo-1590859808308-3d2d9c515b1a?auto=format&fit=crop&q=80&w=800'],
    rating: 4.6, review_count: 934,
    is_best_seller: true,
  }),

  // ═══════════════════════════════════════════════════════════════════════════
  // GARDEN TOOLS (2)
  // ═══════════════════════════════════════════════════════════════════════════

  product({
    _id: 'prod-demo-pruning-shears', id: 'prod-demo-pruning-shears',
    sku: 'FEL-PX-8', name: 'Felco F-2 Classic Bypass Pruning Shears',
    slug: 'felco-f2-classic-bypass-pruning-shears',
    description: 'Swiss-made professional pruning shears with hardened steel blade and anvil. Lifetime warranty with fully replaceable parts. Ergonomic, non-slip handles with a wire-cutting notch. Cuts branches up to 1" diameter.',
    brand_id: 'felco', brand_name: 'Felco',
    category_id: 'cat-garden', category_name: 'Garden Tools',
    price: 4200, discount_price: 3699, stock_quantity: 40,
    image_urls: ['https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&q=80&w=800'],
    rating: 4.9, review_count: 621,
    is_featured: true,
  }),

  product({
    _id: 'prod-demo-garden-spade', id: 'prod-demo-garden-spade',
    sku: 'FIS-GS-46', name: 'Fiskars 46" Steel D-Handle Garden Spade',
    slug: 'fiskars-46-steel-garden-spade',
    description: 'Welded 18-gauge steel head with a sharpened edge slices easily through roots and tough soil. Heavy-duty steel shaft with a large D-handle for comfortable, two-handed leverage. Built to last with a lifetime warranty.',
    brand_id: 'fiskars', brand_name: 'Fiskars',
    category_id: 'cat-garden', category_name: 'Garden Tools',
    price: 2800, discount_price: null, stock_quantity: 55,
    image_urls: ['https://images.unsplash.com/photo-1599686101742-e72c318bfa81?auto=format&fit=crop&q=80&w=800'],
    rating: 4.3, review_count: 198,
    is_new_arrival: true,
  }),
];
