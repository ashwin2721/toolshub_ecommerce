import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

class CartItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final String sku;
  final double price;
  final double? discountPrice;
  final int quantity;
  final int maxQuantity;
  final bool savedForLater;
  final Map<String, dynamic>? bulkPricing;

  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.sku,
    required this.price,
    this.discountPrice,
    required this.quantity,
    this.maxQuantity = 10,
    this.savedForLater = false,
    this.bulkPricing,
  });

  double get bulkDiscountPercent {
    if (bulkPricing == null || bulkPricing!.isEmpty) return 0.0;
    double maxDiscount = 0.0;
    bulkPricing!.forEach((key, val) {
      final threshold = int.tryParse(key) ?? 0;
      if (quantity >= threshold) {
        final discount = (val as num).toDouble();
        if (discount > maxDiscount) {
          maxDiscount = discount;
        }
      }
    });
    return maxDiscount;
  }

  double get unitPriceBeforeBulk => discountPrice ?? price;
  double get effectivePrice => unitPriceBeforeBulk * (1.0 - bulkDiscountPercent);
  double get totalPrice => effectivePrice * quantity;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  bool get hasBulkDiscount => bulkDiscountPercent > 0.0;

  CartItemEntity copyWith({
    int? quantity,
    bool? savedForLater,
    Map<String, dynamic>? bulkPricing,
  }) =>
      CartItemEntity(
        id: id,
        productId: productId,
        productName: productName,
        productImage: productImage,
        sku: sku,
        price: price,
        discountPrice: discountPrice,
        quantity: quantity ?? this.quantity,
        maxQuantity: maxQuantity,
        savedForLater: savedForLater ?? this.savedForLater,
        bulkPricing: bulkPricing ?? this.bulkPricing,
      );

  @override
  List<Object?> get props => [id, productId, quantity, savedForLater, bulkPricing];
}

class CartEntity extends Equatable {
  final String userId;
  final List<CartItemEntity> activeItems;
  final List<CartItemEntity> savedItems;
  final String? couponCode;
  final double? couponDiscount;
  final String? couponType; // percentage, fixed, free_shipping

  const CartEntity({
    required this.userId,
    this.activeItems = const [],
    this.savedItems = const [],
    this.couponCode,
    this.couponDiscount,
    this.couponType,
  });

  double get subtotal =>
      activeItems.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => activeItems.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => activeItems.isEmpty;
  bool get hasCoupon => couponCode != null;

  double get totalBulkDiscountSaved =>
      activeItems.fold(0.0, (sum, item) {
        final basePrice = item.discountPrice ?? item.price;
        final savedPerItem = basePrice - item.effectivePrice;
        return sum + (savedPerItem * item.quantity);
      });

  double get discountAmount {
    if (couponCode == null || couponDiscount == null) return 0;
    final double raw = couponType == 'percentage'
        ? subtotal * (couponDiscount! / 100)
        : couponDiscount!;
    if (raw < 0) return 0;
    return raw > subtotal ? subtotal : raw;
  }

  double get shippingFee {
    if (couponType == 'free_shipping') return 0;
    return subtotal >= AppConstants.freeShippingThreshold
        ? 0
        : AppConstants.standardShippingFee;
  }

  double get gstAmount => (subtotal - discountAmount) * 0.18;
  double get total => subtotal - discountAmount + shippingFee + gstAmount;

  @override
  List<Object?> get props => [userId, activeItems, couponCode];
}
