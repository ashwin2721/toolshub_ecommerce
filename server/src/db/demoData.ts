// Shared demo catalog used by both the standalone seed script (seed-demo.ts)
// and the server's startup seeding (when SEED_DEMO=true). Fields match the
// product/category schema the API and app expect (snake_case, _id === id).

export const demoCategories = [
  {
    _id: 'cat-power-tools', id: 'cat-power-tools',
    name: 'Power Tools', slug: 'power-tools',
    description: 'High performance electric and battery-powered tools.',
    image_url: 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800',
    is_active: true, sort_order: 1, product_count: 2, created_at: new Date(),
  },
  {
    _id: 'cat-hand-tools', id: 'cat-hand-tools',
    name: 'Hand Tools', slug: 'hand-tools',
    description: 'Reliable manual tools for precision work.',
    image_url: 'https://images.unsplash.com/photo-1581147036324-c1878fde93f7?auto=format&fit=crop&q=80&w=800',
    is_active: true, sort_order: 2, product_count: 1, created_at: new Date(),
  },
  {
    _id: 'cat-safety-gear', id: 'cat-safety-gear',
    name: 'Safety Gear', slug: 'safety-gear',
    description: 'Protective equipment for the worksite.',
    image_url: 'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800',
    is_active: true, sort_order: 3, product_count: 1, created_at: new Date(),
  },
];

const product = (p: any) => ({
  rating: 4.6, review_count: 0, is_active: true,
  is_featured: false, is_best_seller: false, is_flash_sale: false, is_new_arrival: false,
  features: [], specifications: '', compatible_product_ids: [], bulk_pricing: {},
  created_at: new Date(),
  ...p,
});

export const demoProducts = [
  product({
    _id: 'prod-demo-dewalt-drill', id: 'prod-demo-dewalt-drill',
    sku: 'DW-20V-DRL', name: 'DeWalt 20V MAX Cordless Drill',
    slug: 'dewalt-20v-max-cordless-drill',
    description: 'Compact cordless drill/driver kit. Includes 2 batteries and charger.',
    brand_id: 'dewalt', brand_name: 'DeWalt',
    category_id: 'cat-power-tools', category_name: 'Power Tools',
    price: 8999, discount_price: 7499, stock_quantity: 45,
    image_urls: ['https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&q=80&w=800'],
    is_featured: true, is_best_seller: true,
  }),
  product({
    _id: 'prod-demo-makita-saw', id: 'prod-demo-makita-saw',
    sku: 'MK-18V-SAW', name: 'Makita 18V LXT Circular Saw',
    slug: 'makita-18v-lxt-circular-saw',
    description: 'Powerful 6-1/2" circular saw with brushless motor.',
    brand_id: 'makita', brand_name: 'Makita',
    category_id: 'cat-power-tools', category_name: 'Power Tools',
    price: 11200, discount_price: null, stock_quantity: 20,
    image_urls: ['https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&q=80&w=800'],
    is_new_arrival: true,
  }),
  product({
    _id: 'prod-demo-stanley-set', id: 'prod-demo-stanley-set',
    sku: 'ST-100-MEC', name: 'Stanley 100-Piece Mechanics Tool Set',
    slug: 'stanley-100-piece-mechanics-tool-set',
    description: 'Comprehensive set of sockets, wrenches, and hex keys.',
    brand_id: 'stanley', brand_name: 'Stanley',
    category_id: 'cat-hand-tools', category_name: 'Hand Tools',
    price: 4599, discount_price: 3799, stock_quantity: 100,
    image_urls: ['https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=800'],
    is_featured: true,
  }),
  product({
    _id: 'prod-demo-3m-hearing', id: 'prod-demo-3m-hearing',
    sku: '3M-WT-HP', name: '3M WorkTunes Connect Hearing Protector',
    slug: '3m-worktunes-connect-hearing-protector',
    description: 'Bluetooth hearing protection with excellent noise reduction.',
    brand_id: '3m', brand_name: '3M',
    category_id: 'cat-safety-gear', category_name: 'Safety Gear',
    price: 3299, discount_price: null, stock_quantity: 30,
    image_urls: ['https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&q=80&w=800'],
    is_flash_sale: true,
  }),
];
