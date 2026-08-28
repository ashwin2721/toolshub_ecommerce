import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/product_provider.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/common/store_chrome.dart';
import '../../widgets/product/product_card.dart';

/// Client-side storefront filters applied to the fetched product list.
class HomeFilters {
  final String categoryId; // '' = all
  final String brand; // '' = all
  final double minRating; // 0 = all
  final double maxPrice; // 0 = all (cap on effective price)
  final String material; // '' = all (keyword match)
  final bool offerOnly; // only discounted items
  const HomeFilters({
    this.categoryId = '',
    this.brand = '',
    this.minRating = 0,
    this.maxPrice = 0,
    this.material = '',
    this.offerOnly = false,
  });
  HomeFilters copyWith({
    String? categoryId,
    String? brand,
    double? minRating,
    double? maxPrice,
    String? material,
    bool? offerOnly,
  }) =>
      HomeFilters(
        categoryId: categoryId ?? this.categoryId,
        brand: brand ?? this.brand,
        minRating: minRating ?? this.minRating,
        maxPrice: maxPrice ?? this.maxPrice,
        material: material ?? this.material,
        offerOnly: offerOnly ?? this.offerOnly,
      );
  bool get isActive =>
      categoryId.isNotEmpty ||
      brand.isNotEmpty ||
      minRating > 0 ||
      maxPrice > 0 ||
      material.isNotEmpty ||
      offerOnly;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _pageSize = 8;

  SortBy _sort = SortBy.latest;
  int _page = 0;
  HomeFilters _filters = const HomeFilters();

  // Client-side filtering on the fetched product list.
  List<ProductEntity> _applyFilters(List<ProductEntity> list) {
    return list.where((p) {
      if (_filters.categoryId.isNotEmpty && p.categoryId != _filters.categoryId) {
        return false;
      }
      if (_filters.brand.isNotEmpty && p.brandName != _filters.brand) {
        return false;
      }
      if (_filters.minRating > 0 && p.rating < _filters.minRating) return false;
      if (_filters.maxPrice > 0 && p.effectivePrice > _filters.maxPrice) {
        return false;
      }
      if (_filters.offerOnly &&
          !(p.discountPrice != null &&
              p.discountPrice! > 0 &&
              p.discountPrice! < p.price)) {
        return false;
      }
      if (_filters.material.isNotEmpty) {
        final hay =
            '${p.name} ${p.description} ${p.specifications ?? ''}'.toLowerCase();
        if (!hay.contains(_filters.material.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  // Client-side sort so it works regardless of what the backend returns.
  List<ProductEntity> _sortProducts(List<ProductEntity> products) {
    final list = [...products];
    switch (_sort) {
      case SortBy.latest:
        break; // keep server order (createdAt desc already)
      case SortBy.priceLowToHigh:
        list.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case SortBy.priceHighToLow:
        list.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case SortBy.bestRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortBy.popular:
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync =
        ref.watch(productsProvider(const ProductFilter(limit: 60)));

    return StorePage(
      showFooter: true,
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StoreHero(),
            const SizedBox(height: 28),
            _FilterBar(
              sort: _sort,
              onSortChanged: (value) => setState(() {
                _sort = value;
                _page = 0;
              }),
              filters: _filters,
              onFiltersChanged: (f) => setState(() {
                _filters = f;
                _page = 0;
              }),
            ),
            const SizedBox(height: 26),
            Text('Tools For You!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
            const SizedBox(height: 18),
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) return const _EmptyGrid();
                final filtered = _applyFilters(products);
                if (filtered.isEmpty) {
                  return _NoMatches(
                    onClear: () => setState(() {
                      _filters = const HomeFilters();
                      _page = 0;
                    }),
                  );
                }
                final sorted = _sortProducts(filtered);
                final totalPages = (sorted.length / _pageSize).ceil();
                final page = _page.clamp(0, totalPages - 1).toInt();
                final pageItems =
                    sorted.skip(page * _pageSize).take(_pageSize).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductGrid(products: pageItems),
                    const SizedBox(height: 28),
                    Center(
                      child: _Pagination(
                        currentPage: page,
                        totalPages: totalPages,
                        onChanged: (next) => setState(() => _page = next),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const _GridShimmer(),
              error: (_, __) => const _EmptyGrid(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Hero banner (cream) ──────────────────────────────────────────────────────
class _StoreHero extends ConsumerWidget {
  const _StoreHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = context.isMobile;
    final settings =
        ref.watch(storeSettingsProvider).valueOrNull ?? const <String, dynamic>{};
    final rawTitle = (settings['heroTitle'] as String?)?.trim() ?? '';
    final title = rawTitle.isNotEmpty
        ? rawTitle
        : 'Grab Upto 50% Off On Selected Power Tools';
    final subtitle = (settings['heroSubtitle'] as String?)?.trim() ?? '';
    final rawCta = (settings['heroCtaLabel'] as String?)?.trim() ?? '';
    final ctaLabel = rawCta.isNotEmpty ? rawCta : 'Buy Now';
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                height: 1.2,
                fontSize: mobile ? 24 : 34,
              ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: mobile ? 13 : 15)),
        ],
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.productList),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(ctaLabel,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );

    final art = Center(
      child: Icon(Icons.construction_rounded,
          size: mobile ? 88 : 150,
          color: AppColors.primary.withValues(alpha: 0.85)),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.heroBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: mobile ? 24 : 48, vertical: mobile ? 28 : 36),
      child: mobile
          ? Column(children: [art, const SizedBox(height: 16), text])
          : Row(
              children: [
                Expanded(flex: 3, child: text),
                Expanded(flex: 2, child: art),
              ],
            ),
    );
  }
}

// ── Filter pill bar + sort ───────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  final SortBy sort;
  final ValueChanged<SortBy> onSortChanged;
  final HomeFilters filters;
  final ValueChanged<HomeFilters> onFiltersChanged;
  const _FilterBar({
    required this.sort,
    required this.onSortChanged,
    required this.filters,
    required this.onFiltersChanged,
  });

  static const _materials = [
    'Steel',
    'Carbide',
    'Aluminium',
    'Plastic',
    'Rubber',
    'Lithium',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final products =
        ref.watch(productsProvider(const ProductFilter(limit: 60))).valueOrNull ??
            const <ProductEntity>[];
    final brands = <String>{
      for (final p in products)
        if (p.brandName.isNotEmpty) p.brandName
    }.toList()
      ..sort();

    final toolTypeOptions = <(String, String)>[
      ('All Tools', ''),
      for (final c in categories) (c.name, c.id),
    ];
    final brandOptions = <(String, String)>[
      ('All Brands', ''),
      for (final b in brands) (b, b),
    ];
    final materialOptions = <(String, String)>[
      ('All Materials', ''),
      for (final m in _materials) (m, m),
    ];
    const priceOptions = <(String, double)>[
      ('Any Price', 0),
      ('Under ₹1,000', 1000),
      ('Under ₹5,000', 5000),
      ('Under ₹10,000', 10000),
      ('Under ₹20,000', 20000),
    ];
    const reviewOptions = <(String, double)>[
      ('Any Rating', 0),
      ('4★ & up', 4),
      ('3★ & up', 3),
      ('2★ & up', 2),
    ];
    const offerOptions = <(String, bool)>[
      ('All Items', false),
      ('On Offer', true),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MenuPill<String>(
                base: 'Tool Type',
                selected: filters.categoryId,
                options: toolTypeOptions,
                onSelected: (v) => onFiltersChanged(filters.copyWith(categoryId: v)),
              ),
              _MenuPill<double>(
                base: 'Price',
                selected: filters.maxPrice,
                options: priceOptions,
                onSelected: (v) => onFiltersChanged(filters.copyWith(maxPrice: v)),
              ),
              _MenuPill<double>(
                base: 'Review',
                selected: filters.minRating,
                options: reviewOptions,
                onSelected: (v) => onFiltersChanged(filters.copyWith(minRating: v)),
              ),
              _MenuPill<String>(
                base: 'Brand',
                selected: filters.brand,
                options: brandOptions,
                onSelected: (v) => onFiltersChanged(filters.copyWith(brand: v)),
              ),
              _MenuPill<String>(
                base: 'Material',
                selected: filters.material,
                options: materialOptions,
                onSelected: (v) => onFiltersChanged(filters.copyWith(material: v)),
              ),
              _MenuPill<bool>(
                base: 'Offer',
                selected: filters.offerOnly,
                options: offerOptions,
                onSelected: (v) => onFiltersChanged(filters.copyWith(offerOnly: v)),
              ),
              if (filters.isActive)
                _ClearFiltersPill(
                    onTap: () => onFiltersChanged(const HomeFilters())),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _SortByPill(sort: sort, onSortChanged: onSortChanged),
      ],
    );
  }
}

String _sortLabel(SortBy s) {
  switch (s) {
    case SortBy.latest:
      return 'Latest';
    case SortBy.popular:
      return 'Popular';
    case SortBy.priceLowToHigh:
      return 'Price: Low to High';
    case SortBy.priceHighToLow:
      return 'Price: High to Low';
    case SortBy.bestRated:
      return 'Best Rated';
  }
}

// Functional "Sort by" control — styled like the decorative pills.
class _SortByPill extends StatelessWidget {
  final SortBy sort;
  final ValueChanged<SortBy> onSortChanged;
  const _SortByPill({required this.sort, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortBy>(
      tooltip: 'Sort by',
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        for (final option in SortBy.values)
          PopupMenuItem<SortBy>(
            value: option,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  child: option == sort
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.primary)
                      : null,
                ),
                Text(
                  _sortLabel(option),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight:
                        option == sort ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sort by',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// A functional filter pill backed by a dropdown menu. The first option is
// treated as the "default/all" value; selecting anything else highlights it.
class _MenuPill<T extends Object> extends StatelessWidget {
  final String base;
  final T selected;
  final List<(String, T)> options;
  final ValueChanged<T> onSelected;
  const _MenuPill({
    required this.base,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected != options.first.$2;
    String label = base;
    if (active) {
      final match = options.where((o) => o.$2 == selected);
      if (match.isNotEmpty) label = match.first.$1;
    }
    return PopupMenuButton<T>(
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final (text, val) in options)
          PopupMenuItem<T>(
            value: val,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  child: val == selected
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.primary)
                      : null,
                ),
                Text(text,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight:
                            val == selected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: active ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: active ? Colors.white : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ClearFiltersPill extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearFiltersPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 16, color: AppColors.error),
            SizedBox(width: 4),
            Text('Clear',
                style: TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// Shown when active filters match no products.
class _NoMatches extends StatelessWidget {
  final VoidCallback onClear;
  const _NoMatches({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text('No products match your filters',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}

// ── Responsive product grid ──────────────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  final List<dynamic> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    final columns = context.productGridColumns;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 20,
        mainAxisSpacing: 24,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, i) =>
          ProductCard(product: products[i], gridView: true),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onChanged;
  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget dot({
      String? label,
      IconData? icon,
      bool active = false,
      bool enabled = true,
      VoidCallback? onTap,
    }) {
      final content = Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon,
                size: 20,
                color:
                    enabled ? AppColors.textPrimary : AppColors.textTertiary)
            : Text(label ?? '',
                style: TextStyle(
                    color: active ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700)),
      );
      if (!enabled || onTap == null) {
        return Opacity(opacity: enabled ? 1 : 0.45, child: content);
      }
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    // Windowed page numbers — at most 5 visible around the current page.
    const maxVisible = 5;
    int start = currentPage - maxVisible ~/ 2;
    int end = start + maxVisible - 1;
    if (start < 0) {
      end -= start;
      start = 0;
    }
    if (end > totalPages - 1) {
      end = totalPages - 1;
      start = end - maxVisible + 1;
      if (start < 0) start = 0;
    }

    final hasPrev = currentPage > 0;
    final hasNext = currentPage < totalPages - 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(
          icon: Icons.chevron_left_rounded,
          enabled: hasPrev,
          onTap: hasPrev ? () => onChanged(currentPage - 1) : null,
        ),
        for (int p = start; p <= end; p++)
          dot(
            label: '${p + 1}',
            active: p == currentPage,
            onTap: () => onChanged(p),
          ),
        dot(
          icon: Icons.chevron_right_rounded,
          enabled: hasNext,
          onTap: hasNext ? () => onChanged(currentPage + 1) : null,
        ),
      ],
    );
  }
}

// ── Placeholders ─────────────────────────────────────────────────────────────
class _GridShimmer extends StatelessWidget {
  const _GridShimmer();

  @override
  Widget build(BuildContext context) {
    final columns = context.productGridColumns;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: columns * 2,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 20,
        mainAxisSpacing: 24,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptyGrid extends StatelessWidget {
  const _EmptyGrid();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 48, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text('No products to show yet',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
