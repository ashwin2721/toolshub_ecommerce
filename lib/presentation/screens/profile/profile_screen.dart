import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../orders/order_list_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/responsive.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/store_chrome.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final wishlist = ref.watch(wishlistProvider);

    return StorePage(
      body: MaxWidthContainer(
        verticalPadding: 24,
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return _GuestView();
            }

            final ordersAsync = ref.watch(userOrdersProvider(user.id));

            return Column(
              children: [
                // ── Profile Header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      Text(user.email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            user.role.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),

                // ── Quick Stats ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _StatCard(
                        label: 'Orders',
                        value: ordersAsync.maybeWhen(
                          data: (orders) => orders.length.toString(),
                          orElse: () => '0',
                        ),
                        icon: Icons.receipt_long_outlined,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Wishlist',
                        value: wishlist.length.toString(),
                        icon: Icons.favorite_outline,
                      ),
                      const SizedBox(width: 12),
                      const _StatCard(
                        label: 'Reviews',
                        value: '0',
                        icon: Icons.star_outline,
                      ),
                    ],
                  ),
                ),

                // ── Menu Items ──
                _ProfileSection(
                  title: 'Orders & Shopping',
                  items: [
                    _ProfileMenuItem(
                        icon: Icons.receipt_long_outlined,
                        label: 'My Orders',
                        onTap: () => context.push(AppRoutes.orders)),
                    _ProfileMenuItem(
                        icon: Icons.favorite_outline,
                        label: 'Wishlist',
                        onTap: () => context.push(AppRoutes.wishlist)),
                    _ProfileMenuItem(
                        icon: Icons.compare_arrows_rounded,
                        label: 'Compare Products',
                        onTap: () => context.push(AppRoutes.comparison)),
                  ],
                ),
                _ProfileSection(
                  title: 'Account',
                  items: [
                    _ProfileMenuItem(
                        icon: Icons.location_on_outlined,
                        label: 'Manage Addresses',
                        onTap: () => context.push(AppRoutes.addresses)),
                    _ProfileMenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => context.push(AppRoutes.notifications)),
                    _ProfileMenuItem(
                        icon: Icons.language_outlined,
                        label: 'Language',
                        trailing: const Text('EN',
                            style: TextStyle(color: AppColors.primary)),
                        onTap: () {}),
                    _ProfileMenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => context.push(AppRoutes.settings)),
                  ],
                ),
                _ProfileSection(
                  title: 'Support',
                  items: [
                    _ProfileMenuItem(
                        icon: Icons.support_agent_outlined,
                        label: 'Support Tickets',
                        onTap: () => context.push(AppRoutes.supportTicket)),
                    _ProfileMenuItem(
                        icon: Icons.precision_manufacturing_outlined,
                        label: 'Book Tool Service',
                        onTap: () => context.push(AppRoutes.toolServiceBooking)),
                    _ProfileMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Gemini AI Assistant',
                        onTap: () => context.push(AppRoutes.aiAssistant)),
                    _ProfileMenuItem(
                        icon: Icons.help_outline,
                        label: 'FAQ',
                        onTap: () => context.push(AppRoutes.faq)),
                    _ProfileMenuItem(
                        icon: Icons.info_outline,
                        label: 'About Us',
                        onTap: () => context.push(AppRoutes.about)),
                    _ProfileMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () => context.push(AppRoutes.privacy)),
                    _ProfileMenuItem(
                        icon: Icons.description_outlined,
                        label: 'Terms & Conditions',
                        onTap: () => context.push(AppRoutes.terms)),
                  ],
                ),
                if (user.isAdmin)
                  _ProfileSection(
                    title: 'Admin',
                    items: [
                      _ProfileMenuItem(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Admin Dashboard',
                          onTap: () => context.go(AppRoutes.adminDashboard)),
                    ],
                  ),

                // ── Logout ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _GuestView(),
        ),
      ),
    );
  }
}

class _GuestView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 72),
          const SizedBox(height: 20),
          const Text('TOOLSHUB',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Sign in to access your account'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.login),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Sign In'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48)),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.register),
            child: const Text('Create Account'),
          ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileMenuItem> items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                final item = items[i];
                return Column(
                  children: [
                    item,
                    if (i < items.length - 1)
                      const Divider(height: 1, indent: 52),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
