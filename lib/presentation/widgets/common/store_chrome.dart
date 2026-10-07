import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/brand/brand.dart';
import '../../../core/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/app_provider.dart';
import 'app_logo.dart';

/// Shopcart-style storefront page: dark announcement bar + white web header,
/// then the scrollable [body], then the footer. Responsive — the header
/// collapses to a compact version on mobile.
class StorePage extends StatelessWidget {
  final Widget body;
  final bool showFooter;
  final Future<void> Function()? onRefresh;

  // Footer shows only where explicitly enabled (the Home page). Every other
  // page — search, cart, profile and its sub-pages, admin, etc. — omits it.
  const StorePage({
    super.key,
    required this.body,
    this.showFooter = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget scrollable = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          if (showFooter) const StoreFooter(),
        ],
      ),
    );

    if (onRefresh != null) {
      scrollable = RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: onRefresh!,
        child: scrollable,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const StoreAnnouncementBar(),
          const StoreHeader(),
          Expanded(child: scrollable),
        ],
      ),
    );
  }
}

// ── Top announcement bar (dark) ──────────────────────────────────────────────
class StoreAnnouncementBar extends ConsumerWidget {
  const StoreAnnouncementBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(storeSettingsProvider).valueOrNull ?? const <String, dynamic>{};
    final t = (settings['announcementText'] as String?)?.trim();
    final c = (settings['announcementCtaLabel'] as String?)?.trim();
    final announcement =
        (t == null || t.isEmpty) ? Brand.current.copy.announcementFallback : t;
    final ctaLabel = (c == null || c.isEmpty) ? 'Shop Now' : c;
    return Container(
      width: double.infinity,
      color: BrandColors.accent,
      child: MaxWidthContainer(
        verticalPadding: 9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // onAccent, not a hardcoded white: a light brand accent
                  // (ToolsHub amber) needs dark text to stay legible.
                  Text('$announcement   ',
                      style: TextStyle(
                          color: BrandColors.onAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.productList),
                    child: Text(ctaLabel,
                        style: TextStyle(
                            color: BrandColors.onAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main white header (logo · nav · search · account · cart) ─────────────────
class StoreHeader extends ConsumerWidget {
  const StoreHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Collapse the full nav + search bar to a compact header on anything
    // narrower than desktop (covers the tablet range so it never overflows).
    final compact = !context.isDesktop;
    final cartCount = ref.watch(cartItemCountProvider);
    final compareCount = ref.watch(comparisonProvider).length;
    final user = ref.watch(currentUserProvider).valueOrNull;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: MaxWidthContainer(
        verticalPadding: 12,
        // Column so the compact (mobile/tablet) header can add a full-width
        // inline search row beneath the logo/actions row.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Logo
                GestureDetector(
                  onTap: () => context.go(AppRoutes.home),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 34),
                      const SizedBox(width: 8),
                      Text(Brand.current.wordmark,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: 1,
                              )),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 36),
                  const _CategoriesNavLink(),
                  _NavLink(
                      label: 'Deals',
                      onTap: () => context.go(Uri(
                          path: AppRoutes.productList,
                          queryParameters: {'deals': 'true'}).toString())),
                  _NavLink(
                      label: "What's New",
                      onTap: () => context.go(AppRoutes.whatsNew)),
                ],
                const Spacer(),
                // Desktop keeps the inline live-search inside the header row.
                // On mobile it moves to its own full-width row below, so the
                // navigate-away search icon is no longer needed.
                if (!compact) ...[
                  const SizedBox(
                    width: 260,
                    child: _HeaderSearch(),
                  ),
                  const SizedBox(width: 6),
                ],
                // Compare shortcut — appears once products are added to comparison.
                if (compareCount > 0) ...[
                  _HeaderAction(
                    icon: Icons.compare_arrows_rounded,
                    label: 'Compare',
                    showLabel: !compact,
                    badgeCount: compareCount,
                    onTap: () => context.push(AppRoutes.comparison),
                  ),
                  const SizedBox(width: 4),
                ],
                _HeaderAction(
                  icon: Icons.person_outline_rounded,
                  label: user != null ? 'Account' : 'Sign In',
                  showLabel: !compact,
                  onTap: () => context.go(AppRoutes.profile),
                ),
                const SizedBox(width: 4),
                _HeaderAction(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Cart',
                  showLabel: !compact,
                  badgeCount: cartCount,
                  onTap: () => context.go(AppRoutes.cart),
                ),
              ],
            ),
            // Mobile/tablet: same inline live-search dropdown as desktop,
            // full-width beneath the header row, instead of routing away to
            // a separate /search page.
            if (compact) ...[
              const SizedBox(height: 10),
              const _HeaderSearch(),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// Categories nav item → a dropdown of live categories, each filtering products.
class _CategoriesNavLink extends ConsumerWidget {
  const _CategoriesNavLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return PopupMenuButton<String>(
      tooltip: 'Categories',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (id) {
        if (id == '__all__') {
          context.go(AppRoutes.productList);
        } else {
          context.go(Uri(
              path: AppRoutes.productList,
              queryParameters: {'category': id}).toString());
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem(value: '__all__', child: Text('All Products')),
        ];
        categoriesAsync.whenData((cats) {
          for (final c in cats) {
            items.add(PopupMenuItem(value: c.id, child: Text(c.name)));
          }
        });
        return items;
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Categories',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class _HeaderSearch extends ConsumerStatefulWidget {
  const _HeaderSearch();
  @override
  ConsumerState<_HeaderSearch> createState() => _HeaderSearchState();
}

class _HeaderSearchState extends ConsumerState<_HeaderSearch> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _menu = OverlayPortalController();
  final _link = LayerLink();
  final _groupId = Object();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _query = v.trim());
    if (_query.length >= 2) {
      if (!_menu.isShowing) _menu.show();
    } else if (_menu.isShowing) {
      _menu.hide();
    }
  }

  void _submit(String v) {
    final q = v.trim();
    if (_menu.isShowing) _menu.hide();
    _focusNode.unfocus();
    if (q.isNotEmpty) {
      context.go(
          Uri(path: AppRoutes.search, queryParameters: {'query': q}).toString());
    }
  }

  void _openProduct(String id) {
    if (_menu.isShowing) _menu.hide();
    _focusNode.unfocus();
    context.go('/product/$id');
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _groupId,
      onTapOutside: (_) {
        if (_menu.isShowing) _menu.hide();
      },
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _menu,
          overlayChildBuilder: (context) => _overlay(),
          child: _field(),
        ),
      ),
    );
  }

  Widget _field() {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              onSubmitted: _submit,
              onTap: () {
                if (_query.length >= 2 && !_menu.isShowing) _menu.show();
              },
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: 'Search Product',
                hintStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _submit(_controller.text),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child:
                    Icon(Icons.search_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlay() {
    // Cap the dropdown at 340 (desktop) but shrink to fit narrow phones so it
    // never spills past the screen edge.
    final available = MediaQuery.sizeOf(context).width - 32;
    final overlayWidth = available < 340 ? available : 340.0;
    return TapRegion(
      groupId: _groupId,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: overlayWidth,
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: Consumer(
                builder: (context, ref, _) {
                  if (_query.length < 2) return const SizedBox.shrink();
                  final async = ref.watch(searchResultsProvider(_query));
                  return async.when(
                    data: (products) {
                      if (products.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text('No matches found',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        );
                      }
                      final top = products.take(6).toList();
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final p in top) _tile(p),
                            InkWell(
                              onTap: () => _submit(_query),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: AppColors.divider)),
                                ),
                                child: Text('See all results for "$_query"',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(22),
                      child: Center(
                          child: SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    ),
                    error: (_, __) => const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('Search failed',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(ProductEntity p) {
    return InkWell(
      onTap: () => _openProduct(p.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 42,
                height: 42,
                color: AppColors.productImageBg,
                child: p.primaryImage != null
                    ? CachedNetworkImage(
                        imageUrl: p.primaryImage!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.handyman_outlined,
                            size: 18,
                            color: AppColors.textTertiary),
                      )
                    : const Icon(Icons.handyman_outlined,
                        size: 18, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(p.brandName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('₹${p.effectivePrice.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showLabel;
  final int badgeCount;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showLabel = true,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, size: 24, color: AppColors.textPrimary);
    if (badgeCount > 0) {
      iconWidget = badges.Badge(
        badgeContent: Text(
          badgeCount > 99 ? '99+' : badgeCount.toString(),
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
        ),
        badgeStyle: const badges.BadgeStyle(
            badgeColor: AppColors.primary, padding: EdgeInsets.all(5)),
        child: iconWidget,
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Footer ───────────────────────────────────────────────────────────────────
class StoreFooter extends StatelessWidget {
  const StoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = context.isMobile;
    final columns = <Widget>[
      _footerBrand(),
      _footerCol('Shop', Brand.current.copy.footerShopLinks),
      _footerCol('Support', const ['Contact Us', 'FAQ', 'Support Ticket', 'Delivery']),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: MaxWidthContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final c in columns) ...[
                        c,
                        const SizedBox(height: 28),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: columns[0]),
                      Expanded(child: columns[1]),
                      Expanded(child: columns[2]),
                    ],
                  ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(Brand.current.copyrightLine(DateTime.now().year),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Text('v1.0.1',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 34, white: true),
            const SizedBox(width: 8),
            Text(Brand.current.wordmark,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 260,
          child: Text(
            Brand.current.copy.footerBlurb,
            style: const TextStyle(
                color: Colors.white60, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _footerCol(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        const SizedBox(height: 14),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(item,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ),
      ],
    );
  }
}
