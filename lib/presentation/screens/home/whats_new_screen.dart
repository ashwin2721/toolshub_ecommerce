import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/common/store_chrome.dart';
import '../../widgets/product/product_card.dart';

/// "What's New" — admin-managed promo banners (each links to a product/route)
/// plus the latest arrivals grid. Everything is tappable and flows into the
/// product detail page → add to cart → buy.
class WhatsNewScreen extends ConsumerWidget {
  const WhatsNewScreen({super.key});

  void _openBanner(BuildContext context, Map<String, dynamic> banner) {
    final action = (banner['actionUrl'] as String?)?.trim() ?? '';
    if (action.startsWith('/')) {
      context.go(action);
    } else {
      context.go(AppRoutes.productList);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);
    final newArrivalsAsync = ref.watch(
        productsProvider(const ProductFilter(isNewArrival: true, limit: 16)));

    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What's New",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
            const SizedBox(height: 6),
            Text(
                'Fresh arrivals and the latest featured drops — tap any banner or product to shop.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 22),

            // Admin-managed promo banners
            bannersAsync.when(
              data: (banners) {
                final active = banners
                    .where((b) => (b['isActive'] ?? true) == true)
                    .toList();
                if (active.isEmpty) return const SizedBox.shrink();
                return _BannerSection(
                    banners: active, onTap: (b) => _openBanner(context, b));
              },
              loading: () => const _BannerShimmer(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 30),
            Text('Latest Arrivals',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            newArrivalsAsync.when(
              data: (products) => products.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No new arrivals yet.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : _grid(context, products),
              loading: () => _grid(
                  context,
                  List<dynamic>.filled(context.productGridColumns * 2, null)),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('Something went wrong: $e'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, List<dynamic> products) {
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
          ? const _CardShimmer()
          : ProductCard(product: products[i], gridView: true),
    );
  }
}

class _BannerSection extends StatelessWidget {
  final List<Map<String, dynamic>> banners;
  final void Function(Map<String, dynamic>) onTap;
  const _BannerSection({required this.banners, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final mobile = context.isMobile;
    return LayoutBuilder(
      builder: (context, c) {
        // Two per row on wide screens, one per row on mobile.
        final cardWidth = mobile ? c.maxWidth : (c.maxWidth - 20) / 2;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            for (final b in banners)
              SizedBox(
                width: cardWidth,
                child: _BannerCard(
                    banner: b,
                    height: mobile ? 150 : 200,
                    onTap: () => onTap(b)),
              ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  final double height;
  final VoidCallback onTap;
  const _BannerCard(
      {required this.banner, required this.height, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final img = (banner['imageUrl'] as String?) ?? '';
    final title = (banner['title'] as String?) ?? '';
    final subtitle = (banner['subtitle'] as String?) ?? '';

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.productImageBg),
                    )
                  : Container(color: AppColors.productImageBg),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.15)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Shop Now',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.isMobile ? 150 : 200,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
