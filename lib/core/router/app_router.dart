import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/main_shell.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/product/product_list_screen.dart';
import '../../presentation/screens/product/product_detail_screen.dart';
import '../../presentation/screens/home/whats_new_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/checkout/checkout_screen.dart';
import '../../presentation/screens/checkout/order_confirmation_screen.dart';
import '../../presentation/screens/orders/order_list_screen.dart';
import '../../presentation/screens/orders/order_detail_screen.dart';
import '../../presentation/screens/orders/order_tracking_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/address_screen.dart';
import '../../presentation/screens/extra/product_comparison_screen.dart';
import '../../presentation/screens/extra/tool_service_booking_screen.dart';
import '../../presentation/screens/extra/gemini_assistant_screen.dart';
import '../../presentation/screens/admin/admin_shell.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_products_screen.dart';
import '../../presentation/screens/admin/admin_orders_screen.dart';
import '../../presentation/screens/admin/admin_content_screen.dart';
import '../../presentation/screens/admin/admin_delivery_screen.dart';
import '../../presentation/providers/auth_provider.dart';

class AppRoutes {
  AppRoutes._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main App
  static const String home = '/';
  static const String productList = '/products';
  static const String whatsNew = '/whats-new';
  static const String productDetail = '/product/:id';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation/:orderId';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String orderTracking = '/orders/:id/tracking';
  static const String profile = '/profile';
  static const String addresses = '/profile/addresses';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // Extra
  static const String comparison = '/comparison';
  static const String supportTicket = '/support';
  static const String faq = '/faq';
  static const String contact = '/contact';
  static const String about = '/about';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String toolServiceBooking = '/support/tool-service';
  static const String aiAssistant = '/support/ai-assistant';

  // Admin
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminAddProduct = '/admin/products/add';
  static const String adminOrders = '/admin/orders';
  static const String adminCustomers = '/admin/customers';
  static const String adminInventory = '/admin/inventory';
  static const String adminCoupons = '/admin/coupons';
  static const String adminBanners = '/admin/banners';
  static const String adminReports = '/admin/reports';
  static const String adminContent = '/admin/content';
  static const String adminDelivery = '/admin/delivery';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // ── Auth Routes ──
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.register, builder: (c, s) => const RegisterScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (c, s) => const ForgotPasswordScreen()),

      // ── Main Shell (Bottom Nav) ──
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (c, s) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (c, s) =>
                SearchScreen(initialQuery: s.uri.queryParameters['query']),
          ),
          GoRoute(
            path: AppRoutes.cart,
            builder: (c, s) => const CartScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (c, s) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Products ──
      GoRoute(
        path: AppRoutes.productList,
        builder: (c, s) => ProductListScreen(
          categoryId: s.uri.queryParameters['category'],
          brandId: s.uri.queryParameters['brand'],
          query: s.uri.queryParameters['q'],
          deals: s.uri.queryParameters['deals'] == 'true',
        ),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (c, s) => ProductDetailScreen(productId: s.pathParameters['id']!),
      ),
      GoRoute(
          path: AppRoutes.whatsNew, builder: (c, s) => const WhatsNewScreen()),

      // ── Cart & Wishlist ──
      GoRoute(path: AppRoutes.wishlist, builder: (c, s) => const WishlistScreen()),
      GoRoute(
        path: AppRoutes.checkout,
        // Guests may build a cart freely, but must sign in before checking out.
        // This guard protects every entry into checkout (cart button, Buy Now,
        // deep links) in one place. After login the user is returned here.
        redirect: (context, state) {
          final loggedIn = ref.read(currentUserProvider).valueOrNull != null;
          if (!loggedIn) {
            return '${AppRoutes.login}?redirect=${Uri.encodeComponent(AppRoutes.checkout)}';
          }
          return null;
        },
        builder: (c, s) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-confirmation/:orderId',
        builder: (c, s) =>
            OrderConfirmationScreen(orderId: s.pathParameters['orderId']!),
      ),

      // ── Orders ──
      GoRoute(path: AppRoutes.orders, builder: (c, s) => const OrderListScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (c, s) =>
            OrderDetailScreen(orderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/tracking',
        builder: (c, s) =>
            OrderTrackingScreen(orderId: s.pathParameters['id']!),
      ),

      // ── Profile ──
      GoRoute(
          path: AppRoutes.addresses, builder: (c, s) => const AddressScreen()),
      GoRoute(
          path: AppRoutes.settings, builder: (c, s) => const SettingsScreen()),
      GoRoute(
          path: AppRoutes.notifications,
          builder: (c, s) => const NotificationsScreen()),

      // ── Extra ──
      GoRoute(
          path: AppRoutes.comparison,
          builder: (c, s) => const ProductComparisonScreen()),
      GoRoute(
          path: AppRoutes.supportTicket,
          builder: (c, s) => const SupportTicketScreen()),
      GoRoute(
          path: AppRoutes.toolServiceBooking,
          builder: (c, s) => const ToolServiceBookingScreen()),
      GoRoute(
          path: AppRoutes.aiAssistant,
          builder: (c, s) => const GeminiAssistantScreen()),
      GoRoute(path: AppRoutes.faq, builder: (c, s) => const FaqScreen()),
      GoRoute(
          path: AppRoutes.contact, builder: (c, s) => const ContactScreen()),
      GoRoute(path: AppRoutes.about, builder: (c, s) => const AboutScreen()),
      GoRoute(
          path: AppRoutes.privacy,
          builder: (c, s) => const PrivacyPolicyScreen()),
      GoRoute(path: AppRoutes.terms, builder: (c, s) => const TermsScreen()),

      // ── Admin Shell ──
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            builder: (c, s) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminProducts,
            builder: (c, s) => const AdminProductsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminAddProduct,
            builder: (c, s) => const AdminAddProductScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminOrders,
            builder: (c, s) => const AdminOrdersScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminCustomers,
            builder: (c, s) => const AdminCustomersScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminInventory,
            builder: (c, s) => const AdminInventoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminCoupons,
            builder: (c, s) => const AdminCouponsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminBanners,
            builder: (c, s) => const AdminBannersScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminReports,
            builder: (c, s) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminContent,
            builder: (c, s) => const AdminContentScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminDelivery,
            builder: (c, s) => const AdminDeliveryScreen(),
          ),
        ],
      ),
    ],
  );
});
