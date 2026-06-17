class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  
  // Shell Tab Routes
  static const String home = '/';
  static const String categories = '/categories';
  static const String wishlist = '/wishlist';
  static const String cart = '/cart';
  static const String profile = '/profile';

  // Secondary standalone pages
  static const String products = '/products';
  static const String productDetail = '/product/:id';
  static const String search = '/search';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String myOrders = '/my-orders';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String helpCenter = '/help-center';
  static const String legalPolicies = '/legal-policies';

  // Direct dynamic path helpers
  static String getProductDetailRoute(String id) => '/product/$id';
}
