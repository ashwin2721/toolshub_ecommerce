import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../providers/cart_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _tabs = [
    AppRoutes.home,
    AppRoutes.search,
    AppRoutes.cart,
    AppRoutes.profile,
  ];

  // Derive the selected tab from the active route so the highlighted tab
  // always matches wherever the router currently is (deep links, back
  // navigation, or programmatic `context.go` from anywhere in the app).
  int _locationToIndex(String location) {
    // Skip index 0 (home '/') since every path starts with '/'; fall back
    // to it when nothing more specific matches.
    for (var i = _tabs.length - 1; i >= 1; i--) {
      if (location == _tabs[i] || location.startsWith('${_tabs[i]}/')) {
        return i;
      }
    }
    return 0;
  }

  void _onTap(int index) {
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemCountProvider);
    final currentIndex =
        _locationToIndex(GoRouterState.of(context).uri.path);

    return Scaffold(
      body: widget.child,
      // Bottom nav is a mobile-only affordance; on desktop/web the top header
      // provides navigation, so hide it there.
      bottomNavigationBar: !context.isMobile
          ? null
          : Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: _onTap,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            NavigationDestination(
              icon: badges.Badge(
                badgeContent: Text(
                  cartCount > 99 ? '99+' : cartCount.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
                showBadge: cartCount > 0,
                badgeStyle: const badges.BadgeStyle(
                    badgeColor: AppColors.primary, padding: EdgeInsets.all(4)),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: badges.Badge(
                badgeContent: Text(
                  cartCount > 99 ? '99+' : cartCount.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
                showBadge: cartCount > 0,
                badgeStyle: const badges.BadgeStyle(
                    badgeColor: AppColors.primary, padding: EdgeInsets.all(4)),
                child: const Icon(Icons.shopping_cart_rounded),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
