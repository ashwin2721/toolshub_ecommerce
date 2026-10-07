import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/external_link_helper.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/app_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_logo.dart';

class ProductCard extends ConsumerWidget {
  final ProductEntity product;
  final bool compact;
  final bool gridView;

  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.gridView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider.notifier);
    final wishlist = ref.watch(wishlistProvider);
    final isWishlisted = wishlist.contains(product.id);

    Widget cardWidget;
    if (gridView) {
      cardWidget = _GridCard(product: product, theme: theme,
          isWishlisted: isWishlisted, cart: cart);
    } else if (compact) {
      cardWidget = _CompactCard(product: product, theme: theme,
          isWishlisted: isWishlisted, cart: cart);
    } else {
      cardWidget = _ListCard(product: product, theme: theme,
          isWishlisted: isWishlisted, cart: cart);
    }

    return _HoverLift(child: cardWidget);
  }
}

// ─── Hover Lift Transition Wrapper ───
class _HoverLift extends StatefulWidget {
  final Widget child;
  const _HoverLift({required this.child});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _isHovered
            ? (Matrix4.identity()
              ..translateByDouble(0.0, -5.0, 0.0, 1.0)
              ..scaleByDouble(1.02, 1.02, 1.02, 1.0))
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}

// ─── Grid Card ────────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final ProductEntity product;
  final ThemeData theme;
  final bool isWishlisted;
  final CartNotifier cart;

  const _GridCard({
    required this.product,
    required this.theme,
    required this.isWishlisted,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image on a light gray tile
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.productImageBg,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        child: product.primaryImage != null
                            ? CachedNetworkImage(
                                imageUrl: product.primaryImage!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    const _ImagePlaceholder(),
                              )
                            : const _ImagePlaceholder(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.isFlashSale)
                          const _Badge(label: 'SALE', color: AppColors.flash),
                        if (product.isNewArrival)
                          const _Badge(label: 'NEW', color: AppColors.new_),
                        if (product.isExternalLink)
                          _ExternalBadge(label: product.externalStoreLabel),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        _WishlistBtn(
                            productId: product.id,
                            isWishlisted: isWishlisted),
                        const SizedBox(height: 8),
                        _CompareBtn(productId: product.id),
                      ],
                    ),
                  ),
                  // An external product has no stock here by design, so the scrim
                  // would otherwise black out every one of them.
                  if (!product.isExternalLink && !product.inStock)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14)),
                        ),
                        child: const Center(
                          child: Text('OUT OF STOCK',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${product.effectivePrice.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brandName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: product.rating,
                        itemBuilder: (_, __) =>
                            const Icon(Icons.star, color: AppColors.gold),
                        itemCount: 5,
                        itemSize: 13,
                      ),
                      const SizedBox(width: 5),
                      Text('(${product.reviewCount})',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    // Filled rather than outlined, so it reads as a different
                    // action from Add to Cart rather than a variant of it.
                    child: product.isExternalLink
                        ? ElevatedButton.icon(
                            onPressed: () => _openStore(context, product),
                            icon: const Icon(Icons.open_in_new_rounded, size: 15),
                            label: Text('Buy on ${product.externalStoreLabel}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: product.inStock
                                ? () {
                                    cart.addItem(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to cart!'),
                                        duration: Duration(seconds: 1),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                                product.inStock ? 'Add to Cart' : 'Out of Stock',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact Card (Horizontal Scroll) ────────────────────────────────────────
class _CompactCard extends StatelessWidget {
  final ProductEntity product;
  final ThemeData theme;
  final bool isWishlisted;
  final CartNotifier cart;

  const _CompactCard({
    required this.product,
    required this.theme,
    required this.isWishlisted,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        width: 154,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: product.primaryImage != null
                      ? CachedNetworkImage(
                          imageUrl: product.primaryImage!,
                          height: 125,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const _ImagePlaceholder(height: 125),
                        )
                      : const _ImagePlaceholder(height: 125),
                ),
                if (product.isExternalLink)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _ExternalBadge(label: product.externalStoreLabel),
                  )
                else if (product.hasDiscount)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _Badge(
                        label: '-${product.discountPercent.toStringAsFixed(0)}%',
                        color: AppColors.flash),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _WishlistBtn(productId: product.id, isWishlisted: isWishlisted),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PriceTag(
                    price: product.price,
                    discountPrice: product.discountPrice,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List Card ────────────────────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final ProductEntity product;
  final ThemeData theme;
  final bool isWishlisted;
  final CartNotifier cart;

  const _ListCard({
    required this.product,
    required this.theme,
    required this.isWishlisted,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: product.primaryImage != null
                  ? CachedNetworkImage(
                      imageUrl: product.primaryImage!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const _ImagePlaceholder(height: 110, width: 110),
                    )
                  : const _ImagePlaceholder(height: 110, width: 110),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brandName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: product.rating,
                          itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.gold),
                          itemCount: 5,
                          itemSize: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    PriceTag(
                      price: product.price,
                      discountPrice: product.discountPrice,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _WishlistBtn(productId: product.id, isWishlisted: isWishlisted),
                  const SizedBox(height: 12),
                  // External products route to the partner store. Note the
                  // deliberate bypass of the `product.inStock` styling below: their
                  // stock is 0, which would otherwise render this grey-disabled.
                  if (product.isExternalLink)
                    GestureDetector(
                      onTap: () => _openStore(context, product),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(Icons.open_in_new_rounded,
                            size: 16, color: Colors.white),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: product.inStock
                          ? () {
                              cart.addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to cart!'),
                                  duration: Duration(seconds: 1),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: product.inStock ? AppColors.primary : AppColors.textDisabled,
                          shape: BoxShape.circle,
                          boxShadow: product.inStock
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Opens an externally-fulfilled product's store link, telling the customer when
// it could not be opened — a dead link must not look like a button that does
// nothing. Shared by all three card layouts.
Future<void> _openStore(BuildContext context, ProductEntity product) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await openExternalLink(product.externalUrl);
  if (!ok) {
    messenger.showSnackBar(SnackBar(
      content: Text('Couldn\'t open the ${product.externalStoreLabel} link'),
      backgroundColor: AppColors.error,
    ));
  }
}

/// Marks a card as linking out to a partner store, so the customer knows the tap
/// leaves the app before they make it.
class _ExternalBadge extends StatelessWidget {
  final String label;
  const _ExternalBadge({required this.label});

  @override
  Widget build(BuildContext context) =>
      _Badge(label: label.toUpperCase(), color: AppColors.warning);
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────
class _WishlistBtn extends ConsumerWidget {
  final String productId;
  final bool isWishlisted;

  const _WishlistBtn({required this.productId, required this.isWishlisted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () =>
          ref.read(wishlistProvider.notifier).toggle(productId),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
          ],
        ),
        child: Icon(
          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 14,
          color: isWishlisted ? AppColors.error : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CompareBtn extends ConsumerWidget {
  final String productId;

  const _CompareBtn({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparison = ref.watch(comparisonProvider);
    final inComparison = comparison.contains(productId);

    return GestureDetector(
      onTap: () {
        // If the comparison is already full and this product isn't part of it,
        // block the add and tell the user about the 3-item cap.
        if (!inComparison && comparison.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can compare up to 3 products'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        ref.read(comparisonProvider.notifier).toggle(productId);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
          ],
        ),
        child: Icon(
          Icons.compare_arrows_rounded,
          size: 14,
          color: inComparison ? AppColors.primary : AppColors.textSecondary,
        ),
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
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5)),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double? height;
  final double? width;

  const _ImagePlaceholder({this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? double.infinity,
      width: width ?? double.infinity,
      color: AppColors.productImageBg,
      child: const Center(
        child: Icon(Icons.handyman_outlined,
            size: 34, color: AppColors.textTertiary),
      ),
    );
  }
}
