import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.sku,
    super.barcode,
    required super.name,
    required super.slug,
    required super.description,
    super.specifications,
    super.features,
    required super.brandId,
    required super.brandName,
    required super.categoryId,
    required super.categoryName,
    super.subcategoryId,
    super.subcategoryName,
    super.imageUrls,
    super.videoUrls,
    required super.price,
    super.discountPrice,
    super.stockQuantity,
    super.warrantyInfo,
    super.weight,
    super.dimensions,
    super.shippingInfo,
    super.rating,
    super.reviewCount,
    super.isActive,
    super.isFeatured,
    super.isFlashSale,
    super.isNewArrival,
    super.isBestSeller,
    required super.createdAt,
    super.updatedAt,
    super.attributes,
    super.tags,
    super.compatibleProductIds,
    super.bulkPricing,
  });


  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      sku: data['sku'] ?? '',
      barcode: data['barcode'],
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      description: data['description'] ?? '',
      specifications: data['specifications'],
      features: data['features'] != null ? List<String>.from(data['features']) : [],
      brandId: data['brandId'] ?? '',
      brandName: data['brandName'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      subcategoryId: data['subcategoryId'],
      subcategoryName: data['subcategoryName'],
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : [],
      videoUrls: data['videoUrls'] != null ? List<String>.from(data['videoUrls']) : [],
      price: (data['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (data['discountPrice'] as num?)?.toDouble(),
      stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
      warrantyInfo: data['warrantyInfo'],
      weight: (data['weight'] as num?)?.toDouble(),
      dimensions: data['dimensions'] != null
          ? _dimensionsFromMap(data['dimensions'] as Map<String, dynamic>)
          : null,
      shippingInfo: data['shippingInfo'] != null
          ? _shippingFromMap(data['shippingInfo'] as Map<String, dynamic>)
          : null,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      isFlashSale: data['isFlashSale'] ?? false,
      isNewArrival: data['isNewArrival'] ?? false,
      isBestSeller: data['isBestSeller'] ?? false,
      createdAt: data['createdAt'] != null
          ? (DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString())
          : null,
      attributes: data['attributes'] as Map<String, dynamic>?,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      compatibleProductIds: data['compatibleProductIds'] != null
          ? List<String>.from(data['compatibleProductIds'])
          : null,
      bulkPricing: data['bulkPricing'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'sku': sku,
        'barcode': barcode,
        'name': name,
        'slug': slug,
        'description': description,
        'specifications': specifications,
        'features': features,
        'brandId': brandId,
        'brandName': brandName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'subcategoryId': subcategoryId,
        'subcategoryName': subcategoryName,
        'imageUrls': imageUrls,
        'videoUrls': videoUrls,
        'price': price,
        'discountPrice': discountPrice,
        'stockQuantity': stockQuantity,
        'warrantyInfo': warrantyInfo,
        'weight': weight,
        'dimensions': dimensions != null
            ? {
                'length': dimensions!.length,
                'width': dimensions!.width,
                'height': dimensions!.height,
                'unit': dimensions!.unit,
              }
            : null,
        'shippingInfo': shippingInfo != null
            ? {
                'freeShipping': shippingInfo!.freeShipping,
                'shippingWeight': shippingInfo!.shippingWeight,
                'estimatedDeliveryDays': shippingInfo!.estimatedDeliveryDays,
                'isFragile': shippingInfo!.isFragile,
              }
            : null,
        'rating': rating,
        'reviewCount': reviewCount,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'isFlashSale': isFlashSale,
        'isNewArrival': isNewArrival,
        'isBestSeller': isBestSeller,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'attributes': attributes,
        'tags': tags,
        'compatibleProductIds': compatibleProductIds,
        'bulkPricing': bulkPricing,

        // For search indexing
        'nameLower': name.toLowerCase(),
        'searchKeywords': _buildSearchKeywords(name, brandName, categoryName),
      };

  static ProductDimensions _dimensionsFromMap(Map<String, dynamic> data) =>
      ProductDimensions(
        length: (data['length'] as num?)?.toDouble() ?? 0,
        width: (data['width'] as num?)?.toDouble() ?? 0,
        height: (data['height'] as num?)?.toDouble() ?? 0,
        unit: data['unit'] ?? 'cm',
      );

  static ShippingInfo _shippingFromMap(Map<String, dynamic> data) =>
      ShippingInfo(
        freeShipping: data['freeShipping'] ?? false,
        shippingWeight: (data['shippingWeight'] as num?)?.toDouble(),
        estimatedDeliveryDays: (data['estimatedDeliveryDays'] as num?)?.toInt() ?? 5,
        isFragile: data['isFragile'] ?? false,
      );

  static List<String> _buildSearchKeywords(String name, String brand, String category) {
    final words = <String>{};
    final parts = '$name $brand $category'.toLowerCase().split(RegExp(r'\s+'));
    for (final word in parts) {
      for (int i = 1; i <= word.length; i++) {
        words.add(word.substring(0, i));
      }
    }
    return words.toList();
  }
}
