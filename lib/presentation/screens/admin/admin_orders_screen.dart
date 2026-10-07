import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../core/utils/csv_download.dart';

/// The statuses the API accepts, mirroring ORDER_STATUSES in
/// server/src/routes/orders.ts. Kept in one place so the dropdown's items
/// and its value check cannot drift apart.
const _kOrderStatuses = [
  'pending', 'confirmed', 'processing', 'packed', 'shipped', 'delivered',
  'cancelled',
];

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
  // Admin endpoint so inventory includes disabled products too.
  final response = await dio.get('/products/admin');
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
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Timer? _pollTimer;
  // 'Packed' is offered by the per-order status dropdown, so it needs a tab
  // too - without one, a packed order vanished from every tab but All.
  final _statuses = ['All', 'Pending', 'Confirmed', 'Processing', 'Packed',
      'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _statuses.length, vsync: this);
    // Poll so new orders show up (and the notification badge updates) without
    // a manual refresh — the admin "sees" incoming orders to confirm/dispatch.
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) ref.invalidate(adminOrdersProvider);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(adminOrdersProvider).maybeWhen(
          data: (orders) =>
              orders.where((o) => (o['status'] ?? '') == 'pending').length,
          orElse: () => 0,
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: pending > 0
                ? '$pending new order(s) awaiting confirmation'
                : 'No new orders',
            onPressed: () => _tabCtrl.animateTo(1),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (pending > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: AppColors.error, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$pending',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminOrdersProvider),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: _statuses.map((s) {
            if (s == 'Pending' && pending > 0) {
              return Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(s),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('$pending',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              );
            }
            return Tab(text: s);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children:
            _statuses.map((status) => _OrdersList(status: status)).toList(),
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
                  // A status outside the known set (legacy row, or a direct API
                  // write) would otherwise trip the dropdown's assertion and
                  // crash the whole order list.
                  value: _kOrderStatuses.contains(currentStatus)
                      ? currentStatus
                      : null,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                  items: _kOrderStatuses
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
class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() =>
      _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  final Set<String> _selected = {};
  bool _selectMode = false;

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selected.length} customer(s)?'),
        content: const Text('This permanently removes the account(s).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final dio = ref.read(dioProvider);
    for (final id in _selected) {
      try {
        await dio.delete('/admin/customers/$id');
      } catch (_) {}
    }
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    ref.invalidate(adminCustomersProvider);
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '-';
    final d = DateTime.tryParse(v.toString());
    return d == null ? v.toString() : '${d.day}/${d.month}/${d.year}';
  }

  Widget _detailRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12))),
            Expanded(
                child: Text((value ?? '-').toString(),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Future<void> _showCustomerDetails(Map<String, dynamic> summary) async {
    Map<String, dynamic> d = summary;
    try {
      final res =
          await ref.read(dioProvider).get('/admin/customers/${summary['id']}');
      d = Map<String, dynamic>.from(res.data);
    } catch (_) {}
    if (!mounted) return;
    final addresses = (d['addresses'] as List?) ?? const [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d['name'] ?? 'Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Email', d['email']),
              _detailRow('Phone', d['phone']),
              _detailRow('Role', d['role']),
              _detailRow('Email verified',
                  (d['isEmailVerified'] == true) ? 'Yes' : 'No'),
              _detailRow('Blocked', (d['isBlocked'] == true) ? 'Yes' : 'No'),
              _detailRow('Joined', _fmtDate(d['createdAt'])),
              const SizedBox(height: 10),
              Text('Addresses (${addresses.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (addresses.isEmpty)
                const Text('No addresses saved',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              for (final a in addresses)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                      '${(a['type'] ?? '').toString().toUpperCase()} · ${a['fullName'] ?? ''}\n${a['street'] ?? ''}, ${a['city'] ?? ''}, ${a['state'] ?? ''} - ${a['pinCode'] ?? ''}\n${a['phone'] ?? ''}${a['isDefault'] == true ? '  (default)' : ''}',
                      style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(adminCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode ? '${_selected.length} selected' : 'Customers'),
        automaticallyImplyLeading: false,
        actions: _selectMode
            ? [
                TextButton.icon(
                  onPressed: _selected.isEmpty ? null : _deleteSelected,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: Text('Delete (${_selected.length})',
                      style: const TextStyle(color: AppColors.error)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _selectMode = false;
                    _selected.clear();
                  }),
                ),
                const SizedBox(width: 8),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist_rounded),
                  tooltip: 'Select',
                  onPressed: () => setState(() => _selectMode = true),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: () => ref.invalidate(adminCustomersProvider),
                ),
              ],
      ),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton.extended(
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
                final selected = _selected.contains(customerId);

                return ListTile(
                  onTap: () {
                    if (_selectMode) {
                      setState(() => selected
                          ? _selected.remove(customerId)
                          : _selected.add(customerId));
                    } else {
                      _showCustomerDetails(data);
                    }
                  },
                  onLongPress: () => setState(() {
                    _selectMode = true;
                    _selected.add(customerId);
                  }),
                  tileColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: selected ? 2 : 0)),
                  leading: _selectMode
                      ? Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary)
                      : CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            (data['name'] as String? ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    [data['email'], data['phone']]
                        .where((s) => s != null && s.toString().trim().isNotEmpty)
                        .join('  •  '),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: _selectMode
                      ? null
                      : Switch(
                          value: !isBlocked,
                          onChanged: (v) async {
                            try {
                              final dio = ref.read(dioProvider);
                              await dio.put(
                                  '/admin/customers/$customerId/block',
                                  data: {'isBlocked': !v});
                              ref.invalidate(adminCustomersProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Failed to update status: $e'),
                                      backgroundColor: AppColors.error),
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
            int lowStock = 0, outOfStock = 0, totalUnits = 0;
            double totalValue = 0;
            for (final d in products) {
              final q = (d['stockQuantity'] as num?)?.toInt() ?? 0;
              final threshold = (d['lowStockThreshold'] as num?)?.toInt() ?? 10;
              final price = (d['price'] as num?)?.toDouble() ?? 0;
              totalUnits += q;
              totalValue += q * price;
              if (q == 0) {
                outOfStock++;
              } else if (q <= threshold) {
                lowStock++;
              }
            }
            // Show the items most in need of attention first (lowest stock).
            final sorted = [...products]
              ..sort((a, b) => ((a['stockQuantity'] as num?)?.toInt() ?? 0)
                  .compareTo((b['stockQuantity'] as num?)?.toInt() ?? 0));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _InventoryStat('Products', '${products.length}', Colors.blue),
                      _InventoryStat('Low Stock', '$lowStock', AppColors.warning),
                      _InventoryStat('Out', '$outOfStock', AppColors.error),
                      _InventoryStat('Stock Value', '₹${totalValue.toStringAsFixed(0)}', AppColors.success),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('$totalUnits units in stock across ${products.length} products',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final data = sorted[i] as Map<String, dynamic>;
                      final stock = (data['stockQuantity'] as num?)?.toInt() ?? 0;
                      final threshold = (data['lowStockThreshold'] as num?)?.toInt() ?? 10;
                      final price = (data['price'] as num?)?.toDouble() ?? 0;
                      final status = stock == 0
                          ? 'Out of stock'
                          : stock <= threshold
                              ? 'Low stock'
                              : 'In stock';
                      final stockColor = stock == 0
                          ? AppColors.error
                          : stock <= threshold
                              ? AppColors.warning
                              : AppColors.success;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        title: Text(data['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            'SKU: ${data['sku'] ?? ""}  ·  ${data['categoryName'] ?? '—'}  ·  ₹${price.toStringAsFixed(0)} each  ·  value ₹${(stock * price).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: stockColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$stock units',
                                  style: TextStyle(
                                      color: stockColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ),
                            const SizedBox(height: 2),
                            Text(status,
                                style: TextStyle(
                                    color: stockColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ],
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
              TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL (or upload below)')),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final url = await pickAndUploadImage();
                      if (url != null) {
                        imageCtrl.text = url;
                        messenger.showSnackBar(const SnackBar(
                            content: Text('Image uploaded'),
                            backgroundColor: AppColors.success));
                      }
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                          content: Text(
                              e.toString().replaceFirst('Exception: ', '')),
                          backgroundColor: AppColors.error));
                    }
                  },
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('Upload image from device'),
                ),
              ),
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
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  static String _esc(Object? v) =>
      '"${(v ?? '').toString().replaceAll('"', '""')}"';
  static String _toCsv(List<List<Object?>> rows) =>
      rows.map((r) => r.map(_esc).join(',')).join('\r\n');
  static String _fmtDate(dynamic v) {
    final d = DateTime.tryParse((v ?? '').toString());
    return d == null
        ? (v ?? '').toString()
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _download(
      BuildContext context, WidgetRef ref, String key, String title) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      List<List<Object?>> rows;
      switch (key) {
        case 'sales':
          final orders = await ref.read(adminOrdersProvider.future);
          rows = [
            ['Order ID', 'Date', 'Customer', 'Payment', 'Status', 'Total (INR)']
          ];
          for (final o in orders) {
            final addr = (o['shippingAddress'] as Map?) ?? const {};
            rows.add([
              o['id'], _fmtDate(o['createdAt']), addr['fullName'] ?? '',
              o['paymentMethod'] ?? '', o['status'] ?? '',
              (o['totalAmount'] as num?)?.toStringAsFixed(2) ?? '0'
            ]);
          }
          break;
        case 'products':
        case 'inventory':
          final prods = await ref.read(adminInventoryProvider.future);
          rows = [
            ['Name', 'SKU', 'Category', 'Brand', 'Stock', 'MRP', 'Selling', 'Active']
          ];
          for (final p in prods) {
            rows.add([
              p['name'], p['sku'], p['categoryName'] ?? '', p['brandName'] ?? '',
              p['stockQuantity'] ?? 0, p['price'] ?? 0, p['discountPrice'] ?? '',
              (p['isActive'] == false) ? 'No' : 'Yes'
            ]);
          }
          break;
        case 'customers':
          final custs = await ref.read(adminCustomersProvider.future);
          rows = [
            ['Name', 'Email', 'Phone', 'Joined', 'Blocked']
          ];
          for (final c in custs) {
            rows.add([
              c['name'], c['email'], c['phone'] ?? '', _fmtDate(c['createdAt']),
              (c['isBlocked'] == true) ? 'Yes' : 'No'
            ]);
          }
          break;
        case 'tax':
          final orders = await ref.read(adminOrdersProvider.future);
          rows = [
            ['Order ID', 'Date', 'Total (INR)', 'Est. GST @18% (INR)']
          ];
          for (final o in orders) {
            final total = (o['totalAmount'] as num?)?.toDouble() ?? 0;
            rows.add([
              o['id'], _fmtDate(o['createdAt']), total.toStringAsFixed(2),
              (total * 0.18 / 1.18).toStringAsFixed(2)
            ]);
          }
          break;
        default:
          rows = [];
      }
      if (rows.length <= 1) {
        messenger.showSnackBar(SnackBar(content: Text('No data for $title yet')));
        return;
      }
      final ts = DateTime.now().toIso8601String().substring(0, 10);
      downloadCsv('${key}_report_$ts.csv', _toCsv(rows));
      messenger.showSnackBar(SnackBar(
          content: Text('$title downloaded'),
          backgroundColor: AppColors.success));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Failed to generate report: $e'),
          backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reports = [
      ('sales', 'Sales Report', Icons.trending_up_outlined, 'All orders with totals & status'),
      ('products', 'Product Report', Icons.inventory_2_outlined, 'Catalog with prices & stock'),
      ('inventory', 'Inventory Report', Icons.warehouse_outlined, 'Current stock levels'),
      ('customers', 'Customer Report', Icons.people_outline, 'Registered customers'),
      ('tax', 'Tax Report (GST)', Icons.receipt_outlined, 'Estimated GST per order'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Download Reports (CSV)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...reports.map((r) => Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(r.$3, color: AppColors.primary),
                    ),
                    title: Text(r.$2,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(r.$4, style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_outlined),
                      tooltip: 'Download CSV',
                      onPressed: () => _download(context, ref, r.$1, r.$2),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
