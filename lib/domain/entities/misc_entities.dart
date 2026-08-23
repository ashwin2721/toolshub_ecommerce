import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final double rating;
  final String title;
  final String body;
  final List<String> images;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    required this.title,
    required this.body,
    this.images = const [],
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, productId, userId, rating];
}

class CouponEntity extends Equatable {
  final String id;
  final String code;
  final String type; // percentage, fixed, free_shipping, bogo
  final double value;
  final double? minOrderValue;
  final double? maxDiscount;
  final int? usageLimit;
  final int usedCount;
  final bool isActive;
  final DateTime? expiresAt;
  final String? description;
  final List<String>? applicableCategories;
  final List<String>? applicableProducts;

  const CouponEntity({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderValue,
    this.maxDiscount,
    this.usageLimit,
    this.usedCount = 0,
    this.isActive = true,
    this.expiresAt,
    this.description,
    this.applicableCategories,
    this.applicableProducts,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isUsageLimitReached =>
      usageLimit != null && usedCount >= usageLimit!;
  bool get isValid => isActive && !isExpired && !isUsageLimitReached;

  double calculateDiscount(double orderAmount) {
    if (!isValid) return 0;
    if (minOrderValue != null && orderAmount < minOrderValue!) return 0;
    if (type == 'free_shipping') return 99;
    double discount = type == 'percentage'
        ? orderAmount * (value / 100)
        : value;
    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }
    return discount;
  }

  @override
  List<Object?> get props => [id, code, type, value, isActive];
}

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // order, promotion, system
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, isRead];
}

class BannerEntity extends Equatable {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? actionUrl;
  final String actionType; // product, category, url
  final bool isActive;
  final int sortOrder;

  const BannerEntity({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.actionUrl,
    this.actionType = 'url',
    this.isActive = true,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, isActive, sortOrder];
}

class SupportTicketEntity extends Equatable {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final String status; // open, in_progress, resolved, closed
  final String priority; // low, medium, high
  final String? orderId;
  final List<TicketMessage> messages;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const SupportTicketEntity({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.orderId,
    this.messages = const [],
    required this.createdAt,
    this.resolvedAt,
  });

  @override
  List<Object?> get props => [id, status];
}

class TicketMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final bool isAdmin;
  final String message;
  final DateTime createdAt;

  const TicketMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.isAdmin,
    required this.message,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, createdAt];
}
