import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/store_chrome.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponCtrl = TextEditingController();
  bool _applyingCoupon = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    if (_couponCtrl.text.trim().isEmpty) return;
    setState(() => _applyingCoupon = true);
    final error = await ref
        .read(cartProvider.notifier)
        .applyCoupon(_couponCtrl.text.trim(), ref.read(dioProvider));
    if (!mounted) return;
    setState(() => _applyingCoupon = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Coupon applied successfully!'),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return StorePage(
      showFooter: false,
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: cart.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: EmptyStateWidget(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your cart is empty',
                  subtitle:
                      'Add products to your cart and they will appear here',
                  buttonLabel: 'Start Shopping',
                  onAction: () => context.go(AppRoutes.home),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('My Cart (${cart.totalItems})',
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            ref.read(cartProvider.notifier).clearCart(),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.error),
                        label: const Text('Clear All',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Two-column on desktop: items left, summary right.
                  context.isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _itemsColumn(cart)),
                            const SizedBox(width: 24),
                            Expanded(
                                flex: 2,
                                child: _summarySide(theme, cart)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _itemsColumn(cart),
                            const SizedBox(height: 16),
                            _summarySide(theme, cart),
                          ],
                        ),
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

  Widget _itemsColumn(dynamic cart) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FreeShippingProgressBar(subtotal: cart.subtotal),
        for (final it in cart.activeItems)
          _CartItem(
            item: it,
            onRemove: () => ref.read(cartProvider.notifier).removeItem(it.id),
            onQuantityChange: (q) =>
                ref.read(cartProvider.notifier).updateQuantity(it.id, q),
            onSaveForLater: () =>
                ref.read(cartProvider.notifier).saveForLater(it.id),
          ),
        if (cart.savedItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Saved for Later (${cart.savedItems.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          for (final it in cart.savedItems)
            _CartItem(
              item: it,
              isSaved: true,
              onRemove: () => ref.read(cartProvider.notifier).removeItem(it.id),
              onMoveToCart: () =>
                  ref.read(cartProvider.notifier).moveToCart(it.id),
            ),
        ],
      ],
    );
  }

  Widget _summarySide(ThemeData theme, dynamic cart) {
    return Column(
      children: [
        _couponCard(theme, cart),
        const SizedBox(height: 16),
        _summaryCard(theme, cart),
        const SizedBox(height: 16),
        _checkoutBar(theme, cart),
      ],
    );
  }

  Widget _couponCard(ThemeData theme, dynamic cart) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: cart.hasCoupon ? AppColors.success : AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: cart.hasCoupon
          ? _appliedCoupon(theme, cart)
          : _couponInput(theme),
    );
  }

  Widget _couponInput(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.local_offer_outlined, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _couponCtrl,
            enabled: !_applyingCoupon,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Enter promo coupon code',
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) {
              if (!_applyingCoupon) _applyCoupon();
            },
          ),
        ),
        TextButton(
          onPressed: _applyingCoupon ? null : _applyCoupon,
          child: _applyingCoupon
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Apply',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _appliedCoupon(ThemeData theme, dynamic cart) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.success),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${cart.couponCode} applied',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              Text(_couponBenefit(cart),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            _couponCtrl.clear();
            ref.read(cartProvider.notifier).removeCoupon();
          },
          child: const Text('Remove',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.error)),
        ),
      ],
    );
  }

  String _couponBenefit(dynamic cart) {
    switch (cart.couponType) {
      case 'free_shipping':
        return 'Free delivery unlocked';
      case 'percentage':
        return '${(cart.couponDiscount ?? 0).toStringAsFixed(0)}% off · '
            '-₹${cart.discountAmount.toStringAsFixed(2)}';
      default:
        return '-₹${cart.discountAmount.toStringAsFixed(2)} off';
    }
  }

  Widget _summaryCard(ThemeData theme, dynamic cart) {
    // Delivery is now priced by distance from the shop to the delivery address,
    // so the exact fee is only known at checkout. Orders over the free-shipping
    // threshold are guaranteed free regardless of distance.
    final freeByOrder = cart.subtotal >= AppConstants.freeShippingThreshold;
    final estTotal = freeByOrder
        ? cart.total
        : (cart.subtotal - cart.discountAmount + cart.gstAmount);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _SummaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(2)}'),
          if (cart.totalBulkDiscountSaved > 0)
            _SummaryRow('Contractor Bulk Savings',
                '-₹${cart.totalBulkDiscountSaved.toStringAsFixed(2)}',
                color: AppColors.success, isBold: true),
          if (cart.hasCoupon)
            _SummaryRow('Coupon Discount (${cart.couponCode})',
                '-₹${cart.discountAmount.toStringAsFixed(2)}',
                color: AppColors.success, isBold: true),
          _SummaryRow(
              'Delivery',
              freeByOrder ? 'FREE' : 'Calculated at checkout',
              color: freeByOrder ? AppColors.success : AppColors.textSecondary,
              isBold: freeByOrder),
          _SummaryRow('GST Tax (18%)', '₹${cart.gstAmount.toStringAsFixed(2)}'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(freeByOrder ? 'Grand Total' : 'Estimated Total',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text('₹${estTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          if (!freeByOrder)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('+ delivery, based on your address at checkout',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }

  Widget _checkoutBar(ThemeData theme, dynamic cart) {
    final freeByOrder = cart.subtotal >= AppConstants.freeShippingThreshold;
    final estTotal = freeByOrder
        ? cart.total
        : (cart.subtotal - cart.discountAmount + cart.gstAmount);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(freeByOrder ? 'Total Payable:' : 'Est. Total:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('₹${estTotal.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        CustomButton(
          label: 'Proceed to Secure Checkout',
          onPressed: () => context.push(AppRoutes.checkout),
          icon: Icons.lock_outline_rounded,
        ),
      ],
    );
  }
}

// ─── Free Shipping Progress Widget ───
class _FreeShippingProgressBar extends StatelessWidget {
  final double subtotal;

  const _FreeShippingProgressBar({required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const freeShippingLimit = AppConstants.freeShippingThreshold;
    final progress = (subtotal / freeShippingLimit).clamp(0.0, 1.0);
    final remaining = freeShippingLimit - subtotal;
    final isFree = remaining <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFree
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFree
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isFree ? 'Congratulations!' : 'Delivery Discount Deal',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isFree ? AppColors.success : AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                isFree
                    ? 'Free Shipping Applied'
                    : '₹${remaining.toStringAsFixed(0)} away',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isFree ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isFree ? AppColors.success : AppColors.primary),
            ),
          ),
          if (!isFree) ...[
            const SizedBox(height: 6),
            Text(
              'Add ₹${remaining.toStringAsFixed(0)} more of items to unlock FREE shipping!',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Compact Cart Item Card ───
class _CartItem extends StatelessWidget {
  final dynamic item;
  final VoidCallback? onRemove;
  final void Function(int)? onQuantityChange;
  final VoidCallback? onSaveForLater;
  final VoidCallback? onMoveToCart;
  final bool isSaved;

  const _CartItem({
    required this.item,
    this.onRemove,
    this.onQuantityChange,
    this.onSaveForLater,
    this.onMoveToCart,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.productImage != null
                ? CachedNetworkImage(
                    imageUrl: item.productImage,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 84,
                        height: 84,
                        color: AppColors.productImageBg,
                        child: const Center(
                            child: Icon(Icons.handyman_outlined,
                                size: 28, color: AppColors.textTertiary))),
                  )
                : Container(
                    width: 84,
                    height: 84,
                    color: AppColors.productImageBg,
                    child: const Center(
                        child: Icon(Icons.handyman_outlined,
                            size: 28, color: AppColors.textTertiary))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text('SKU: ${item.sku}',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('₹${item.effectivePrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w800)),
                if (item.hasBulkDiscount) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      '${(item.bulkDiscountPercent * 100).toStringAsFixed(0)}% Contractor Bulk Discount Applied',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!isSaved && onQuantityChange != null) ...[
                      _QtyBtn(
                          icon: Icons.remove,
                          onPressed: item.quantity > 1
                              ? () => onQuantityChange!(item.quantity - 1)
                              : null),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('${item.quantity}',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      _QtyBtn(
                          icon: Icons.add,
                          onPressed: item.quantity < item.maxQuantity
                              ? () => onQuantityChange!(item.quantity + 1)
                              : null),
                      const Spacer(),
                    ],
                    if (isSaved && onMoveToCart != null)
                      ElevatedButton.icon(
                        onPressed: onMoveToCart,
                        icon: const Icon(Icons.shopping_cart_outlined, size: 12),
                        label: const Text('Move to Cart',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (!isSaved && onSaveForLater != null)
                      TextButton.icon(
                        onPressed: onSaveForLater,
                        icon: const Icon(Icons.bookmark_border_rounded,
                            size: 14),
                        label: const Text('Save for Later',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onRemove,
            color: AppColors.textSecondary,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color:
                onPressed != null ? AppColors.primary : AppColors.textDisabled),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isBold;

  const _SummaryRow(this.label, this.value, {this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
