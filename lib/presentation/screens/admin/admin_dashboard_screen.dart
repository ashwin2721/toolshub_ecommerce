import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/admin/stats');
  return response.data as Map<String, dynamic>;
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(adminStatsProvider),
          ),
          // NOTE: Sample data is seeded via the Postgres backend (`npm run db:seed`),
          // not from the app. The old Firestore seed action has been removed.
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const CircleAvatar(radius: 16, backgroundColor: AppColors.primary,
              child: Text('A', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load dashboard statistics: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(adminStatsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (stats) {
            final totalRevenue = stats['totalRevenue'] as num? ?? 0;
            final totalOrders = stats['totalOrders'] as int? ?? 0;
            final totalCustomers = stats['totalCustomers'] as int? ?? 0;
            final totalProducts = stats['totalProducts'] as int? ?? 0;
            final recentOrders = stats['recentOrders'] as List<dynamic>? ?? [];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome ──
                  Text('Welcome back, Admin! 👋',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text("Here's what's happening today",
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 20),

                  // ── KPI Cards ──
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _KpiCard(
                        label: 'Total Revenue',
                        value: '₹${totalRevenue.toStringAsFixed(0)}',
                        change: '+100%',
                        positive: true,
                        icon: Icons.currency_rupee_rounded,
                        color: AppColors.primary,
                      ),
                      _KpiCard(
                        label: 'Total Orders',
                        value: totalOrders.toString(),
                        change: '+100%',
                        positive: true,
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.info,
                      ),
                      _KpiCard(
                        label: 'Total Customers',
                        value: totalCustomers.toString(),
                        change: '+100%',
                        positive: true,
                        icon: Icons.people_rounded,
                        color: AppColors.success,
                      ),
                      _KpiCard(
                        label: 'Total Products',
                        value: totalProducts.toString(),
                        change: '+100%',
                        positive: true,
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Sales Chart ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sales Overview',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            DropdownButton<String>(
                              value: 'Monthly',
                              items: const [
                                DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                                DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                                DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                              ],
                              onChanged: (_) {},
                              underline: const SizedBox.shrink(),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              barGroups: List.generate(7, (i) {
                                final values = [45.0, 68.0, 52.0, 90.0, 75.0, 110.0, 85.0];
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: values[i],
                                      color: AppColors.primary,
                                      width: 20,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ],
                                );
                              }),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                      return Text(days[v.toInt()],
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Quick Actions ──
                  Text('Quick Actions',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _QuickAction(icon: Icons.add_box_outlined, label: 'Add Product',
                          color: AppColors.primary, onTap: () => context.go(AppRoutes.adminAddProduct)),
                      _QuickAction(icon: Icons.category_outlined, label: 'Categories',
                          color: AppColors.accentLight, onTap: () => context.go(AppRoutes.adminCategories)),
                      _QuickAction(icon: Icons.receipt_outlined, label: 'View Orders',
                          color: AppColors.info, onTap: () => context.go(AppRoutes.adminOrders)),
                      _QuickAction(icon: Icons.people_outline, label: 'Customers',
                          color: AppColors.success, onTap: () => context.go(AppRoutes.adminCustomers)),
                      _QuickAction(icon: Icons.tag_outlined, label: 'Coupons',
                          color: AppColors.warning, onTap: () => context.go(AppRoutes.adminCoupons)),
                      _QuickAction(icon: Icons.image_outlined, label: 'Banners',
                          color: AppColors.accent, onTap: () => context.go(AppRoutes.adminBanners)),
                      _QuickAction(icon: Icons.bar_chart_outlined, label: 'Reports',
                          color: AppColors.secondary, onTap: () => context.go(AppRoutes.adminReports)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Recent Orders ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Orders',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      TextButton(onPressed: () => context.go(AppRoutes.adminOrders),
                          child: const Text('View All')),
                    ],
                  ),
                  if (recentOrders.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(child: Text('No orders yet')),
                    )
                  else
                    Column(
                      children: recentOrders.map((data) {
                        return _OrderRow(
                          orderNumber: data['orderNumber'] ?? '',
                          customerName: data['userName'] ?? '',
                          total: (data['total'] as num?)?.toDouble() ?? 0,
                          status: data['status'] ?? 'pending',
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, change;
  final bool positive;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.change,
    required this.positive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: positive ? AppColors.successContainer : AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(change,
                    style: TextStyle(
                        color: positive ? AppColors.success : AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String orderNumber, customerName, status;
  final double total;

  const _OrderRow({required this.orderNumber, required this.customerName, required this.total, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'delivered' ? AppColors.success
        : status == 'cancelled' ? AppColors.error
        : status == 'shipped' ? AppColors.info
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(customerName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text('₹${total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}
