import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_upload_helper.dart';

/// Loads every category (admin-only) from `GET /api/categories/admin`,
/// including hidden ones so they can be seen and re-enabled.
final adminCategoriesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/categories/admin');
  return response.data as List<dynamic>;
});

/// Pulls the friendly message out of a failed admin request. The API answers
/// with `{ error: '...' }`, which reads far better than Dio's own text.
String categoryErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) return data['error'].toString();
  }
  return error.toString().replaceFirst('Exception: ', '');
}

/// Opens the add/edit category form. Returns the saved category's id, or null
/// if it was cancelled. Shared with the Add Product form, so a missing category
/// can be created without abandoning a half-filled product.
Future<String?> showCategoryFormDialog(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? existing,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CategoryFormDialog(existing: existing),
  );
}

/// Admin screen for managing storefront categories. Renders inside AdminShell.
class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  Future<void> _patch(
    BuildContext context,
    WidgetRef ref,
    String id,
    Map<String, dynamic> body,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(dioProvider).patch('/categories/$id', data: body);
      ref.invalidate(adminCategoriesProvider);
      // The storefront grid and the product form's dropdown read this one.
      ref.invalidate(categoriesProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(categoryErrorMessage(e)),
          backgroundColor: AppColors.error));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> cat,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
            '"${cat['name']}" will be removed. This cannot be undone.\n\n'
            'Products already filed under it must be moved first.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(dioProvider).delete('/categories/${cat['id']}');
      ref.invalidate(adminCategoriesProvider);
      ref.invalidate(categoriesProvider);
      messenger.showSnackBar(const SnackBar(
          content: Text('Category deleted'),
          backgroundColor: AppColors.success));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(categoryErrorMessage(e)),
          backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminCategoriesProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryFormDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load categories: ${categoryErrorMessage(err)}',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(adminCategoriesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.category_outlined,
                        size: 56, color: AppColors.textTertiary),
                    const SizedBox(height: 16),
                    const Text('No categories yet',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      'Add your first category — products are filed under '
                      'these, and they drive the storefront category row.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => showCategoryFormDialog(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Category'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminCategoriesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final cat = Map<String, dynamic>.from(docs[i] as Map);
                final isActive = cat['isActive'] ?? true;
                final count = (cat['productCount'] as num?)?.toInt() ?? 0;
                final imageUrl = (cat['imageUrl'] ?? '').toString();

                return Opacity(
                  opacity: isActive ? 1.0 : 0.55,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      leading: _CategoryThumb(imageUrl: imageUrl),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(cat['name'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Hidden',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${cat['slug'] ?? ''} • $count '
                        'product${count == 1 ? '' : 's'} • #${cat['sortOrder'] ?? 0}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            activeThumbColor: AppColors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => _patch(
                                context, ref, cat['id'], {'isActive': v}),
                          ),
                          PopupMenuButton<String>(
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete',
                                      style:
                                          TextStyle(color: AppColors.error))),
                            ],
                            onSelected: (action) {
                              if (action == 'edit') {
                                showCategoryFormDialog(context, ref,
                                    existing: cat);
                              } else if (action == 'delete') {
                                _confirmDelete(context, ref, cat);
                              }
                            },
                          ),
                        ],
                      ),
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
}

class _CategoryThumb extends StatelessWidget {
  final String imageUrl;
  const _CategoryThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const placeholder = Icon(Icons.category_outlined, color: AppColors.primary);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        height: 52,
        color: AppColors.primaryContainer,
        child: imageUrl.isEmpty
            ? const Center(child: placeholder)
            : Image.network(imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: placeholder)),
      ),
    );
  }
}

/// Add/edit form for a single category. Pops the saved category's id.
class _CategoryFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  const _CategoryFormDialog({this.existing});

  @override
  ConsumerState<_CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _sortCtrl;
  bool _saving = false;
  bool _uploading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: (e?['name'] ?? '').toString());
    _descCtrl =
        TextEditingController(text: (e?['description'] ?? '').toString());
    _imageCtrl = TextEditingController(text: (e?['imageUrl'] ?? '').toString());
    _sortCtrl = TextEditingController(text: (e?['sortOrder'] ?? '').toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadImage();
      if (url != null && mounted) setState(() => _imageCtrl.text = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(categoryErrorMessage(e)),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'imageUrl': _imageCtrl.text.trim(),
      if (_sortCtrl.text.trim().isNotEmpty)
        'sortOrder': int.tryParse(_sortCtrl.text.trim()),
    };

    try {
      final dio = ref.read(dioProvider);
      String id;
      if (_isEdit) {
        id = widget.existing!['id'].toString();
        await dio.patch('/categories/$id', data: body);
      } else {
        final res = await dio.post('/categories', data: body);
        id = (res.data['id'] ?? '').toString();
      }

      ref.invalidate(adminCategoriesProvider);
      ref.invalidate(categoriesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Category updated' : 'Category added'),
          backgroundColor: AppColors.success));
      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(categoryErrorMessage(e)),
          backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageCtrl.text.trim();

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Category' : 'Add Category'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      prefixIcon: Icon(Icons.category_outlined),
                      hintText: 'e.g. Power Tools'),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description', alignLabelWithHint: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Sort order',
                      helperText: 'Lower numbers show first. Blank = last.'),
                ),
                const SizedBox(height: 16),
                const Text('Category Image',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _CategoryThumb(imageUrl: imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploading ? null : _upload,
                        icon: _uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload_rounded, size: 18),
                        label: Text(
                            _uploading ? 'Uploading…' : 'Upload from device'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _imageCtrl,
                  decoration: const InputDecoration(
                      labelText: 'or paste an Image URL',
                      prefixIcon: Icon(Icons.link_rounded),
                      hintText: 'https://...'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? 'Save' : 'Add Category'),
        ),
      ],
    );
  }
}
