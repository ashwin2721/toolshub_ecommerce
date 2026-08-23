import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/common/store_chrome.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/product/product_card.dart';


// ── Wishlist Screen ────────────────────────────────────────────────────────────
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final items = wishlist.take(20).toList();
    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wishlist (${wishlist.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            if (wishlist.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: EmptyStateWidget(
                  icon: Icons.favorite_outline,
                  title: 'Your wishlist is empty',
                  subtitle: 'Save products you love and come back later',
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.productGridColumns,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.66,
                ),
                itemBuilder: (_, i) {
                  final id = items[i];
                  return Consumer(
                    builder: (_, ref, __) {
                      final async = ref.watch(productDetailProvider(id));
                      return async.maybeWhen(
                        data: (p) => p != null
                            ? ProductCard(product: p, gridView: true)
                            : const SizedBox.shrink(),
                        orElse: () => const ShimmerBox(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 16,
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Address Screen ─────────────────────────────────────────────────────────────
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  bool _isLoading = false;

  Future<void> _showAddAddressSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    String selectedType = 'home';
    bool isDefault = false;
    bool locating = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Add New Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                // Address Type Selector
                const Text('Address Type',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TypeChip(
                      label: 'Home',
                      icon: Icons.home_outlined,
                      selected: selectedType == 'home',
                      onTap: () => setSheetState(() => selectedType = 'home'),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: 'Work',
                      icon: Icons.work_outline,
                      selected: selectedType == 'work',
                      onTap: () => setSheetState(() => selectedType = 'work'),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: 'Other',
                      icon: Icons.place_outlined,
                      selected: selectedType == 'other',
                      onTap: () => setSheetState(() => selectedType = 'other'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Detect current location → auto-fills street / city / state / PIN.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: locating
                        ? null
                        : () async {
                            setSheetState(() => locating = true);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final addr = await resolveCurrentAddress(
                                  ref.read(dioProvider));
                              if (addr.street.isNotEmpty) {
                                streetCtrl.text = addr.street;
                              }
                              if (addr.city.isNotEmpty) cityCtrl.text = addr.city;
                              if (addr.state.isNotEmpty) {
                                stateCtrl.text = addr.state;
                              }
                              if (addr.pinCode.isNotEmpty) {
                                pinCtrl.text = addr.pinCode;
                              }
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Location detected — address filled in.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e
                                      .toString()
                                      .replaceFirst('Exception: ', '')),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            } finally {
                              setSheetState(() => locating = false);
                            }
                          },
                    icon: locating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(locating
                        ? 'Detecting location…'
                        : 'Use my current location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: nameCtrl,
                  label: 'Full Name',
                  hint: 'John Doe',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: phoneCtrl,
                  label: 'Phone Number',
                  hint: '+91 9876543210',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: streetCtrl,
                  label: 'Street Address',
                  hint: 'Flat/House No, Building, Street, Area',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: cityCtrl,
                        label: 'City',
                        hint: 'City',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: pinCtrl,
                        label: 'PIN Code',
                        hint: '110001',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: stateCtrl,
                  label: 'State',
                  hint: 'State',
                  prefixIcon: Icons.map_outlined,
                ),
                const SizedBox(height: 16),

                // Set as default toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Set as default address',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Switch.adaptive(
                        value: isDefault,
                        onChanged: (v) => setSheetState(() => isDefault = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (nameCtrl.text.isEmpty ||
                          phoneCtrl.text.isEmpty ||
                          streetCtrl.text.isEmpty ||
                          cityCtrl.text.isEmpty ||
                          stateCtrl.text.isEmpty ||
                          pinCtrl.text.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all fields'),
                              backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      try {
                        final dio = ref.read(dioProvider);
                        await dio.post('/auth/addresses', data: {
                          'type': selectedType,
                          'fullName': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'street': streetCtrl.text.trim(),
                          'city': cityCtrl.text.trim(),
                          'state': stateCtrl.text.trim(),
                          'pinCode': pinCtrl.text.trim(),
                          'isDefault': isDefault,
                        });
                        ref.invalidate(authNotifierProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Address saved successfully!'),
                              backgroundColor: AppColors.success),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text('Failed to add address: $e'),
                              backgroundColor: AppColors.error),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Address'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAddress(String addressId) async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/auth/addresses/$addressId');
      ref.invalidate(authNotifierProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Address removed'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefault(String addressId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/auth/addresses/$addressId/default');
      ref.invalidate(authNotifierProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final addresses = user?.addresses ?? [];
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
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text('My Addresses',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () => _showAddAddressSheet(context),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add Address'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (addresses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: EmptyStateWidget(
                  icon: Icons.location_on_outlined,
                  title: 'No addresses saved',
                  subtitle: 'Add a delivery address to speed up checkout',
                ),
              )
            else
              Column(
                children: [
                  for (final addr in addresses)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: addr.isDefault
                              ? AppColors.primary
                              : AppColors.border,
                          width: addr.isDefault ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: addr.isDefault
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : AppColors.border.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  addr.type == 'work'
                                      ? Icons.work_outline
                                      : addr.type == 'other'
                                          ? Icons.place_outlined
                                          : Icons.home_outlined,
                                  color: addr.isDefault
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          addr.type.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: addr.isDefault
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (addr.isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.star_rounded,
                                                    size: 11,
                                                    color: AppColors.primary),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Default',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      addr.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded,
                                    color: AppColors.textSecondary, size: 20),
                                onSelected: (val) {
                                  if (val == 'default') _setDefault(addr.id);
                                  if (val == 'delete') _deleteAddress(addr.id);
                                },
                                itemBuilder: (_) => [
                                  if (!addr.isDefault)
                                    const PopupMenuItem(
                                      value: 'default',
                                      child: Row(
                                        children: [
                                          Icon(Icons.star_outline,
                                              size: 18,
                                              color: AppColors.primary),
                                          SizedBox(width: 8),
                                          Text('Set as Default'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            size: 18, color: AppColors.error),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style: TextStyle(
                                                color: AppColors.error)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  addr.formatted,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                addr.phone,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings Screen ────────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotif = true;
  bool _emailNotif = true;
  bool _smsNotif = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotif = prefs.getBool('notif_push') ?? true;
      _emailNotif = prefs.getBool('notif_email') ?? true;
      _smsNotif = prefs.getBool('notif_sms') ?? false;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
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
            const SizedBox(height: 4),
            Text('Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              trailing: DropdownButton<String>(
                value: lang,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                ],
                onChanged: (v) =>
                    ref.read(languageProvider.notifier).setLanguage(v ?? 'en'),
                underline: const SizedBox.shrink(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Push Notifications'),
              trailing: Switch(
                value: _pushNotif,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _pushNotif = v);
                  _setPref('notif_push', v);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Notifications'),
              trailing: Switch(
                value: _emailNotif,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _emailNotif = v);
                  _setPref('notif_email', v);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sms_outlined),
              title: const Text('SMS Notifications'),
              trailing: Switch(
                value: _smsNotif,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _smsNotif = v);
                  _setPref('notif_sms', v);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
              title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text(
                        'Are you sure you want to delete your account? This action is permanent and cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                try {
                  await ref.read(dioProvider).delete('/auth/account');
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to delete account: $e'),
                          backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Notifications Screen ───────────────────────────────────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 4),
            Text('Notifications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            for (int i = 0; i < 5; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: i == 0 ? AppColors.primaryContainer : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: i == 0 ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your order has been shipped!',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Order #TH${1000 + i} is on the way',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('${2 + i}h ago', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (i == 0) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
