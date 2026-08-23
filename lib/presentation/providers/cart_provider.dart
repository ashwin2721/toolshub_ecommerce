import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/product_entity.dart';
import 'auth_provider.dart';

class CartNotifier extends StateNotifier<CartEntity> {
  CartNotifier(this._userId) : super(CartEntity(userId: _userId ?? '')) {
    _load();
  }

  final String? _userId;
  static const _uuid = Uuid();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userCart = _readCart(prefs, _userId ?? 'guest');
    if (userCart != null) {
      state = userCart;
    }

    // Migrate/merge any guest cart into the logged-in user's cart so items
    // added before login are not orphaned under the 'guest' key.
    if (_userId != null) {
      final guestCart = _readCart(prefs, 'guest');
      if (guestCart != null &&
          (guestCart.activeItems.isNotEmpty ||
              guestCart.savedItems.isNotEmpty)) {
        state = _mergeCarts(state, guestCart);
        await prefs.remove('cart_data_guest');
        await _sync();
      }
    }
  }

  CartEntity? _readCart(SharedPreferences prefs, String keySuffix) {
    final jsonStr = prefs.getString('cart_data_$keySuffix');
    if (jsonStr == null) return null;
    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final activeItems = (data['activeItems'] as List<dynamic>?)
              ?.map((i) => _itemFromMap(Map<String, dynamic>.from(i)))
              .toList() ??
          [];
      final savedItems = (data['savedItems'] as List<dynamic>?)
              ?.map((i) => _itemFromMap(Map<String, dynamic>.from(i)))
              .toList() ??
          [];
      return CartEntity(
        userId: _userId ?? '',
        activeItems: activeItems,
        savedItems: savedItems,
        couponCode: data['couponCode'],
        couponDiscount: (data['couponDiscount'] as num?)?.toDouble(),
        couponType: data['couponType'],
      );
    } catch (_) {
      return null;
    }
  }

  CartEntity _mergeCarts(CartEntity base, CartEntity incoming) {
    final mergedActive = List<CartItemEntity>.from(base.activeItems);
    for (final guestItem in incoming.activeItems) {
      final idx =
          mergedActive.indexWhere((i) => i.productId == guestItem.productId);
      if (idx >= 0) {
        final existing = mergedActive[idx];
        final newQty = (existing.quantity + guestItem.quantity)
            .clamp(1, existing.maxQuantity);
        mergedActive[idx] = existing.copyWith(quantity: newQty);
      } else {
        mergedActive.add(guestItem);
      }
    }

    final mergedSaved = List<CartItemEntity>.from(base.savedItems);
    for (final guestItem in incoming.savedItems) {
      final alreadyPresent = mergedActive
              .any((i) => i.productId == guestItem.productId) ||
          mergedSaved.any((i) => i.productId == guestItem.productId);
      if (!alreadyPresent) {
        mergedSaved.add(guestItem);
      }
    }

    return CartEntity(
      userId: base.userId,
      activeItems: mergedActive,
      savedItems: mergedSaved,
      couponCode: base.couponCode ?? incoming.couponCode,
      couponDiscount: base.couponDiscount ?? incoming.couponDiscount,
      couponType: base.couponType ?? incoming.couponType,
    );
  }

  Future<void> addItem(ProductEntity product, {int quantity = 1}) async {
    // Cap to the lesser of the cart limit and what's actually in stock so we
    // never hold quantities that cannot be fulfilled at checkout.
    final maxAllowed = product.stockQuantity < AppConstants.maxCartQuantity
        ? product.stockQuantity
        : AppConstants.maxCartQuantity;
    if (maxAllowed < 1) return; // out of stock: nothing can be added
    final existing = state.activeItems
        .indexWhere((item) => item.productId == product.id);
    List<CartItemEntity> updated = List.from(state.activeItems);
    if (existing >= 0) {
      final item = updated[existing];
      final newQty = (item.quantity + quantity).clamp(1, maxAllowed);
      updated[existing] = item.copyWith(quantity: newQty);
    } else {
      updated.add(CartItemEntity(
        id: _uuid.v4(),
        productId: product.id,
        productName: product.name,
        productImage: product.primaryImage,
        sku: product.sku,
        price: product.price,
        discountPrice: product.discountPrice,
        quantity: quantity.clamp(1, maxAllowed),
        maxQuantity: maxAllowed,
        bulkPricing: product.bulkPricing,
      ));
    }
    state = CartEntity(
      userId: state.userId,
      activeItems: updated,
      savedItems: state.savedItems,
      couponCode: state.couponCode,
      couponDiscount: state.couponDiscount,
      couponType: state.couponType,
    );
    await _sync();
  }

  Future<void> removeItem(String itemId) async {
    state = CartEntity(
      userId: state.userId,
      activeItems: state.activeItems.where((i) => i.id != itemId).toList(),
      savedItems: state.savedItems,
      couponCode: state.couponCode,
      couponDiscount: state.couponDiscount,
      couponType: state.couponType,
    );
    await _sync();
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity < 1) {
      await removeItem(itemId);
      return;
    }
    final updated = state.activeItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity.clamp(1, item.maxQuantity));
      }
      return item;
    }).toList();
    state = CartEntity(
      userId: state.userId,
      activeItems: updated,
      savedItems: state.savedItems,
      couponCode: state.couponCode,
      couponDiscount: state.couponDiscount,
      couponType: state.couponType,
    );
    await _sync();
  }

  Future<void> saveForLater(String itemId) async {
    final item = state.activeItems.firstWhere((i) => i.id == itemId);
    state = CartEntity(
      userId: state.userId,
      activeItems: state.activeItems.where((i) => i.id != itemId).toList(),
      savedItems: [...state.savedItems, item.copyWith(savedForLater: true)],
      couponCode: state.couponCode,
      couponDiscount: state.couponDiscount,
      couponType: state.couponType,
    );
    await _sync();
  }

  Future<void> moveToCart(String itemId) async {
    final item = state.savedItems.firstWhere((i) => i.id == itemId);
    state = CartEntity(
      userId: state.userId,
      activeItems: [...state.activeItems, item.copyWith(savedForLater: false)],
      savedItems: state.savedItems.where((i) => i.id != itemId).toList(),
      couponCode: state.couponCode,
      couponDiscount: state.couponDiscount,
      couponType: state.couponType,
    );
    await _sync();
  }

  Future<bool> applyCoupon(String code) async {
    final normalizedCode = code.toUpperCase();
    double? discount;
    String? type;

    // Hardcode popular dev coupons
    if (normalizedCode == 'WELCOME10') {
      discount = 10.0;
      type = 'percentage';
    } else if (normalizedCode == 'SAVE200') {
      discount = 200.0;
      type = 'fixed';
    } else {
      return false;
    }

    state = CartEntity(
      userId: state.userId,
      activeItems: state.activeItems,
      savedItems: state.savedItems,
      couponCode: normalizedCode,
      couponDiscount: discount,
      couponType: type,
    );
    await _sync();
    return true;
  }

  Future<void> removeCoupon() async {
    state = CartEntity(
      userId: state.userId,
      activeItems: state.activeItems,
      savedItems: state.savedItems,
    );
    await _sync();
  }

  Future<void> clearCart() async {
    state = CartEntity(userId: state.userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_data_${_userId ?? "guest"}');
  }

  Future<void> _sync() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'userId': _userId ?? '',
      'activeItems': state.activeItems.map(_itemToMap).toList(),
      'savedItems': state.savedItems.map(_itemToMap).toList(),
      'couponCode': state.couponCode,
      'couponDiscount': state.couponDiscount,
      'couponType': state.couponType,
    };
    await prefs.setString('cart_data_${_userId ?? "guest"}', json.encode(data));
  }

  Map<String, dynamic> _itemToMap(CartItemEntity item) => {
        'id': item.id,
        'productId': item.productId,
        'productName': item.productName,
        'productImage': item.productImage,
        'sku': item.sku,
        'price': item.price,
        'discountPrice': item.discountPrice,
        'quantity': item.quantity,
        'maxQuantity': item.maxQuantity,
        'savedForLater': item.savedForLater,
        'bulkPricing': item.bulkPricing,
      };

  CartItemEntity _itemFromMap(Map<String, dynamic> data) => CartItemEntity(
        id: data['id'] ?? _uuid.v4(),
        productId: data['productId'] ?? '',
        productName: data['productName'] ?? '',
        productImage: data['productImage'],
        sku: data['sku'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        discountPrice: (data['discountPrice'] as num?)?.toDouble(),
        quantity: (data['quantity'] as num?)?.toInt() ?? 1,
        maxQuantity:
            (data['maxQuantity'] as num?)?.toInt() ?? AppConstants.maxCartQuantity,
        savedForLater: data['savedForLater'] ?? false,
        bulkPricing: data['bulkPricing'] as Map<String, dynamic>?,
      );
}

final cartProvider = StateNotifierProvider<CartNotifier, CartEntity>((ref) {
  final userId = ref.watch(currentUserProvider).valueOrNull?.id;
  return CartNotifier(userId);
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItems;
});
