import { Router } from 'express';
import crypto from 'crypto';
import { query } from '../db';
import { authenticateToken, requireAdmin } from '../middlewares/auth';

const router = Router();

// 1. Get Banners
router.get('/banners', async (req, res) => {
  try {
    const result = await query(
      'SELECT id, title, subtitle, image_url as "imageUrl", action_url as "actionUrl", is_active as "isActive", sort_order as "sortOrder" FROM banners WHERE is_active = true ORDER BY sort_order ASC'
    );
    res.json(result.rows);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Get Categories
router.get('/categories', async (req, res) => {
  try {
    const result = await query(
      'SELECT id, name, slug, description, image_url as "imageUrl", is_active as "isActive", sort_order as "sortOrder", product_count as "productCount" FROM categories WHERE is_active = true ORDER BY sort_order ASC'
    );
    res.json(result.rows);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 3. Get Products (with filters, search, and sorting)
router.get('/products', async (req, res) => {
  const { category, brand, isFeatured, isBestSeller, isFlashSale, isNewArrival, q, sortBy, limit, minPrice, maxPrice } = req.query;
  
  let queryText = 'SELECT * FROM products WHERE is_active = true';
  const params: any[] = [];
  let paramCount = 1;

  if (category) {
    queryText += ` AND category_id = $${paramCount}`;
    params.push(category);
    paramCount++;
  }

  if (brand) {
    queryText += ` AND brand_id = $${paramCount}`;
    params.push(brand);
    paramCount++;
  }

  const minPriceNum = parseFloat(minPrice as string);
  if (!isNaN(minPriceNum)) {
    queryText += ` AND price >= $${paramCount}`;
    params.push(minPriceNum);
    paramCount++;
  }

  const maxPriceNum = parseFloat(maxPrice as string);
  if (!isNaN(maxPriceNum)) {
    queryText += ` AND price <= $${paramCount}`;
    params.push(maxPriceNum);
    paramCount++;
  }

  if (isFeatured === 'true') {
    queryText += ` AND is_featured = true`;
  }

  if (isBestSeller === 'true') {
    queryText += ` AND is_best_seller = true`;
  }

  if (isFlashSale === 'true') {
    queryText += ` AND is_flash_sale = true`;
  }

  if (isNewArrival === 'true') {
    queryText += ` AND is_new_arrival = true`;
  }

  if (q && (q as string).trim().length > 0) {
    queryText += ` AND (LOWER(name) LIKE $${paramCount} OR LOWER(brand_name) LIKE $${paramCount} OR LOWER(description) LIKE $${paramCount})`;
    params.push(`%${(q as string).trim().toLowerCase()}%`);
    paramCount++;
  }

  // Sorting
  switch (sortBy) {
    case 'priceLowToHigh':
      queryText += ' ORDER BY price ASC';
      break;
    case 'priceHighToLow':
      queryText += ' ORDER BY price DESC';
      break;
    case 'bestRated':
      queryText += ' ORDER BY rating DESC';
      break;
    case 'popular':
      queryText += ' ORDER BY review_count DESC';
      break;
    default:
      queryText += ' ORDER BY created_at DESC';
  }

  const limitNum = parseInt(limit as string) || 20;
  queryText += ` LIMIT $${paramCount}`;
  params.push(limitNum);

  try {
    const result = await query(queryText, params);
    
    // Map database column names to camelCase for the frontend models
    const mapped = result.rows.map(row => ({
      id: row.id,
      sku: row.sku,
      name: row.name,
      slug: row.slug,
      description: row.description,
      brandId: row.brand_id,
      brandName: row.brand_name,
      categoryId: row.category_id,
      categoryName: row.category_name,
      price: parseFloat(row.price),
      discountPrice: row.discount_price ? parseFloat(row.discount_price) : null,
      stockQuantity: row.stock_quantity,
      rating: parseFloat(row.rating),
      reviewCount: row.review_count,
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
      createdAt: row.created_at
    }));

    res.json(mapped);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 4. Get Product by ID
router.get('/products/:id', async (req, res) => {
  try {
    const result = await query('SELECT * FROM products WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    const row = result.rows[0];
    res.json({
      id: row.id,
      sku: row.sku,
      name: row.name,
      slug: row.slug,
      description: row.description,
      brandId: row.brand_id,
      brandName: row.brand_name,
      categoryId: row.category_id,
      categoryName: row.category_name,
      price: parseFloat(row.price),
      discountPrice: row.discount_price ? parseFloat(row.discount_price) : null,
      stockQuantity: row.stock_quantity,
      rating: parseFloat(row.rating),
      reviewCount: row.review_count,
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
      createdAt: row.created_at
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 5. Add Product (Admin only)
router.post('/products', authenticateToken, requireAdmin, async (req, res) => {
  const {
    name, sku, description, price, discountPrice, stockQuantity,
    categoryId, brandId, brandName, isFeatured, isFlashSale, isNewArrival,
    features, specifications, imageUrls, compatibleProductIds, bulkPricing
  } = req.body;

  if (!name || !sku || !price) {
    return res.status(400).json({ error: 'Name, SKU, and price are required' });
  }

  try {
    const id = `prod-${crypto.randomUUID()}`;
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');
    
    // Find category name if categoryId is provided
    let categoryName = null;
    if (categoryId) {
      const catRes = await query('SELECT name FROM categories WHERE id = $1', [categoryId]);
      if (catRes.rows.length > 0) {
        categoryName = catRes.rows[0].name;
      }
    }

    await query(
      `INSERT INTO products (
        id, sku, name, slug, description, brand_id, brand_name, 
        category_id, category_name, price, discount_price, stock_quantity,
        is_featured, is_flash_sale, is_new_arrival, features, specifications, 
        image_urls, compatible_product_ids, bulk_pricing
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)`,
      [
        id, sku, name, slug, description || null, brandId || null, brandName || null,
        categoryId || null, categoryName, price, discountPrice || null, stockQuantity || 0,
        !!isFeatured, !!isFlashSale, !!isNewArrival, features || null, specifications || null,
        imageUrls || null, compatibleProductIds || null, bulkPricing ? JSON.stringify(bulkPricing) : null
      ]
    );

    res.status(201).json({ id, message: 'Product created successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 6. Update Product (Admin only)
router.put('/products/:id', authenticateToken, requireAdmin, async (req, res) => {
  const { id } = req.params;
  const {
    name, sku, description, price, discountPrice, stockQuantity,
    categoryId, brandId, isFeatured, isFlashSale, isNewArrival,
    features, specifications, imageUrls, compatibleProductIds, bulkPricing, isActive
  } = req.body;

  try {
    const existing = await query('SELECT id FROM products WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    // Find category name if categoryId is provided
    let categoryName = null;
    if (categoryId) {
      const catRes = await query('SELECT name FROM categories WHERE id = $1', [categoryId]);
      if (catRes.rows.length > 0) {
        categoryName = catRes.rows[0].name;
      }
    }

    const slug = name ? name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '') : undefined;

    await query(
      `UPDATE products SET 
        name = COALESCE($1, name),
        sku = COALESCE($2, sku),
        slug = COALESCE($3, slug),
        description = COALESCE($4, description),
        brand_id = COALESCE($5, brand_id),
        brand_name = COALESCE($5, brand_name),
        category_id = COALESCE($6, category_id),
        category_name = COALESCE($7, category_name),
        price = COALESCE($8, price),
        discount_price = COALESCE($9, discount_price),
        stock_quantity = COALESCE($10, stock_quantity),
        is_featured = COALESCE($11, is_featured),
        is_flash_sale = COALESCE($12, is_flash_sale),
        is_new_arrival = COALESCE($13, is_new_arrival),
        features = COALESCE($14, features),
        specifications = COALESCE($15, specifications),
        image_urls = COALESCE($16, image_urls),
        compatible_product_ids = COALESCE($17, compatible_product_ids),
        bulk_pricing = COALESCE($18, bulk_pricing),
        is_active = COALESCE($19, is_active)
      WHERE id = $20`,
      [
        name || null, sku || null, slug || null, description || null, brandId || null,
        categoryId || null, categoryName, price || null, discountPrice || null, stockQuantity !== undefined ? stockQuantity : null,
        isFeatured !== undefined ? isFeatured : null, isFlashSale !== undefined ? isFlashSale : null, isNewArrival !== undefined ? isNewArrival : null,
        features || null, specifications || null, imageUrls || null, compatibleProductIds || null,
        bulkPricing ? JSON.stringify(bulkPricing) : null, isActive !== undefined ? isActive : null,
        id
      ]
    );

    res.json({ message: 'Product updated successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// 7. Delete Product (Admin only)
router.delete('/products/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const existing = await query('SELECT id FROM products WHERE id = $1', [req.params.id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    await query('DELETE FROM products WHERE id = $1', [req.params.id]);
    res.json({ message: 'Product deleted successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
