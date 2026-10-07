import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String sku;
  final String? barcode;
  final String name;
  final String slug;
  final String description;
  final String? specifications;
  final List<String> features;
  final String brandId;
  final String brandName;
  final String categoryId;
  final String categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final double price;
  final double? discountPrice;
  final int stockQuantity;
  final String? warrantyInfo;
  final double? weight;
  final ProductDimensions? dimensions;
  final ShippingInfo? shippingInfo;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final bool isFeatured;
  final bool isFlashSale;
  final bool isNewArrival;
  final bool isBestSeller;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? attributes;
  final List<String>? tags;
  final List<String>? compatibleProductIds;
  final Map<String, dynamic>? bulkPricing;

  /// Link to a partner store (Amazon, Flipkart, ...). When set, this product
  /// is bought there rather than here: the storefront shows a "Buy on <store>"
  /// button instead of Add to Cart, and it can never enter a cart or an order.
  final String? externalUrl;

  /// Display name of that store, derived server-side from the link's host.
  final String? externalStoreName;

  const ProductEntity({
    required this.id,
    required this.sku,
    this.barcode,
    required this.name,
    required this.slug,
    required this.description,
    this.specifications,
    this.features = const [],
    required this.brandId,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.imageUrls = const [],
    this.videoUrls = const [],
    required this.price,
    this.discountPrice,
    this.stockQuantity = 0,
    this.warrantyInfo,
    this.weight,
    this.dimensions,
    this.shippingInfo,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.isFlashSale = false,
    this.isNewArrival = false,
    this.isBestSeller = false,
    required this.createdAt,
    this.updatedAt,
    this.attributes,
    this.tags,
    this.compatibleProductIds,
    this.bulkPricing,
    this.externalUrl,
    this.externalStoreName,
  });


  double get effectivePrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  double get discountPercent =>
      hasDiscount ? ((price - discountPrice!) / price * 100).roundToDouble() : 0;
  /// True only when there is a usable link, so a half-saved record can never
  /// render a button that opens nothing. Gate all external UI on this, never
  /// on `externalUrl != null` alone.
  bool get isExternalLink =>
      externalUrl != null && externalUrl!.trim().isNotEmpty;

  /// What to call the partner store in a button label.
  String get externalStoreLabel =>
      (externalStoreName != null && externalStoreName!.trim().isNotEmpty)
          ? externalStoreName!.trim()
          : 'the store';

  bool get inStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 10;
  String? get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : null;

  @override
  List<Object?> get props => [id, sku, name, price, stockQuantity];
}

class ProductDimensions extends Equatable {
  final double length;
  final double width;
  final double height;
  final String unit;

  const ProductDimensions({
    required this.length,
    required this.width,
    required this.height,
    this.unit = 'cm',
  });

  @override
  List<Object?> get props => [length, width, height, unit];
}

class ShippingInfo extends Equatable {
  final bool freeShipping;
  final double? shippingWeight;
  final int estimatedDeliveryDays;
  final bool isFragile;

  const ShippingInfo({
    this.freeShipping = false,
    this.shippingWeight,
    this.estimatedDeliveryDays = 5,
    this.isFragile = false,
  });

  @override
  List<Object?> get props => [freeShipping, estimatedDeliveryDays];
}
