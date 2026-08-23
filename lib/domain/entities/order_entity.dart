import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final String userId;
  final String? userName;
  final String? userEmail;
  final List<OrderItemEntity> items;
  final AddressEntity shippingAddress;
  final String paymentMethod;
  final String? paymentId;
  final String? transactionId;
  final OrderStatus status;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double gst;
  final double total;
  final String? couponCode;
  final double? couponDiscount;
  final String deliveryMethod;
  final String? trackingNumber;
  final String? trackingUrl;
  final String? notes;
  final List<OrderStatusUpdate> statusHistory;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expectedDelivery;
  final DateTime? deliveredAt;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    this.paymentId,
    this.transactionId,
    required this.status,
    required this.subtotal,
    this.discount = 0,
    this.shippingFee = 0,
    this.gst = 0,
    required this.total,
    this.couponCode,
    this.couponDiscount,
    required this.deliveryMethod,
    this.trackingNumber,
    this.trackingUrl,
    this.notes,
    this.statusHistory = const [],
    required this.createdAt,
    this.updatedAt,
    this.expectedDelivery,
    this.deliveredAt,
  });

  bool get isCancellable =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;
  bool get isReturnable => status == OrderStatus.delivered;
  bool get isTrackable =>
      status == OrderStatus.shipped || status == OrderStatus.packed;

  @override
  List<Object?> get props => [id, orderNumber, status];
}

class OrderItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final String sku;
  final int quantity;
  final double price;
  final double? discountPrice;
  final double total;

  const OrderItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.sku,
    required this.quantity,
    required this.price,
    this.discountPrice,
    required this.total,
  });

  double get effectivePrice => discountPrice ?? price;

  @override
  List<Object?> get props => [id, productId, quantity];
}

class OrderStatusUpdate extends Equatable {
  final OrderStatus status;
  final String? message;
  final DateTime timestamp;

  const OrderStatusUpdate({
    required this.status,
    this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [status, timestamp];
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  packed,
  shipped,
  delivered,
  cancelled,
  returned,
  refunded;

  String get label {
    switch (this) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.confirmed: return 'Confirmed';
      case OrderStatus.processing: return 'Processing';
      case OrderStatus.packed: return 'Packed';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
      case OrderStatus.returned: return 'Returned';
      case OrderStatus.refunded: return 'Refunded';
    }
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}
