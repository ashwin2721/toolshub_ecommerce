import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';

final adminProductsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/products');
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () {},
            tooltip: 'Import CSV',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {},
            tooltip: 'Export CSV',
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

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: Text('🔧', style: TextStyle(fontSize: 24))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('SKU: ${data['sku'] ?? ""} | Stock: ${data['stockQuantity'] ?? 0}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  Text('₹${(data['price'] as num?)?.toStringAsFixed(0) ?? "0"}',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
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
                                      await dio.put('/products/$productId', data: {'isActive': v});
                                      ref.invalidate(adminProductsProvider);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to update product status: $e'), backgroundColor: AppColors.error),
                                        );
                                      }
                                    }
                                  },
                                  activeThumbColor: AppColors.primary,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                PopupMenuButton<String>(
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                                    const PopupMenuItem(value: 'delete',
                                        child: Text('Delete', style: TextStyle(color: AppColors.error))),
                                  ],
                                  onSelected: (action) {
                                    if (action == 'delete') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Delete Product?'),
                                          content: const Text('This action cannot be undone.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                            ElevatedButton(
                                              onPressed: () async {
                                                try {
                                                  final dio = ref.read(dioProvider);
                                                  await dio.delete('/products/$productId');
                                                  ref.invalidate(adminProductsProvider);
                                                  if (!context.mounted) return;
                                                  Navigator.pop(context);
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Failed to delete product: $e'), backgroundColor: AppColors.error),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
  final _categoryCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final List<String> _imageUrls = [];
  bool _isFeatured = false;
  bool _isFlashSale = false;
  bool _isNewArrival = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountPriceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    _brandCtrl.dispose();
    _imageUrlCtrl.dispose();
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
        'stockQuantity': int.tryParse(_stockCtrl.text) ?? 0,
        'categoryId': _categoryCtrl.text.isNotEmpty ? _categoryCtrl.text : null,
        'brandId': _brandCtrl.text.isNotEmpty ? _brandCtrl.text : null,
        'imageUrls': _imageUrls,
        'isFeatured': _isFeatured,
        'isFlashSale': _isFlashSale,
        'isNewArrival': _isNewArrival,
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
              // Basic Info
              Text('Basic Information', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.inventory_2_outlined)),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _skuCtrl, decoration: const InputDecoration(labelText: 'SKU *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _stockCtrl, decoration: const InputDecoration(labelText: 'Stock *'),
                    keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Price (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _discountPriceCtrl, decoration: const InputDecoration(labelText: 'Discount Price (₹)'),
                    keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _categoryCtrl, decoration: const InputDecoration(labelText: 'Category'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _brandCtrl, decoration: const InputDecoration(labelText: 'Brand'))),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtrl, maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true)),
              const SizedBox(height: 16),
              // Images
              Text('Product Images', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Add one or more image URLs — the first is the main image.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: _imageUrlCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Image URL',
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
