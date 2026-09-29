import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/models/product_model.dart';
import 'auth_provider.dart';

// ─── Product List (REST API) ──────────────────────────────────────────────────
final productsProvider =
    FutureProvider.family<List<ProductEntity>, ProductFilter?>((ref, filter) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/products', queryParameters: {
    if (filter?.categoryId != null) 'category': filter!.categoryId,
    if (filter?.brandId != null) 'brand': filter!.brandId,
    if (filter?.minPrice != null) 'minPrice': filter!.minPrice,
    if (filter?.maxPrice != null) 'maxPrice': filter!.maxPrice,
    if (filter?.isFlashSale == true) 'isFlashSale': true,
    if (filter?.isFeatured == true) 'isFeatured': true,
    if (filter?.isNewArrival == true) 'isNewArrival': true,
    if (filter?.isBestSeller == true) 'isBestSeller': true,
    if (filter?.sortBy != null) 'sortBy': filter!.sortBy!.name,
    'limit': filter?.limit ?? 20,
  });

  if (response.data is! List) return [];
  final List<dynamic> data = response.data;
  return data.map((json) {
    final map = Map<String, dynamic>.from(json as Map);
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    return ProductModel.fromMap(map, id);
  }).toList();
});

// ─── Single Product Details ───────────────────────────────────────────────────
final productDetailProvider =
    FutureProvider.family<ProductEntity?, String>((ref, productId) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/products/$productId');
    if (response.data == null || response.data is! Map) return null;
    final map = Map<String, dynamic>.from(response.data as Map);
    final id = (map['id'] ?? map['_id'] ?? productId).toString();
    return ProductModel.fromMap(map, id);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

// ─── Search Results ───────────────────────────────────────────────────────────
final searchResultsProvider =
    FutureProvider.family<List<ProductEntity>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/products', queryParameters: {'q': query});
  if (response.data is! List) return [];
  final List<dynamic> data = response.data;
  return data.map((json) {
    final map = Map<String, dynamic>.from(json as Map);
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    return ProductModel.fromMap(map, id);
  }).toList();
});

// ─── Compatible Accessories ───────────────────────────────────────────────────
final compatibleProductsProvider =
    FutureProvider.family<List<ProductEntity>, List<String>>((ref, ids) async {
  if (ids.isEmpty) return [];
  final dio = ref.watch(dioProvider);
  final List<ProductEntity> result = [];
  for (final id in ids) {
    try {
      final response = await dio.get('/products/$id');
      result.add(ProductModel.fromMap(response.data, response.data['id']));
    } catch (_) {}
  }
  return result;
});

// ─── Categories ───────────────────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/categories');
  final List<dynamic> data = response.data;
  return data
      .map((json) => CategoryEntity(
            id: json['id'],
            name: json['name'] ?? '',
            slug: json['slug'] ?? '',
            description: json['description'],
            imageUrl: json['imageUrl'],
            productCount: (json['productCount'] as num?)?.toInt() ?? 0,
            isActive: json['isActive'] ?? true,
            sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
          ))
      .toList();
});

// ─── Banners ──────────────────────────────────────────────────────────────────
final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/banners');
  final List<dynamic> data = response.data;
  return data.map((json) => Map<String, dynamic>.from(json)).toList();
});

// ─── Storefront content settings (admin-editable promo/hero copy) ─────────────
final storeSettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/settings');
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return <String, dynamic>{};
  }
});

// ─── Delivery-fee settings (admin-managed, distance-based) ────────────────────
final deliverySettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/delivery-settings');
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return <String, dynamic>{};
  }
});

// ─── Product reviews ──────────────────────────────────────────────────────────
final productReviewsProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, productId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/products/$productId/reviews');
  return response.data as List<dynamic>;
});

// ─── Recently Viewed ──────────────────────────────────────────────────────────
class RecentlyViewedNotifier extends StateNotifier<List<String>> {
  RecentlyViewedNotifier() : super([]);

  void add(String productId) {
    if (state.contains(productId)) {
      state = [productId, ...state.where((id) => id != productId)];
    } else {
      state = [productId, ...state.take(19)];
    }
  }

  void clear() => state = [];
}

final recentlyViewedProvider =
    StateNotifierProvider<RecentlyViewedNotifier, List<String>>(
  (ref) => RecentlyViewedNotifier(),
);

final recentlyViewedProductsProvider =
    FutureProvider<List<ProductEntity>>((ref) async {
  final ids = ref.watch(recentlyViewedProvider);
  if (ids.isEmpty) return [];
  final dio = ref.watch(dioProvider);
  final List<ProductEntity> result = [];
  for (final id in ids.take(10)) {
    try {
      final response = await dio.get('/products/$id');
      result.add(ProductModel.fromMap(response.data, response.data['id']));
    } catch (_) {}
  }
  return result;
});

// ─── Wishlist (Local SharedPreferences Storage) ──────────────────────────────
class WishlistNotifier extends StateNotifier<Set<String>> {
  WishlistNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = Set<String>.from(prefs.getStringList('wishlist_items') ?? []);
  }

  Future<void> toggle(String productId) async {
    final newState = Set<String>.from(state);
    if (newState.contains(productId)) {
      newState.remove(productId);
    } else {
      newState.add(productId);
    }
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('wishlist_items', newState.toList());
  }

  bool contains(String productId) => state.contains(productId);
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, Set<String>>((ref) {
  return WishlistNotifier();
});

// ─── Filter/Sort Data Classes ─────────────────────────────────────────────────
class ProductFilter extends Equatable {
  final String? categoryId;
  final String? brandId;
  final double? minPrice;
  final double? maxPrice;
  final bool? isFlashSale;
  final bool? isFeatured;
  final bool? isNewArrival;
  final bool? isBestSeller;
  final SortBy? sortBy;
  final int limit;

  const ProductFilter({
    this.categoryId,
    this.brandId,
    this.minPrice,
    this.maxPrice,
    this.isFlashSale,
    this.isFeatured,
    this.isNewArrival,
    this.isBestSeller,
    this.sortBy,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [
        categoryId,
        brandId,
        minPrice,
        maxPrice,
        isFlashSale,
        isFeatured,
        isNewArrival,
        isBestSeller,
        sortBy,
        limit,
      ];
}

enum SortBy { latest, popular, priceLowToHigh, priceHighToLow, bestRated }
