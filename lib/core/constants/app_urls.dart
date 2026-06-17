class AppUrls {
  // Base API URL
  static const String baseUrl = 'https://api.auracouture.com/v1';

  // Auth Gateways
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String forgotPassword = '/auth/forgot-password';
  static const String updateProfile = '/auth/profile/update';

  // Catalog & Shopping
  static const String products = '/products';
  static const String categories = '/categories';
  static const String orders = '/orders/place';
  static const String notifications = '/notifications/list';
}
