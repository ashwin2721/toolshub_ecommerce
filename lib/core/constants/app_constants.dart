class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'TOOLSHUB';
  static const String appTagline = 'Professional Tools & Hardware Store';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API Endpoints (placeholder - replace with real values)
  static const String baseUrl = 'https://api.toolshub.com/v1';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String subcategoriesCollection = 'subcategories';
  static const String brandsCollection = 'brands';
  static const String ordersCollection = 'orders';
  static const String orderItemsCollection = 'order_items';
  static const String cartCollection = 'cart';
  static const String wishlistCollection = 'wishlist';
  static const String couponsCollection = 'coupons';
  static const String reviewsCollection = 'reviews';
  static const String ratingsCollection = 'ratings';
  static const String notificationsCollection = 'notifications';
  static const String inventoryCollection = 'inventory';
  static const String suppliersCollection = 'suppliers';
  static const String bannersCollection = 'banners';
  static const String settingsCollection = 'settings';
  static const String supportTicketsCollection = 'support_tickets';
  static const String reportsCollection = 'reports';
  static const String analyticsCollection = 'analytics';

  // Storage Paths
  static const String productsStoragePath = 'products';
  static const String usersStoragePath = 'users';
  static const String bannersStoragePath = 'banners';
  static const String categoriesStoragePath = 'categories';

  // Payment Keys (PLACEHOLDER - replace with real keys)
  static const String razorpayKeyId = 'rzp_test_PLACEHOLDER';
  static const String stripePublishableKey = 'pk_test_PLACEHOLDER';
  static const String paypalClientId = 'PAYPAL_CLIENT_ID_PLACEHOLDER';

  // Pagination
  static const int defaultPageSize = 20;
  static const int searchPageSize = 15;
  static const int ordersPageSize = 10;

  // Image
  static const String placeholderImageUrl =
      'https://placehold.co/400x400/F3F4F6/9CA3AF?text=TOOLSHUB';
  static const String productPlaceholderUrl =
      'https://placehold.co/600x600/F3F4F6/9CA3AF?text=Product';

  // Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration slowAnimation = Duration(milliseconds: 600);
  static const Duration carouselAutoPlay = Duration(seconds: 4);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration cacheExpiry = Duration(hours: 1);

  // Sizes
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 20.0;
  static const double smallBorderRadius = 8.0;
  static const double cardElevation = 2.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Product
  static const int maxCartQuantity = 10;
  static const int maxImagesPerProduct = 10;
  static const double maxProductWeight = 999.99;

  // Limits
  static const int maxWishlistItems = 100;
  static const int maxAddresses = 5;
  static const int maxSupportTickets = 10;
  static const int maxReviewLength = 1000;
  static const int maxSearchHistory = 20;

  // GST
  static const double defaultGstRate = 18.0;
  static const String gstNumber = 'GSTIN_PLACEHOLDER';
  static const String companyName = 'TOOLSHUB Technologies Pvt. Ltd.';
  static const String companyAddress = '123, Industrial Area, Mumbai - 400001';

  // Shipping — free over this cart subtotal, else a flat delivery fee applies.
  // Tools are high-ticket, so keep the threshold high enough that free
  // shipping is a real incentive rather than something every order clears.
  static const double freeShippingThreshold = 4999.0;
  static const double standardShippingFee = 99.0;
  static const double expressShippingFee = 199.0;

  // Order Statuses
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusProcessing = 'processing';
  static const String statusPacked = 'packed';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';
  static const String statusReturned = 'returned';
  static const String statusRefunded = 'refunded';

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleAdmin = 'admin';
  static const String roleStaffManager = 'staff_manager';
  static const String roleInventoryManager = 'inventory_manager';

  // Payment Methods
  static const String paymentRazorpay = 'razorpay';
  static const String paymentStripe = 'stripe';
  static const String paymentPaypal = 'paypal';
  static const String paymentUpi = 'upi';
  static const String paymentCreditCard = 'credit_card';
  static const String paymentDebitCard = 'debit_card';
  static const String paymentNetBanking = 'net_banking';
  static const String paymentCod = 'cod';

  // Category IDs
  static const String catPowerTools = 'power_tools';
  static const String catHandTools = 'hand_tools';
  static const String catMeasuringTools = 'measuring_tools';
  static const String catElectricalTools = 'electrical_tools';
  static const String catSafetyEquipment = 'safety_equipment';
  static const String catWeldingEquipment = 'welding_equipment';
  static const String catPlumbingTools = 'plumbing_tools';
  static const String catGardeningTools = 'gardening_tools';
  static const String catToolStorage = 'tool_storage';
  static const String catIndustrialEquipment = 'industrial_equipment';

  // Hive Boxes
  static const String hiveCart = 'cart_box';
  static const String hiveWishlist = 'wishlist_box';
  static const String hiveSearchHistory = 'search_history_box';
  static const String hiveSettings = 'settings_box';
  static const String hiveRecentlyViewed = 'recently_viewed_box';
  static const String hiveProducts = 'products_cache_box';

  // SharedPrefs Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language_code';
  static const String prefOnboarding = 'onboarding_done';
  static const String prefUserId = 'user_id';
  static const String prefFcmToken = 'fcm_token';
}
