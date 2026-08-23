import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/store_chrome.dart';
import '../../../core/responsive.dart';
import '../../../core/theme/app_colors.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? brandId;
  final String? query;
  final bool deals;

  const ProductListScreen(
      {super.key,
      this.categoryId,
      this.brandId,
      this.query,
      this.deals = false});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  bool _gridView = true;
  SortBy _sortBy = SortBy.latest;
  double? _minPrice;
  double? _maxPrice;

  ProductFilter get _filter => ProductFilter(
        categoryId: widget.categoryId,
        brandId: widget.brandId,
        isFlashSale: widget.deals ? true : null,
        sortBy: _sortBy,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FilterSheet(
        currentSort: _sortBy,
        onApply: (sort, min, max) {
          setState(() {
            _sortBy = sort;
            _minPrice = min;
            _maxPrice = max;
          });
        },
      ),
    );
  }

  String _prettyTitle() {
    if (widget.deals) return 'Hot Deals';
    if (widget.query != null && widget.query!.isNotEmpty) {
      return 'Results for "${widget.query}"';
    }
    if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
      return widget.categoryId!
          .split('_')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    return 'All Products';
  }

  Widget _controlButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: label.isEmpty ? 11 : 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<dynamic> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.productGridColumns,
        crossAxisSpacing: 20,
        mainAxisSpacing: 24,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (_, i) => products[i] == null
          ? const _ShimmerCard()
          : ProductCard(product: products[i], gridView: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(_filter));

    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_prettyTitle(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          )),
                ),
                _controlButton(
                    _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    '',
                    () => setState(() => _gridView = !_gridView)),
                const SizedBox(width: 10),
                _controlButton(Icons.tune_rounded, 'Filters', _showFilterSheet),
              ],
            ),
            const SizedBox(height: 20),
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: EmptyStateWidget(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Products Found',
                      subtitle: 'Try adjusting your filters or search terms',
                    ),
                  );
                }
                return _gridView
                    ? _buildGrid(context, products)
                    : Column(
                        children: [
                          for (final p in products) ProductCard(product: p),
                        ],
                      );
              },
              loading: () => _buildGrid(
                  context, List<dynamic>.filled(context.productGridColumns * 2, null)),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(child: Text('Something went wrong: $e')),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final SortBy currentSort;
  final void Function(SortBy, double?, double?) onApply;

  const _FilterSheet({required this.currentSort, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SortBy _sort;
  RangeValues _priceRange = const RangeValues(0, 50000);

  @override
  void initState() {
    super.initState();
    _sort = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters & Sort',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close')),
              ],
            ),
            const Divider(),
            Text('Sort By', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SortBy.values.map((s) {
                return ChoiceChip(
                  label: Text(_sortLabel(s)),
                  selected: _sort == s,
                  onSelected: (_) => setState(() => _sort = s),
                  selectedColor: AppColors.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Price Range: ₹${_priceRange.start.toStringAsFixed(0)} – ₹${_priceRange.end.toStringAsFixed(0)}',
                style: theme.textTheme.titleSmall),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 50000,
              divisions: 100,
              onChanged: (v) => setState(() => _priceRange = v),
              activeColor: AppColors.primary,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _sort = SortBy.latest;
                        _priceRange = const RangeValues(0, 50000);
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_sort,
                          _priceRange.start > 0 ? _priceRange.start : null,
                          _priceRange.end < 50000 ? _priceRange.end : null);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(SortBy s) {
    switch (s) {
      case SortBy.latest: return 'Latest';
      case SortBy.popular: return 'Popular';
      case SortBy.priceLowToHigh: return 'Price ↑';
      case SortBy.priceHighToLow: return 'Price ↓';
      case SortBy.bestRated: return 'Top Rated';
    }
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.shimmerBase;
    const highlightColor = AppColors.shimmerHighlight;

    // Grid Card Skeleton
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Expanded(
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
            ),
          ),
          // Info skeleton
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    height: 10,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        height: 16,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
