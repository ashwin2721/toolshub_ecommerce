import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/common/store_chrome.dart';
import '../../../domain/entities/order_entity.dart';
import 'package:timeline_tile/timeline_tile.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dio = ref.watch(dioProvider);

    final allStatuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.processing,
      OrderStatus.packed,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];

    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(height: 8),
            Text('Track Order',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            FutureBuilder<dynamic>(
              future: dio.get('/orders/$orderId').then((res) => res.data),
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
                final currentStatus =
                    OrderStatus.fromString(data['status'] ?? 'pending');
                final trackingNumber = data['trackingNumber'] as String?;
                final currentIdx = allStatuses.indexOf(currentStatus);

                final orderNumber = orderId.length > 8
                    ? 'TH-${orderId.substring(orderId.length - 8).toUpperCase()}'
                    : orderId.toUpperCase();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order: $orderNumber',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          if (trackingNumber != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.local_shipping_outlined,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text('Tracking: $trackingNumber',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Tracking History',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    // Timeline
                    ...List.generate(allStatuses.length, (i) {
                      final s = allStatuses[i];
                      final isDone = i <= currentIdx;
                      final isActive = i == currentIdx;
                      final isFirst = i == 0;
                      final isLast = i == allStatuses.length - 1;

                      return TimelineTile(
                        alignment: TimelineAlign.manual,
                        lineXY: 0.12,
                        isFirst: isFirst,
                        isLast: isLast,
                        indicatorStyle: IndicatorStyle(
                          width: 32,
                          height: 32,
                          color: isDone ? AppColors.primary : AppColors.border,
                          iconStyle: IconStyle(
                            iconData: isDone
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            color: isDone ? Colors.white : AppColors.textTertiary,
                            fontSize: 16,
                          ),
                        ),
                        beforeLineStyle: LineStyle(
                          color: isDone ? AppColors.primary : AppColors.border,
                          thickness: 2,
                        ),
                        afterLineStyle: LineStyle(
                          color: i < currentIdx
                              ? AppColors.primary
                              : AppColors.border,
                          thickness: 2,
                        ),
                        endChild: Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.label,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isActive
                                          ? AppColors.primary
                                          : isDone
                                              ? theme.colorScheme.onSurface
                                              : AppColors.textTertiary,
                                      fontSize: 15)),
                              Text(
                                _statusDescription(s),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDone
                                        ? AppColors.textSecondary
                                        : AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusDescription(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return 'Order received, awaiting confirmation';
      case OrderStatus.confirmed: return 'Order confirmed by our team';
      case OrderStatus.processing: return 'Order is being prepared';
      case OrderStatus.packed: return 'Order packed and ready to ship';
      case OrderStatus.shipped: return 'Order picked up by courier';
      case OrderStatus.delivered: return 'Order delivered successfully';
      default: return '';
    }
  }
}
