import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Admin editor for storefront copy (promo announcement bar + homepage hero).
/// Renders inside the AdminShell. Saves to PUT /api/settings.
class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen> {
  final _announcement = TextEditingController();
  final _announcementCta = TextEditingController();
  final _heroTitle = TextEditingController();
  final _heroSubtitle = TextEditingController();
  final _heroCta = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/settings');
      final s = Map<String, dynamic>.from(res.data);
      _announcement.text = s['announcementText'] ?? '';
      _announcementCta.text = s['announcementCtaLabel'] ?? '';
      _heroTitle.text = s['heroTitle'] ?? '';
      _heroSubtitle.text = s['heroSubtitle'] ?? '';
      _heroCta.text = s['heroCtaLabel'] ?? '';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/settings', data: {
        'announcementText': _announcement.text.trim(),
        'announcementCtaLabel': _announcementCta.text.trim(),
        'heroTitle': _heroTitle.text.trim(),
        'heroSubtitle': _heroSubtitle.text.trim(),
        'heroCtaLabel': _heroCta.text.trim(),
      });
      ref.invalidate(storeSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Storefront content updated!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _announcement.dispose();
    _announcementCta.dispose();
    _heroTitle.dispose();
    _heroSubtitle.dispose();
    _heroCta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Storefront Content',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                  'Edit the promo bar and homepage hero text shown to customers.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              _section('Announcement Bar'),
              _field('Announcement text', _announcement),
              _field('Announcement button label', _announcementCta),
              const SizedBox(height: 20),
              _section('Homepage Hero'),
              _field('Hero title', _heroTitle, maxLines: 2),
              _field('Hero subtitle', _heroSubtitle),
              _field('Hero button label', _heroCta),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      );

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
