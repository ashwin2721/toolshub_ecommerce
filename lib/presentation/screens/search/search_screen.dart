import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';
import '../../providers/app_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/fuzzy_search_helper.dart';
import '../../widgets/common/store_chrome.dart';
import '../../widgets/product/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  static const _popular = [
    'Drill Machine',
    'Hammer',
    'Safety Gloves',
    'Wrench Set',
    'Level Tool',
    'Pliers',
    'Angle Grinder',
    'Tape Measure',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initial = widget.initialQuery?.trim() ?? '';
      if (initial.isNotEmpty) {
        _searchCtrl.text = initial;
        _onSearch(initial);
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _query = value.trim());
    if (value.trim().isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = ref.watch(searchHistoryProvider);
    final correctedQuery =
        _query.isNotEmpty ? FuzzySearchHelper.getCorrection(_query) : null;
    final effectiveQuery = correctedQuery ?? _query;
    final resultsAsync = _query.isNotEmpty
        ? ref.watch(searchResultsProvider(effectiveQuery))
        : null;

    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      // Search live as the user types; save to history on submit.
                      onChanged: (v) => setState(() => _query = v.trim()),
                      onSubmitted: _onSearch,
                      decoration: const InputDecoration(
                        hintText: 'Search tools, brands, categories...',
                        filled: false,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_query.isNotEmpty && correctedQuery != null)
              _correctionBanner(theme, correctedQuery),

            if (_query.isEmpty)
              _suggestions(theme, history)
            else
              resultsAsync!.when(
                data: (products) => products.isEmpty
                    ? _noResults(theme, effectiveQuery)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${products.length} results for "$effectiveQuery"',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          _resultsGrid(context, products),
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
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

  Widget _correctionBanner(ThemeData theme, String corrected) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.textPrimary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
                children: [
                  const TextSpan(text: 'Showing results for '),
                  TextSpan(
                      text: corrected,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const TextSpan(text: ' instead of '),
                  TextSpan(
                      text: _query,
                      style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestions(ThemeData theme, List<String> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () =>
                    ref.read(searchHistoryProvider.notifier).clear(),
                child: const Text('Clear All',
                    style: TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final q in history)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded,
                  color: AppColors.textSecondary),
              title: Text(q),
              trailing: const Icon(Icons.north_west_rounded,
                  size: 16, color: AppColors.textTertiary),
              onTap: () {
                _searchCtrl.text = q;
                _onSearch(q);
              },
            ),
          const SizedBox(height: 20),
        ],
        Text('Popular Searches',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in _popular)
              ActionChip(
                label: Text(s),
                avatar: const Icon(Icons.search, size: 14),
                onPressed: () {
                  _searchCtrl.text = s;
                  _onSearch(s);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _resultsGrid(BuildContext context, List<dynamic> products) {
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
      itemBuilder: (_, i) => ProductCard(product: products[i], gridView: true),
    );
  }

  Widget _noResults(ThemeData theme, String query) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('No results for "$query"', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Try different keywords',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
