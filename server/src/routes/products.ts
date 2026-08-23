import { Router } from 'express';
import crypto from 'crypto';
import { products, categories, banners, coupons } from '../db/mongo';
import { authenticateToken, requireAdmin } from '../middlewares/auth';

const router = Router();

// Map a product document to the camelCase shape the frontend models expect.
const mapProduct = (row: any) => ({
  id: row.id,
  sku: row.sku,
  name: row.name,
  slug: row.slug,
  description: row.description,
  brandId: row.brand_id,
  brandName: row.brand_name,
  categoryId: row.category_id,
  categoryName: row.category_name,
  price: Number(row.price),
  discountPrice: row.discount_price != null ? Number(row.discount_price) : null,
  stockQuantity: row.stock_quantity,
  rating: Number(row.rating ?? 0),
  reviewCount: row.review_count ?? 0,
  isActive: row.is_active,
  isFeatured: row.is_featured,
  isBestSeller: row.is_best_seller,
  isFlashSale: row.is_flash_sale,
  isNewArrival: row.is_new_arrival,
  features: row.features,
  specifications: row.specifications,
  imageUrls: row.image_urls,
  compatibleProductIds: row.compatible_product_ids,
  bulkPricing: row.bulk_pricing,
  createdAt: row.created_at,
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
    name, sku, description, price, discountPrice, stockQuantity,
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
    name, sku, description, price, discountPrice, stockQuantity,
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

export default router;
