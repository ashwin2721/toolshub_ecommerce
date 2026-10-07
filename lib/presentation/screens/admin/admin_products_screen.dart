import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/image_upload_helper.dart';
import 'admin_categories_screen.dart';

final adminProductsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  // Admin endpoint returns ALL products (including disabled ones) so they can
  // be seen and re-enabled.
  final response = await dio.get('/products/admin');
  return response.data;
});

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selected = {};
  bool _selectMode = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _duplicate(Map<String, dynamic> data) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/products', data: {
        'name': '${data['name']} (Copy)',
        'sku': '${data['sku']}-COPY-${DateTime.now().millisecondsSinceEpoch % 100000}',
        'description': data['description'],
        'price': data['price'],
        'discountPrice': data['discountPrice'],
        'stockQuantity': data['stockQuantity'] ?? 0,
        'lowStockThreshold': data['lowStockThreshold'] ?? 5,
        'categoryId': data['categoryId'],
        'isFeatured': data['isFeatured'] ?? false,
        'isFlashSale': data['isFlashSale'] ?? false,
        'isNewArrival': data['isNewArrival'] ?? false,
        'isExternal': data['isExternal'] ?? false,
        'externalUrl': data['externalUrl'],
        'brandName': data['brandName'],
        'imageUrls': data['imageUrls'],
        'specifications': data['specifications'],
        'features': data['features'],
      });
      ref.invalidate(adminProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Product duplicated'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to duplicate: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selected.length} product(s)?'),
        content: const Text('This action cannot be undone.'),
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
        await dio.delete('/products/$id');
      } catch (_) {}
    }
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    ref.invalidate(adminProductsProvider);
  }

  void _showCsvFormatDialog() {
    const sample =
        'name,sku,price,discountPrice,stockQuantity,categoryId,brandName,description\n'
        'Cordless Drill,DRL-001,8999,7499,50,cat-power-tools,DeWalt,Compact 20V drill\n'
        'Claw Hammer,HMR-002,799,,120,cat-hand-tools,Stanley,16oz steel hammer';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulk Upload — CSV Format'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Your CSV needs these columns (first row = headers). Copy this sample as a starting point:',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SelectableText(sample,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
              const SizedBox(height: 8),
              const Text(
                  'discountPrice may be left blank. categoryId must match an existing category id.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode ? '${_selected.length} selected' : 'Products'),
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
                  tooltip: 'Cancel',
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
                  icon: const Icon(Icons.upload_file_outlined),
                  onPressed: _showCsvFormatDialog,
                  tooltip: 'Bulk upload (CSV)',
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.adminAddProduct),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(adminProductsProvider.future),
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Failed to load products: $err')),
                data: (products) {
                  var filtered = products;
                  if (_searchQuery.isNotEmpty) {
                    filtered = products.where((item) {
                      final name = (item['name'] as String? ?? '').toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No products found'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final data = filtered[i] as Map<String, dynamic>;
                      final isActive = data['isActive'] ?? true;
                      final productId = data['id'] as String;

                      final selected = _selected.contains(productId);
                      return GestureDetector(
                        onLongPress: () => setState(() {
                          _selectMode = true;
                          _selected.add(productId);
                        }),
                        onTap: () {
                          if (_selectMode) {
                            setState(() => selected
                                ? _selected.remove(productId)
                                : _selected.add(productId));
                          } else {
                            context.push('/product/$productId');
                          }
                        },
                        child: Opacity(
                          opacity: isActive ? 1.0 : 0.5,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: selected ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                if (_selectMode) ...[
                                  Icon(
                                      selected
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textSecondary),
                                  const SizedBox(width: 10),
                                ],
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                      child: Text('🔧',
                                          style: TextStyle(fontSize: 24))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(data['name'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14)),
                                          ),
                                          if (data['isExternal'] == true) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppColors.warning
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                  (data['externalStoreName'] ??
                                                          'External')
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.warning,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ),
                                          ],
                                          if (!isActive) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppColors.error
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text('Hidden',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.error,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                          'SKU: ${data['sku'] ?? ""} | Stock: ${data['stockQuantity'] ?? 0}',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11)),
                                      Text(
                                          '₹${(data['price'] as num?)?.toStringAsFixed(0) ?? "0"}',
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Switch(
                                      value: isActive,
                                      onChanged: (v) async {
                                        try {
                                          final dio = ref.read(dioProvider);
                                          await dio.put('/products/$productId',
                                              data: {'isActive': v});
                                          ref.invalidate(adminProductsProvider);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Failed to update product status: $e'),
                                                  backgroundColor:
                                                      AppColors.error),
                                            );
                                          }
                                        }
                                      },
                                      activeThumbColor: AppColors.primary,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    PopupMenuButton<String>(
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                            value: 'view',
                                            child: Text('View details')),
                                        const PopupMenuItem(
                                            value: 'duplicate',
                                            child: Text('Duplicate')),
                                        const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete',
                                                style: TextStyle(
                                                    color: AppColors.error))),
                                      ],
                                      onSelected: (action) {
                                        if (action == 'view') {
                                          context.push('/product/$productId');
                                        } else if (action == 'duplicate') {
                                          _duplicate(data);
                                        } else if (action == 'delete') {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title:
                                                  const Text('Delete Product?'),
                                              content: const Text(
                                                  'This action cannot be undone.'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child:
                                                        const Text('Cancel')),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    try {
                                                      final dio =
                                                          ref.read(dioProvider);
                                                      await dio.delete(
                                                          '/products/$productId');
                                                      ref.invalidate(
                                                          adminProductsProvider);
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      Navigator.pop(context);
                                                    } catch (e) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Failed to delete product: $e'),
                                                            backgroundColor:
                                                                AppColors.error),
                                                      );
                                                    }
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              AppColors.error),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminAddProductScreen extends ConsumerStatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  ConsumerState<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends ConsumerState<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _lowStockCtrl = TextEditingController(text: '5');
  String? _selectedCategoryId;
  final _brandCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final List<String> _imageUrls = [];
  bool _isFeatured = false;
  bool _isFlashSale = false;
  bool _isNewArrival = false;
  bool _isExternal = false;
  final _externalUrlCtrl = TextEditingController();
  bool _loading = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountPriceCtrl.dispose();
    _stockCtrl.dispose();
    _lowStockCtrl.dispose();
    _brandCtrl.dispose();
    _imageUrlCtrl.dispose();
    _externalUrlCtrl.dispose();
    super.dispose();
  }

  void _addImage() {
    final url = _imageUrlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _imageUrls.add(url);
      _imageUrlCtrl.clear();
    });
  }

  Future<void> _uploadImage() async {
    setState(() => _uploadingImage = true);
    try {
      final url = await pickAndUploadImage();
      if (url != null) setState(() => _imageUrls.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/products', data: {
        'name': _nameCtrl.text,
        'sku': _skuCtrl.text,
        'description': _descCtrl.text,
        'price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'discountPrice': _discountPriceCtrl.text.isNotEmpty
            ? double.tryParse(_discountPriceCtrl.text)
            : null,
        'stockQuantity': _isExternal ? 0 : (int.tryParse(_stockCtrl.text) ?? 0),
        'lowStockThreshold': int.tryParse(_lowStockCtrl.text) ?? 5,
        'categoryId': _selectedCategoryId,
        'brandName': _brandCtrl.text.isNotEmpty ? _brandCtrl.text : null,
        'imageUrls': _imageUrls,
        'isFeatured': _isFeatured,
        'isFlashSale': _isFlashSale,
        'isNewArrival': _isNewArrival,
        'isExternal': _isExternal,
        // Guarded on the toggle: switching off after typing a URL must not ship
        // the text the now-unmounted field still holds.
        'externalUrl': _isExternal ? _externalUrlCtrl.text.trim() : null,
      });
      ref.invalidate(adminProductsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!'),
              backgroundColor: AppColors.success),
        );
        context.go(AppRoutes.adminProducts);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sits above Basic Information on purpose: this toggle changes what
              // the rest of the form means (it hides Stock), so it has to be read
              // before the fields it reconfigures.
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _isExternal,
                      onChanged: (v) => setState(() => _isExternal = v),
                      activeThumbColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sold on an external store',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Customers get a "Buy on Amazon" button instead of Add to '
                          'Cart. This product can never be added to a cart or ordered '
                          'here.',
                          style: TextStyle(fontSize: 12)),
                    ),
                    if (_isExternal) ...[
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _externalUrlCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Product link *',
                          prefixIcon: Icon(Icons.link_rounded),
                          hintText: 'https://www.amazon.in/dp/...',
                          helperText: 'The store name is taken from the link.',
                        ),
                        validator: (v) {
                          if (!_isExternal) return null;
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Required for an external product';
                          // Uri.tryParse accepts 'amazon.in/dp/x' with an empty
                          // scheme and host, so check both explicitly. Matches the
                          // server rule exactly so neither side rejects what the
                          // other accepted.
                          final u = Uri.tryParse(s);
                          if (u == null ||
                              u.host.isEmpty ||
                              (u.scheme != 'http' && u.scheme != 'https')) {
                            return 'Enter a full link starting with https://';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Basic Info
              Text('Basic Information', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.inventory_2_outlined)),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _skuCtrl, decoration: const InputDecoration(labelText: 'SKU *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null)),
                // We hold no inventory for an externally-fulfilled product, and a
                // number left in here would make the product list and low-stock
                // reports claim goods that do not exist.
                if (!_isExternal) ...[
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _stockCtrl, decoration: const InputDecoration(labelText: 'Stock *'),
                      keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _lowStockCtrl, decoration: const InputDecoration(labelText: 'Low-stock alert'),
                      keyboardType: TextInputType.number)),
                ],
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'MRP (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _discountPriceCtrl, decoration: const InputDecoration(labelText: 'Selling Price (₹)'),
                    keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Consumer(builder: (context, ref, _) {
                    final catsAsync = ref.watch(categoriesProvider);
                    final cats = catsAsync.valueOrNull ?? const [];
                    final hasNone = catsAsync.hasValue && cats.isEmpty;
                    // A value that is no longer in the list (category hidden or
                    // deleted elsewhere) would trip the dropdown's assertion,
                    // so only show one the items can match.
                    final ids = {for (final c in cats) c.id};
                    return DropdownButtonFormField<String>(
                      initialValue: ids.contains(_selectedCategoryId)
                          ? _selectedCategoryId
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        hintText: hasNone ? 'None yet — add one' : null,
                        helperText: hasNone
                            ? 'Tap + to create your first category'
                            : null,
                      ),
                      items: [
                        for (final c in cats)
                          DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name,
                                  overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedCategoryId = v),
                    );
                  }),
                ),
                // Create a category without leaving a half-filled product form.
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'New category',
                  onPressed: () async {
                    final id = await showCategoryFormDialog(context, ref);
                    if (id != null && id.isNotEmpty && mounted) {
                      setState(() => _selectedCategoryId = id);
                    }
                  },
                ),
                const SizedBox(width: 4),
                Expanded(child: TextFormField(controller: _brandCtrl, decoration: const InputDecoration(labelText: 'Brand'))),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtrl, maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true)),
              const SizedBox(height: 16),
              // Images
              Text('Product Images', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Upload images from your device, or paste image URLs. The first image is the main one.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _uploadingImage ? null : _uploadImage,
                  icon: _uploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_rounded, size: 18),
                  label:
                      Text(_uploadingImage ? 'Uploading…' : 'Upload from device'),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: _imageUrlCtrl,
                        decoration: const InputDecoration(
                            labelText: 'or paste an Image URL',
                            prefixIcon: Icon(Icons.link_rounded),
                            hintText: 'https://...'),
                        onFieldSubmitted: (_) => _addImage())),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                    onPressed: _addImage,
                    icon: const Icon(Icons.add),
                    label: const Text('Add')),
              ]),
              if (_imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (int i = 0; i < _imageUrls.length; i++)
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(_imageUrls[i],
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      width: 84,
                                      height: 84,
                                      color: AppColors.surfaceVariant,
                                      child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: AppColors.textTertiary))),
                            ),
                            Positioned(
                              top: -10,
                              right: -10,
                              child: IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: AppColors.error, size: 20),
                                  onPressed: () =>
                                      setState(() => _imageUrls.removeAt(i))),
                            ),
                            if (i == 0)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  color: AppColors.primary,
                                  child: const Text('MAIN',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // Flags
              Text('Product Tags', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  FilterChip(label: const Text('Featured'), selected: _isFeatured,
                      onSelected: (v) => setState(() => _isFeatured = v), selectedColor: AppColors.primaryContainer),
                  FilterChip(label: const Text('Flash Sale'), selected: _isFlashSale,
                      onSelected: (v) => setState(() => _isFlashSale = v), selectedColor: AppColors.primaryContainer),
                  FilterChip(label: const Text('New Arrival'), selected: _isNewArrival,
                      onSelected: (v) => setState(() => _isNewArrival = v), selectedColor: AppColors.primaryContainer),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
                label: const Text('Save Product'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
