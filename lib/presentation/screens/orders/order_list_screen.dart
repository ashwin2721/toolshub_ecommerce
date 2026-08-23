import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/common/store_chrome.dart';
import '../../../domain/entities/order_entity.dart';

// Keyed to the current user's id and autoDisposed so a previous account's
// cached orders can never be served to a different user (cross-account leak).
final userOrdersProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/orders');
  return response.data;
});

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final theme = Theme.of(context);

    if (user == null) {
      return StorePage(
        body: MaxWidthContainer(
          verticalPadding: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backButton(context),
              const SizedBox(height: 4),
              Text('My Orders',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: Text('Please login to view orders')),
              ),
            ],
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(userOrdersProvider(user.id));

    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _backButton(context),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text('My Orders',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(userOrdersProvider(user.id)),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ordersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(child: Text('Failed to load orders: $err')),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text('No orders yet',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          const Text('Your order history will appear here'),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < orders.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _buildOrderCard(orders[i] as Map<String, dynamic>),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: const Text('Back'),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> data) {
    final status = OrderStatus.fromString(data['status'] ?? 'pending');
    final orderId = data['id'] as String;
    final orderNumber = orderId.length > 8
        ? 'TH-${orderId.substring(orderId.length - 8).toUpperCase()}'
        : orderId.toUpperCase();
    return _OrderCard(
      orderId: orderId,
      orderNumber: orderNumber,
      status: status,
      total: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      itemCount: (data['items'] as List?)?.length ?? 0,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'])
          : null,
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId, orderNumber;
  final OrderStatus status;
  final double total;
  final int itemCount;
  final DateTime? createdAt;

  const _OrderCard({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.itemCount,
    this.createdAt,
  });

  Color get _statusColor {
    switch (status) {
      case OrderStatus.delivered: return AppColors.success;
      case OrderStatus.shipped:
      case OrderStatus.packed:
      case OrderStatus.processing:
      case OrderStatus.confirmed: return AppColors.info;
      case OrderStatus.cancelled:
      case OrderStatus.returned:
      case OrderStatus.refunded: return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push('/orders/$orderId'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(orderNumber,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status.label,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$itemCount item${itemCount > 1 ? "s" : ""}',
                        style: theme.textTheme.bodySmall),
                    if (createdAt != null)
                      Text(
                          '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
                Text('₹${total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/orders/$orderId'),
                    icon: const Icon(Icons.receipt_outlined, size: 16),
                    label: const Text('Details', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                if (status == OrderStatus.shipped ||
                    status == OrderStatus.packed)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/orders/$orderId/tracking'),
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      label: const Text('Track', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
