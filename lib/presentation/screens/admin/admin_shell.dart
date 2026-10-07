import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/brand/brand.dart';
import '../../../core/router/app_router.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final _navItems = [
    (AppRoutes.adminDashboard, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (AppRoutes.adminProducts, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Products'),
    (AppRoutes.adminOrders, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
    (AppRoutes.adminCustomers, Icons.people_outline, Icons.people_rounded, 'Customers'),
    (AppRoutes.adminInventory, Icons.warehouse_outlined, Icons.warehouse_rounded, 'Inventory'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: isWide
          ? Row(
              children: [
                // ── Side Nav (Desktop) ──
                Container(
                  width: 220,
                  color: AppColors.secondary,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: BrandColors.accent, borderRadius: BorderRadius.circular(8)),
                              child: Center(child: Icon(Brand.current.markIcon, size: 20, color: BrandColors.onAccent)),
                            ),
                            const SizedBox(width: 10),
                            Text(Brand.current.wordmark, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
                          ],
                        ),
                      ),
                      // Scrollable nav list so more items never overflow the
                      // fixed-height sidebar on shorter viewports.
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: Colors.white24),
                      ),
                      const SizedBox(height: 8),
                      ..._navItems.asMap().entries.map((e) => _SideNavItem(
                        icon: e.value.$2,
                        activeIcon: e.value.$3,
                        label: e.value.$4,
                        isSelected: _selectedIndex == e.key,
                        onTap: () {
                          setState(() => _selectedIndex = e.key);
                          context.go(e.value.$1);
                        },
                      )),
                      const Divider(color: Colors.white24, indent: 16, endIndent: 16),
                      _SideNavItem(
                        icon: Icons.category_outlined,
                        activeIcon: Icons.category_rounded,
                        label: 'Categories',
                        isSelected: false,
                        onTap: () => context.go(AppRoutes.adminCategories),
                      ),
                      _SideNavItem(
                        icon: Icons.tag_outlined,
                        activeIcon: Icons.tag_rounded,
                        label: 'Coupons',
                        isSelected: false,
                        onTap: () => context.go(AppRoutes.adminCoupons),
                      ),
                      _SideNavItem(
                        icon: Icons.image_outlined,
                        activeIcon: Icons.image_rounded,
                        label: 'Banners',
                        isSelected: false,
                        onTap: () => context.go(AppRoutes.adminBanners),
                      ),
                      _SideNavItem(
                        icon: Icons.bar_chart_outlined,
                        activeIcon: Icons.bar_chart_rounded,
                        label: 'Reports',
                        isSelected: false,
                        onTap: () => context.go(AppRoutes.adminReports),
                      ),
                      _SideNavItem(
                        icon: Icons.edit_note_outlined,
                        activeIcon: Icons.edit_note_rounded,
                        label: 'Storefront Content',
                        isSelected: false,
                        onTap: () => context.go(AppRoutes.adminContent),
                      ),
                      _SideNavItem(
                        icon: Icons.local_shipping_outlined,
                        activeIcon: Icons.local_shipping_rounded,
                        label: 'Delivery Fees',
                        isSelected: false,
                        onTap: () => context.go(AppRoutes.adminDelivery),
                      ),
                      _SideNavItem(
                        icon: Icons.reviews_outlined,
                        activeIcon: Icons.reviews_rounded,
                        label: 'Reviews',
                        isSelected: false,
                        onTap: () => context.go(AppRoutes.adminReviews),
                      ),
                          ],
                        ),
                      ),
                      _SideNavItem(
                        icon: Icons.account_circle_outlined,
                        activeIcon: Icons.account_circle_rounded,
                        label: 'My Profile',
                        isSelected: false,
                        onTap: () => context.go(AppRoutes.profile),
                      ),
                      _SideNavItem(
                        icon: Icons.store_outlined,
                        activeIcon: Icons.store_rounded,
                        label: 'Customer App',
                        isSelected: false,
                        onTap: () => context.go(AppRoutes.home),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // ── Content ──
                Expanded(child: widget.child),
              ],
            )
          : widget.child,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) {
                setState(() => _selectedIndex = i);
                context.go(_navItems[i].$1);
              },
              destinations: _navItems.map((item) => NavigationDestination(
                icon: Icon(item.$2),
                selectedIcon: Icon(item.$3),
                label: item.$4,
              )).toList(),
            ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.primaryLight : Colors.white60,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
