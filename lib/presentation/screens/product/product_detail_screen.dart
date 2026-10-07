import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../core/utils/external_link_helper.dart';
import '../../../core/brand/brand.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/store_chrome.dart';
import '../../widgets/product/product_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _selectedImage = 0;
  int _quantity = 1;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentlyViewedProvider.notifier).add(widget.productId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _openGallery(List<String> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GalleryViewer(images: images, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return const StorePage(
            body: Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: Text('Product not found')),
            ),
          );
        }
        final isWishlisted = ref.watch(wishlistProvider).contains(product.id);
        final images =
            product.imageUrls.isNotEmpty ? product.imageUrls : <String>[''];

        return StorePage(
          body: MaxWidthContainer(
            verticalPadding: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _breadcrumb(product),
                const SizedBox(height: 18),
                if (context.isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _gallery(product, images)),
                      const SizedBox(width: 40),
                      Expanded(child: _infoPanel(product, isWishlisted)),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _gallery(product, images),
                      const SizedBox(height: 24),
                      _infoPanel(product, isWishlisted),
                    ],
                  ),
                const SizedBox(height: 36),
                _tabsSection(product),
                const SizedBox(height: 32),
                _relatedSection(product),
                if (product.compatibleProductIds != null &&
                    product.compatibleProductIds!.isNotEmpty)
                  _compatibleSection(product),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      loading: () => const StorePage(
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 100),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => StorePage(
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Center(child: Text('Something went wrong: $e')),
        ),
      ),
    );
  }

  // ── Breadcrumb ──
  Widget _breadcrumb(ProductEntity product) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _crumb('Home', () => context.go(AppRoutes.home)),
        _crumbSep(),
        _crumb(
            product.categoryName,
            () => context.go(Uri(
                path: AppRoutes.productList,
                queryParameters: {'category': product.categoryId}).toString())),
        _crumbSep(),
        _crumb(
            product.brandName,
            () => context.go(Uri(
                path: AppRoutes.productList,
                queryParameters: {'brand': product.brandId}).toString())),
        _crumbSep(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _crumb(String label, VoidCallback onTap) => InkWell(
      onTap: onTap,
      child: Text(label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)));

  Widget _crumbSep() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('/',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 13)));

  // ── Gallery ──
  Widget _gallery(ProductEntity product, List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openGallery(images, _selectedImage),
          child: Container(
            height: context.isMobile ? 300 : 440,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.productImageBg,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                images[_selectedImage].isNotEmpty
                    ? Hero(
                        tag: 'product_${product.id}',
                        child: CachedNetworkImage(
                            imageUrl: images[_selectedImage],
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                                child: Icon(Icons.handyman_outlined,
                                    size: 64, color: AppColors.textTertiary))),
                      )
                    : const Center(
                        child: Icon(Icons.handyman_outlined,
                            size: 64, color: AppColors.textTertiary)),
                if (product.isFlashSale || product.isNewArrival)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        if (product.isFlashSale)
                          const _Badge(
                              label: 'FLASH SALE', color: AppColors.flash),
                        if (product.isNewArrival) ...[
                          const SizedBox(width: 6),
                          const _Badge(label: 'NEW', color: AppColors.new_),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selectedImage = i),
                child: Container(
                  width: 70,
                  decoration: BoxDecoration(
                    color: AppColors.productImageBg,
                    border: Border.all(
                        color: _selectedImage == i
                            ? AppColors.primary
                            : AppColors.border,
                        width: _selectedImage == i ? 2 : 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: images[i].isNotEmpty
                      ? CachedNetworkImage(imageUrl: images[i], fit: BoxFit.cover)
                      : const Icon(Icons.handyman_outlined,
                          size: 18, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Info panel ──
  Widget _infoPanel(ProductEntity product, bool isWishlisted) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(product.brandName.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: Icon(
                  isWishlisted
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color:
                      isWishlisted ? AppColors.error : AppColors.textSecondary),
              onPressed: () =>
                  ref.read(wishlistProvider.notifier).toggle(product.id),
            ),
          ],
        ),
        Text(product.name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(
          children: [
            RatingBarIndicator(
              rating: product.rating,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: AppColors.gold),
              itemCount: 5,
              itemSize: 18,
            ),
            const SizedBox(width: 8),
            Text(
                '${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PriceTag(
                  price: product.price,
                  discountPrice: product.discountPrice,
                  large: true),
              const SizedBox(height: 6),
              Text('Inclusive of all taxes (18% GST included)',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (product.isExternalLink)
          Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  color: AppColors.info, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sold and shipped by ${product.externalStoreLabel}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
          children: [
            Icon(
                product.inStock
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: product.inStock ? AppColors.success : AppColors.error,
                size: 20),
            const SizedBox(width: 6),
            Text(
              product.inStock
                  ? (product.isLowStock
                      ? 'Only ${product.stockQuantity} items left!'
                      : 'In Stock (Ready to dispatch)')
                  : 'Out of Stock',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: product.inStock
                    ? (product.isLowStock
                        ? AppColors.warning
                        : AppColors.success)
                    : AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (!product.isExternalLink)
          Row(
            children: [
              Text('Quantity:',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              _QuantitySelector(
                value: _quantity,
                max: product.stockQuantity.clamp(1, 10),
                onChanged: (v) => setState(() => _quantity = v),
              ),
            ],
          ),
        const SizedBox(height: 20),
        if (product.isExternalLink) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await openExternalLink(product.externalUrl);
                if (!ok) {
                  messenger.showSnackBar(SnackBar(
                      content: Text(
                          'Couldn\'t open the ${product.externalStoreLabel} link'),
                      backgroundColor: AppColors.error));
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text('Buy on ${product.externalStoreLabel}'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be taken to ${product.externalStoreLabel} to finish this '
            'purchase. The price there may differ.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ] else
          Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: product.inStock
                    ? () {
                        ref
                            .read(cartProvider.notifier)
                            .addItem(product, quantity: _quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Added to cart!'),
                              backgroundColor: AppColors.success),
                        );
                      }
                    : null,
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text('Add to Cart'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: product.inStock
                    ? () {
                        ref
                            .read(cartProvider.notifier)
                            .addItem(product, quantity: _quantity);
                        context.push(AppRoutes.checkout);
                      }
                    : null,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('Buy Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (product.bulkPricing != null && product.bulkPricing!.isNotEmpty) ...[
          _BulkPricingCard(
              bulkPricing: product.bulkPricing!,
              basePrice: product.effectivePrice),
          const SizedBox(height: 16),
        ],
        if (!product.isExternalLink)
          Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12)),
          child: const Column(
            children: [
              _InfoRow(
                  icon: Icons.local_shipping_outlined,
                  text: 'Free delivery on orders above ₹4,999'),
              _InfoRow(
                  icon: Icons.assignment_return_outlined,
                  text: '7-day easy returns policy'),
              _InfoRow(
                  icon: Icons.lock_outline_rounded,
                  text: '100% secure encrypted checkout'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tabs ──
  Widget _tabsSection(ProductEntity product) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24)),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: false,
            indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Description'),
              Tab(text: 'Specifications'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.description,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                    if (product.features.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Key Features',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...product.features.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.success, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(f,
                                        style: theme.textTheme.bodySmall)),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
              SingleChildScrollView(
                child: product.specifications != null
                    ? Text(product.specifications!,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.6))
                    : const Text('No specifications available',
                        style: TextStyle(color: AppColors.textSecondary)),
              ),
              _reviewsTabContent(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Reviews tab: list + write-a-review ──
  Widget _reviewsTabContent() {
    final reviewsAsync = ref.watch(productReviewsProvider(widget.productId));
    final user = ref.watch(currentUserProvider).valueOrNull;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  user == null ? _promptSignIn() : _showWriteReviewDialog(),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text(
                  user == null ? 'Sign in to write a review' : 'Write a review'),
            ),
          ),
          const SizedBox(height: 12),
          reviewsAsync.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator())),
            error: (e, _) => const Text('Could not load reviews',
                style: TextStyle(color: AppColors.textSecondary)),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No reviews yet. Be the first to review!',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return Column(
                children: list.map((r) {
                  final data = r as Map<String, dynamic>;
                  final rating = (data['rating'] as num?)?.toDouble() ?? 0;
                  final comment = (data['comment'] ?? '').toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(data['userName'] ?? 'Customer',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(width: 8),
                            ...List.generate(
                                5,
                                (i) => Icon(
                                    i < rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 14,
                                    color: AppColors.gold)),
                          ],
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(comment,
                              style:
                                  const TextStyle(fontSize: 13, height: 1.4)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _promptSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Please sign in to write a review'),
      action: SnackBarAction(
        label: 'Sign In',
        onPressed: () => context.go(
            '${AppRoutes.login}?redirect=${Uri.encodeComponent('/product/${widget.productId}')}'),
      ),
    ));
  }

  void _showWriteReviewDialog() {
    int rating = 5;
    final commentCtrl = TextEditingController();
    bool saving = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                    (i) => IconButton(
                          onPressed: () => setLocal(() => rating = i + 1),
                          icon: Icon(
                              i < rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.gold,
                              size: 32),
                        )),
              ),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Your review (optional)',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() => saving = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(dioProvider).post(
                          '/products/${widget.productId}/reviews',
                          data: {'rating': rating, 'comment': commentCtrl.text.trim()},
                        );
                        ref.invalidate(productReviewsProvider(widget.productId));
                        ref.invalidate(productDetailProvider(widget.productId));
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(const SnackBar(
                            content: Text('Thanks for your review!'),
                            backgroundColor: AppColors.success));
                      } catch (e) {
                        setLocal(() => saving = false);
                        messenger.showSnackBar(SnackBar(
                            content: Text('Failed to submit review: $e'),
                            backgroundColor: AppColors.error));
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Similar items ──
  Widget _relatedSection(ProductEntity product) {
    final theme = Theme.of(context);
    final related = ref.watch(
        productsProvider(ProductFilter(categoryId: product.categoryId, limit: 6)));
    return related.maybeWhen(
      data: (products) {
        final filtered = products.where((p) => p.id != product.id).toList();
        if (filtered.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Similar Items You Might Like',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) => SizedBox(
                    width: 200,
                    child: ProductCard(product: filtered[i], gridView: true)),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _compatibleSection(ProductEntity product) {
    final theme = Theme.of(context);
    final accessoriesAsync =
        ref.watch(compatibleProductsProvider(product.compatibleProductIds!));
    return accessoriesAsync.maybeWhen(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text('Compatible Accessories',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) => SizedBox(
                    width: 200,
                    child: ProductCard(product: products[i], gridView: true)),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _GalleryViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const _GalleryViewer({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(images[i]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
        pageController: PageController(initialPage: initialIndex),
        loadingBuilder: (_, __) =>
            const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int value;
  final int max;
  final void Function(int) onChanged;

  const _QuantitySelector(
      {required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyBtn(
          icon: Icons.remove,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Text('$value',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
        _QtyBtn(
          icon: Icons.add,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QtyBtn({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(
              color: onPressed != null ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color:
                onPressed != null ? AppColors.primary : AppColors.textDisabled),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _BulkPricingCard extends StatelessWidget {
  final Map<String, dynamic> bulkPricing;
  final double basePrice;

  const _BulkPricingCard({required this.bulkPricing, required this.basePrice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedTiers = bulkPricing.entries.toList()
      ..sort((a, b) {
        final qa = int.tryParse(a.key) ?? 0;
        final qb = int.tryParse(b.key) ?? 0;
        return qa.compareTo(qb);
      });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      color: AppColors.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sell_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${Brand.current.copy.bulkPricingLabel} Pricing Tiers',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.4),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('Min Qty',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('Discount',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('Price / Unit',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
                ...sortedTiers.map((entry) {
                  final qty = entry.key;
                  final discountPercent =
                      ((entry.value as num) * 100).toStringAsFixed(0);
                  final discountFactor = 1.0 - (entry.value as num).toDouble();
                  final tierPrice = basePrice * discountFactor;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('$qty+ units',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('$discountPercent% OFF',
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('₹${tierPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.right),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
