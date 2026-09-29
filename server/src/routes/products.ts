import { Router } from 'express';
import crypto from 'crypto';
import { products, categories, banners, coupons, reviews, users } from '../db/mongo';
import { authenticateToken, requireAdmin, AuthRequest } from '../middlewares/auth';

const router = Router();

// Map a product document to the camelCase shape the frontend models expect.
const mapProduct = (row: any) => ({
  id: row.id || row._id?.toString() || '',
  sku: row.sku || '',
  name: row.name || '',
  slug: row.slug || '',
  description: row.description || '',
  brandId: row.brand_id || null,
  brandName: row.brand_name || '',
  categoryId: row.category_id || '',
  categoryName: row.category_name || '',
  price: Number(row.price || 0),
  discountPrice: row.discount_price != null ? Number(row.discount_price) : null,
  stockQuantity: row.stock_quantity ?? row.stock ?? 50,
  rating: Number(row.rating ?? 0),
  reviewCount: Number(row.review_count ?? 0),
  isActive: row.is_active ?? true,
  isFeatured: row.is_featured ?? false,
  isBestSeller: row.is_best_seller ?? false,
  isFlashSale: row.is_flash_sale ?? false,
  isNewArrival: row.is_new_arrival ?? false,
  features: row.features || null,
  specifications: row.specifications || null,
  imageUrls: row.image_urls || [],
  compatibleProductIds: row.compatible_product_ids || null,
  bulkPricing: row.bulk_pricing || null,
  lowStockThreshold: row.low_stock_threshold ?? 5,
  createdAt: row.created_at || new Date().toISOString(),
});

const escapeRegex = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// 1. Get Banners (active, customer-facing)
router.get('/banners', async (req, res) => {
  try {
    const rows = await banners().find({ is_active: true }).sort({ sort_order: 1 }).toArray();
    res.json(rows.map((b) => ({
      id: b.id,
      title: b.title,
      subtitle: b.subtitle,
      imageUrl: b.image_url,
      actionUrl: b.action_url,
      isActive: b.is_active,
      sortOrder: b.sort_order,
    })));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Get Categories (active)
router.get('/categories', async (req, res) => {
  try {
    const rows = await categories().find({ is_active: true }).sort({ sort_order: 1 }).toArray();
    res.json(rows.map((c) => ({
      id: c.id,
      name: c.name,
      slug: c.slug,
      description: c.description,
      imageUrl: c.image_url,
      isActive: c.is_active,
      sortOrder: c.sort_order,
      productCount: c.product_count,
    })));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 3. Get Products (with filters, search, and sorting)
router.get('/products', async (req, res) => {
  const { category, brand, isFeatured, isBestSeller, isFlashSale, isNewArrival, q, sortBy, limit, minPrice, maxPrice } = req.query;

  const filter: any = { is_active: true };
  if (category) filter.category_id = category;
  if (brand) filter.brand_id = brand;

  const minPriceNum = parseFloat(minPrice as string);
  const maxPriceNum = parseFloat(maxPrice as string);
  if (!isNaN(minPriceNum) || !isNaN(maxPriceNum)) {
    filter.price = {};
    if (!isNaN(minPriceNum)) filter.price.$gte = minPriceNum;
    if (!isNaN(maxPriceNum)) filter.price.$lte = maxPriceNum;
  }

  if (isFeatured === 'true') filter.is_featured = true;
  if (isBestSeller === 'true') filter.is_best_seller = true;
  if (isFlashSale === 'true') filter.is_flash_sale = true;
  if (isNewArrival === 'true') filter.is_new_arrival = true;

  if (q && (q as string).trim().length > 0) {
    const rx = new RegExp(escapeRegex((q as string).trim()), 'i');
    filter.$or = [{ name: rx }, { brand_name: rx }, { description: rx }];
  }

  let sortSpec: Record<string, 1 | -1> = { created_at: -1 };
  switch (sortBy) {
    case 'priceLowToHigh': sortSpec = { price: 1 }; break;
    case 'priceHighToLow': sortSpec = { price: -1 }; break;
    case 'bestRated': sortSpec = { rating: -1 }; break;
    case 'popular': sortSpec = { review_count: -1 }; break;
  }

  const limitNum = parseInt(limit as string) || 20;

  try {
    const rows = await products().find(filter).sort(sortSpec).limit(limitNum).toArray();
    res.json(rows.map(mapProduct));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Admin product list — returns ALL products (active + inactive) so the admin
// can see and re-enable disabled products. MUST be before '/products/:id'.
router.get('/products/admin', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const rows = await products().find({}).sort({ created_at: -1 }).toArray();
    res.json(rows.map(mapProduct));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 4. Get Product by ID
router.get('/products/:id', async (req, res) => {
  try {
    const row = await products().findOne({ _id: req.params.id });
    if (!row) {
      return res.status(404).json({ error: 'Product not found' });
    }
    res.json(mapProduct(row));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 5. Add Product (Admin only)
router.post('/products', authenticateToken, requireAdmin, async (req, res) => {
  const {
    name, sku, description, price, discountPrice, stockQuantity, lowStockThreshold,
    categoryId, brandId, brandName, isFeatured, isFlashSale, isNewArrival,
    features, specifications, imageUrls, compatibleProductIds, bulkPricing,
  } = req.body;

  if (!name || !sku || !price) {
    return res.status(400).json({ error: 'Name, SKU, and price are required' });
  }

  try {
    const id = `prod-${crypto.randomUUID()}`;
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');

    let categoryName: string | null = null;
    if (categoryId) {
      const cat = await categories().findOne({ _id: categoryId });
      if (cat) categoryName = cat.name;
    }

    await products().insertOne({
      _id: id,
      id,
      sku,
      name,
      slug,
      description: description || null,
      brand_id: brandId || null,
      brand_name: brandName || null,
      category_id: categoryId || null,
      category_name: categoryName,
      price: Number(price),
      discount_price: discountPrice != null ? Number(discountPrice) : null,
      stock_quantity: stockQuantity || 0,
      low_stock_threshold: lowStockThreshold ?? 5,
      rating: 0,
      review_count: 0,
      is_active: true,
      is_featured: !!isFeatured,
      is_best_seller: false,
      is_flash_sale: !!isFlashSale,
      is_new_arrival: !!isNewArrival,
      features: features || null,
      specifications: specifications || null,
      image_urls: imageUrls || null,
      compatible_product_ids: compatibleProductIds || null,
      bulk_pricing: bulkPricing || null,
      created_at: new Date(),
    });

    res.status(201).json({ id, message: 'Product created successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 6. Update Product (Admin only) — only provided fields are changed.
router.put('/products/:id', authenticateToken, requireAdmin, async (req, res) => {
  const { id } = req.params;
  const {
    name, sku, description, price, discountPrice, stockQuantity, lowStockThreshold,
    categoryId, brandId, isFeatured, isFlashSale, isNewArrival,
    features, specifications, imageUrls, compatibleProductIds, bulkPricing, isActive,
  } = req.body;

  try {
    const existing = await products().findOne({ _id: id });
    if (!existing) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const set: any = {};
    if (name != null) {
      set.name = name;
      set.slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');
    }
    if (sku != null) set.sku = sku;
    if (description != null) set.description = description;
    if (brandId != null) { set.brand_id = brandId; set.brand_name = brandId; }
    if (categoryId != null) {
      set.category_id = categoryId;
      const cat = await categories().findOne({ _id: categoryId });
      if (cat) set.category_name = cat.name;
    }
    if (price != null) set.price = Number(price);
    if (discountPrice != null) set.discount_price = Number(discountPrice);
    if (stockQuantity !== undefined) set.stock_quantity = stockQuantity;
    if (lowStockThreshold !== undefined) set.low_stock_threshold = lowStockThreshold;
    if (isFeatured !== undefined) set.is_featured = isFeatured;
    if (isFlashSale !== undefined) set.is_flash_sale = isFlashSale;
    if (isNewArrival !== undefined) set.is_new_arrival = isNewArrival;
    if (features != null) set.features = features;
    if (specifications != null) set.specifications = specifications;
    if (imageUrls != null) set.image_urls = imageUrls;
    if (compatibleProductIds != null) set.compatible_product_ids = compatibleProductIds;
    if (bulkPricing != null) set.bulk_pricing = bulkPricing;
    if (isActive !== undefined) set.is_active = isActive;

    if (Object.keys(set).length > 0) {
      await products().updateOne({ _id: id }, { $set: set });
    }

    res.json({ message: 'Product updated successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 7. Delete Product (Admin only)
router.delete('/products/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const existing = await products().findOne({ _id: req.params.id });
    if (!existing) {
      return res.status(404).json({ error: 'Product not found' });
    }
    await products().deleteOne({ _id: req.params.id });
    res.json({ message: 'Product deleted successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ── Banners (admin management) ──────────────────────────────────────────────
const mapBanner = (b: any) => ({
  id: b.id,
  title: b.title,
  subtitle: b.subtitle,
  imageUrl: b.image_url,
  actionUrl: b.action_url,
  isActive: b.is_active,
  sortOrder: b.sort_order,
});

router.get('/banners/admin', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const rows = await banners().find({}).sort({ sort_order: 1 }).toArray();
    res.json(rows.map(mapBanner));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/banners', authenticateToken, requireAdmin, async (req, res) => {
  const { title, subtitle, imageUrl, actionUrl, sortOrder, isActive } = req.body;
  try {
    const id = `banner-${crypto.randomUUID()}`;
    await banners().insertOne({
      _id: id, id,
      title: title || 'Banner',
      subtitle: subtitle || null,
      image_url: imageUrl || null,
      action_url: actionUrl || null,
      is_active: isActive !== false,
      sort_order: sortOrder || 0,
    });
    res.status(201).json({ id });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/banners/:id', authenticateToken, requireAdmin, async (req, res) => {
  const { title, subtitle, imageUrl, actionUrl, sortOrder, isActive } = req.body;
  const set: any = {};
  if (title !== undefined) set.title = title;
  if (subtitle !== undefined) set.subtitle = subtitle;
  if (imageUrl !== undefined) set.image_url = imageUrl;
  if (actionUrl !== undefined) set.action_url = actionUrl;
  if (sortOrder !== undefined) set.sort_order = sortOrder;
  if (isActive !== undefined) set.is_active = isActive;
  try {
    await banners().updateOne({ _id: req.params.id }, { $set: set });
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ── Coupons (admin management) ──────────────────────────────────────────────
const mapCoupon = (c: any) => ({
  id: c.id,
  code: c.code,
  type: c.type,
  value: c.value,
  isActive: c.is_active,
  usedCount: c.used_count,
  createdAt: c.created_at,
});

router.get('/coupons', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const rows = await coupons().find({}).sort({ created_at: -1 }).toArray();
    res.json(rows.map(mapCoupon));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/coupons', authenticateToken, requireAdmin, async (req, res) => {
  const { code, type, value } = req.body;
  if (!code) return res.status(400).json({ error: 'Coupon code is required' });
  try {
    const id = `coupon-${crypto.randomUUID()}`;
    await coupons().insertOne({
      _id: id, id,
      code: String(code).toUpperCase(),
      type: type || 'percentage',
      value: Number(value) || 0,
      is_active: true,
      used_count: 0,
      created_at: new Date(),
    });
    res.status(201).json({ id });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/coupons/:id', authenticateToken, requireAdmin, async (req, res) => {
  const set: any = {};
  if (req.body.isActive !== undefined) set.is_active = req.body.isActive;
  if (req.body.code !== undefined) set.code = String(req.body.code).toUpperCase();
  if (req.body.type !== undefined) set.type = req.body.type;
  if (req.body.value !== undefined) set.value = Number(req.body.value);
  try {
    await coupons().updateOne({ _id: req.params.id }, { $set: set });
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ── Product reviews ─────────────────────────────────────────────────────────
router.get('/products/:id/reviews', async (req, res) => {
  try {
    const rows = await reviews()
      .find({ product_id: req.params.id })
      .sort({ created_at: -1 })
      .toArray();
    res.json(rows.map((r) => ({
      id: r.id,
      productId: r.product_id,
      userId: r.user_id,
      userName: r.user_name,
      rating: r.rating,
      comment: r.comment,
      createdAt: r.created_at,
    })));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Add a review (any signed-in user). Recomputes the product's average rating.
router.post('/products/:id/reviews', authenticateToken, async (req: AuthRequest, res) => {
  if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
  const rating = Number(req.body.rating);
  const comment = (req.body.comment || '').toString();
  if (!Number.isFinite(rating) || rating < 1 || rating > 5) {
    return res.status(400).json({ error: 'Rating must be between 1 and 5' });
  }
  try {
    const product = await products().findOne({ _id: req.params.id });
    if (!product) return res.status(404).json({ error: 'Product not found' });

    const u = await users().findOne({ _id: req.user.id });
    const id = `review-${crypto.randomUUID()}`;
    await reviews().insertOne({
      _id: id,
      id,
      product_id: req.params.id,
      user_id: req.user.id,
      user_name: u?.name || 'Customer',
      rating,
      comment,
      created_at: new Date(),
    });

    // Recompute the product's average rating and review count.
    const all = await reviews().find({ product_id: req.params.id }).toArray();
    const count = all.length;
    const avg = count ? all.reduce((s, x) => s + (x.rating || 0), 0) / count : 0;
    await products().updateOne(
      { _id: req.params.id },
      { $set: { rating: Math.round(avg * 10) / 10, review_count: count } }
    );

    res.status(201).json({ id, message: 'Review added successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// All reviews across products (Admin only) — for the admin reviews list.
router.get('/reviews', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const rows = await reviews().find({}).sort({ created_at: -1 }).toArray();
    const prods = await products().find({}).toArray();
    const nameById: Record<string, string> = {};
    for (const p of prods) nameById[p.id] = p.name;
    res.json(rows.map((r) => ({
      id: r.id,
      productId: r.product_id,
      productName: nameById[r.product_id] || r.product_id,
      userName: r.user_name,
      rating: r.rating,
      comment: r.comment,
      createdAt: r.created_at,
    })));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Validate a promo code (public) — returns the coupon if it's active.
router.get('/coupons/validate', async (req, res) => {
  const code = String(req.query.code || '').toUpperCase().trim();
  if (!code) return res.status(400).json({ error: 'Coupon code required' });
  try {
    const c = await coupons().findOne({ code, is_active: true });
    if (!c) return res.status(404).json({ error: 'Invalid or expired coupon code' });
    res.json({ valid: true, code: c.code, type: c.type, value: c.value });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
