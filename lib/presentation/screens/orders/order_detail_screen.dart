import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/store_chrome.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/order_entity.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  // Memoized once so rebuilds don't refetch and flash the loader.
  late Future<dynamic> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _fetchOrder();
  }

  Future<dynamic> _fetchOrder() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/orders/${widget.orderId}');
    return res.data;
  }

  void _reload() {
    setState(() {
      _orderFuture = _fetchOrder();
    });
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final dio = ref.read(dioProvider);
    try {
      await dio.post('/orders/${widget.orderId}/cancel');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled')),
      );
      _reload();
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Failed to cancel order';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Order Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  onPressed: () {},
                  tooltip: 'Download Invoice',
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<dynamic>(
              future: _orderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: Text('Order not found')),
                  );
                }
          final data = snapshot.data as Map<String, dynamic>;
          final status = OrderStatus.fromString(data['status'] ?? 'pending');
          final items = (data['items'] as List<dynamic>?) ?? [];
          final address = data['shippingAddress'] as Map<String, dynamic>?;

          double subtotal = 0.0;
          for (var item in items) {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
            subtotal += price * qty;
          }

          // Only `totalAmount` is stored on the order; derive the remaining
          // charges from the real total so the breakdown always reconciles
          // instead of fabricating shipping/GST client-side.
          final total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final adjustment = total - subtotal;

          final orderNumber = widget.orderId.length > 8
              ? 'TH-${widget.orderId.substring(widget.orderId.length - 8).toUpperCase()}'
              : widget.orderId.toUpperCase();

          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orderNumber,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          Text(status.label,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      Text('₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Items
                Text('Items (${items.length})',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...items.map((item) => _ItemRow(item: item)),
                const SizedBox(height: 16),

                // Shipping Address
                if (address != null) ...[
                  Text('Shipping Address',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address['fullName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(address['phone'] ?? '',
                            style: const TextStyle(color: AppColors.textSecondary)),
                        Text(
                            '${address['street']}, ${address['city']}, ${address['state']} - ${address['pinCode']}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Order Summary
                Text('Price Details',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _PriceRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                      if (adjustment.abs() >= 0.01)
                        _PriceRow(
                          adjustment >= 0 ? 'Shipping & Taxes' : 'Discount',
                          '${adjustment < 0 ? '-' : ''}₹${adjustment.abs().toStringAsFixed(2)}',
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                if (status == OrderStatus.pending ||
                    status == OrderStatus.confirmed ||
                    status == OrderStatus.processing)
                  ElevatedButton.icon(
                    onPressed: _cancelOrder,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Order'),
                    style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.error,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                if (status == OrderStatus.delivered)
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.replay_outlined),
                    label: const Text('Reorder'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
              ],
            );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final dynamic item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final total = price * qty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('Qty: $qty',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text('₹${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _PriceRow(this.label, this.value) : color = null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
