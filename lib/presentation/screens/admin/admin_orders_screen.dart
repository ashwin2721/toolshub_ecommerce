import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

final adminOrdersProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/orders/admin');
  return response.data;
});

final adminCustomersProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/admin/customers');
  return response.data as List<dynamic>;
});

final adminInventoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/products');
  return response.data as List<dynamic>;
});

final adminCouponsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/coupons');
  return response.data as List<dynamic>;
});

final adminBannersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/banners/admin');
  return response.data as List<dynamic>;
});


// ── Admin Orders Screen ────────────────────────────────────────────────────────
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _statuses = ['All', 'Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _statuses.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: _statuses.map((s) => Tab(text: s)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _statuses.map((status) => _OrdersList(status: status)).toList(),
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  final String status;
  const _OrdersList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminOrdersProvider.future),
      child: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load orders: $err')),
        data: (orders) {
          var filtered = orders;
          if (status != 'All') {
            filtered = orders.where((item) => item['status'] == status.toLowerCase()).toList();
          }

          if (filtered.isEmpty) {
            return const Center(child: Text('No orders'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final data = filtered[i] as Map<String, dynamic>;
              final currentStatus = data['status'] ?? 'pending';
              final orderId = data['id'] as String;
              return _AdminOrderCard(
                docId: orderId,
                data: data,
                currentStatus: currentStatus,
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerWidget {
  final String docId, currentStatus;
  final Map<String, dynamic> data;

  const _AdminOrderCard({required this.docId, required this.data, required this.currentStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = currentStatus == 'delivered' ? AppColors.success
        : currentStatus == 'cancelled' ? AppColors.error
        : currentStatus == 'shipped' ? AppColors.info
        : AppColors.warning;

    final orderNumber = docId.length > 8
        ? 'TH-${docId.substring(docId.length - 8).toUpperCase()}'
        : docId.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  ),
                child: DropdownButton<String>(
                  value: currentStatus,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                  items: ['pending', 'confirmed', 'processing', 'packed', 'shipped', 'delivered', 'cancelled']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                      .toList(),
                  onChanged: (newStatus) async {
                    if (newStatus != null) {
                      try {
                        final dio = ref.read(dioProvider);
                        await dio.put('/orders/admin/$docId/status', data: {
                          'status': newStatus,
                        });
                        ref.invalidate(adminOrdersProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                data['shippingAddress'] != null && data['shippingAddress']['fullName'] != null
                    ? data['shippingAddress']['fullName']
                    : 'Customer',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              Text('₹${(data['totalAmount'] as num?)?.toStringAsFixed(2) ?? "0"}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Admin Customers Screen ─────────────────────────────────────────────────────
class AdminCustomersScreen extends ConsumerWidget {
  const AdminCustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(adminCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.refresh(adminCustomersProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAdminDialog(context, ref),
        icon: const Icon(Icons.admin_panel_settings_outlined),
        label: const Text('Add Admin'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminCustomersProvider.future),
        child: customersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Failed to load customers: $err')),
          data: (customers) {
            if (customers.isEmpty) {
              return const Center(child: Text('No customers registered yet'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final data = customers[i] as Map<String, dynamic>;
                final isBlocked = data['isBlocked'] ?? false;
                final customerId = data['id'] as String;

                return ListTile(
                  tileColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      (data['name'] as String? ?? '?')[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(data['email'] ?? '', style: const TextStyle(fontSize: 12)),
                  trailing: Switch(
                    value: !isBlocked,
                    onChanged: (v) async {
                      try {
                        final dio = ref.read(dioProvider);
                        await dio.put('/admin/customers/$customerId/block', data: {
                          'isBlocked': !v,
                        });
                        ref.invalidate(adminCustomersProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
                    activeThumbColor: AppColors.success,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreateAdminDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool saving = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Create Admin'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The new account will have full admin access.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password (min 6 characters)',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setLocal(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (nameCtrl.text.trim().isEmpty ||
                          emailCtrl.text.trim().isEmpty ||
                          passwordCtrl.text.length < 6) {
                        messenger.showSnackBar(const SnackBar(
                          content: Text('Enter a name, email, and a 6+ character password'),
                          backgroundColor: AppColors.error,
                        ));
                        return;
                      }
                      setLocal(() => saving = true);
                      try {
                        await ref.read(dioProvider).post('/auth/admins', data: {
                          'name': nameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'password': passwordCtrl.text,
                        });
                        ref.invalidate(adminCustomersProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(const SnackBar(
                          content: Text('Admin account created successfully'),
                          backgroundColor: AppColors.success,
                        ));
                      } on DioException catch (e) {
                        final data = e.response?.data;
                        final msg = data is Map && data['error'] != null
                            ? data['error'].toString()
                            : 'Failed to create admin';
                        messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
                        setLocal(() => saving = false);
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
                        setLocal(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Admin Inventory Screen ─────────────────────────────────────────────────────
class AdminInventoryScreen extends ConsumerWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(adminInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.refresh(adminInventoryProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminInventoryProvider.future),
        child: inventoryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Failed to load inventory: $err')),
          data: (products) {
            final totalCount = products.length;
            final lowStockCount = products.where((d) {
              final q = (d['stockQuantity'] as num?)?.toInt() ?? 0;
              return q > 0 && q <= 10;
            }).length;
            final outOfStockCount = products.where((d) {
              final q = (d['stockQuantity'] as num?)?.toInt() ?? 0;
              return q == 0;
            }).length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _InventoryStat('Total', '$totalCount', Colors.blue),
                      _InventoryStat('Low Stock', '$lowStockCount', AppColors.warning),
                      _InventoryStat('Out of Stock', '$outOfStockCount', AppColors.error),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final data = products[i] as Map<String, dynamic>;
                      final stock = (data['stockQuantity'] as num?)?.toInt() ?? 0;
                      final stockColor = stock == 0 ? AppColors.error : stock <= 10 ? AppColors.warning : AppColors.success;
                      return ListTile(
                        title: Text(data['name'] ?? '', style: const TextStyle(fontSize: 13)),
                        subtitle: Text('SKU: ${data['sku'] ?? ""}', style: const TextStyle(fontSize: 11)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$stock units', style: TextStyle(color: stockColor, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InventoryStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InventoryStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Admin Coupons Screen ───────────────────────────────────────────────────────
class AdminCouponsScreen extends ConsumerWidget {
  const AdminCouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(adminCouponsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCouponDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Coupon'),
      ),
      body: couponsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load coupons: $e')),
        data: (docs) {
          if (docs.isEmpty) return const Center(child: Text('No coupons yet'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminCouponsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final data = docs[i] as Map<String, dynamic>;
                final type = data['type'] ?? 'percentage';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
                    title: Text(data['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                    subtitle: Text('$type • ${data['value']}${type == 'percentage' ? '%' : '₹'} off'),
                    trailing: Switch(
                      value: data['isActive'] ?? false,
                      onChanged: (v) async {
                        await ref.read(dioProvider).patch('/coupons/${data['id']}', data: {'isActive': v});
                        ref.invalidate(adminCouponsProvider);
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddCouponDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String type = 'percentage';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Coupon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Coupon Code'),
                  textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (₹)')),
                  DropdownMenuItem(value: 'free_shipping', child: Text('Free Shipping')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'percentage'),
              ),
              const SizedBox(height: 8),
              TextField(controller: valueCtrl, decoration: const InputDecoration(labelText: 'Value'),
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(dioProvider).post('/coupons', data: {
                  'code': codeCtrl.text.toUpperCase(),
                  'type': type,
                  'value': double.tryParse(valueCtrl.text) ?? 0,
                });
                ref.invalidate(adminCouponsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Admin Banners Screen ───────────────────────────────────────────────────────
class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Banners'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBannerDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Banner'),
      ),
      body: bannersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load banners: $e')),
        data: (docs) {
          if (docs.isEmpty) return const Center(child: Text('No banners. Add one!'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminBannersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final data = docs[i] as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 60, height: 40,
                      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: Icon(Icons.image_outlined, color: AppColors.primary)),
                    ),
                    title: Text(data['title'] ?? 'Banner', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(data['actionUrl'] ?? '', style: const TextStyle(fontSize: 11)),
                    trailing: Switch(
                      value: data['isActive'] ?? false,
                      onChanged: (v) async {
                        await ref.read(dioProvider).patch('/banners/${data['id']}', data: {'isActive': v});
                        ref.invalidate(adminBannersProvider);
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final actionCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Banner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: subtitleCtrl, decoration: const InputDecoration(labelText: 'Subtitle')),
              const SizedBox(height: 8),
              TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL')),
              const SizedBox(height: 8),
              TextField(controller: actionCtrl, decoration: const InputDecoration(labelText: 'Action URL (e.g. /products)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(dioProvider).post('/banners', data: {
                'title': titleCtrl.text.trim(),
                'subtitle': subtitleCtrl.text.trim(),
                'imageUrl': imageCtrl.text.trim(),
                'actionUrl': actionCtrl.text.trim(),
                'isActive': true,
              });
              ref.invalidate(adminBannersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Admin Reports Screen ───────────────────────────────────────────────────────
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate Reports', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...[
              ('Sales Report', Icons.trending_up_outlined, 'Monthly & annual sales summary'),
              ('Product Report', Icons.inventory_2_outlined, 'Top selling, low stock products'),
              ('Inventory Report', Icons.warehouse_outlined, 'Current stock levels'),
              ('Customer Report', Icons.people_outline, 'New customers, retention'),
              ('Tax Report (GST)', Icons.receipt_outlined, 'GST collected & payable'),
            ].map((r) => Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Icon(r.$2, color: AppColors.primary),
                ),
                title: Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(r.$3, style: const TextStyle(fontSize: 12)),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'pdf', child: Text('Download PDF')),
                    PopupMenuItem(value: 'excel', child: Text('Download Excel')),
                    PopupMenuItem(value: 'csv', child: Text('Download CSV')),
                  ],
                  onSelected: (format) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Generating ${r.$1} ($format)...')),
                    );
                  },
                  child: const Icon(Icons.download_outlined),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
