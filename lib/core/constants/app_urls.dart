class AppUrls {
  // Base API URLs
  static const String mobileBaseUrl = 'http://192.168.1.103:5001';

  //Auth Gateways
  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/register';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String updateProfile = '/api/auth/profile/update';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh';
  static const String keepMeSignedIn = '/api/auth/keep-me-signed-in';

  //Catalog & Shopping
  static const String products = '/api/products';
  static const String categories = '/api/categories';
  static const String orders = '/api/orders/place';
  static const String notifications = '/api/notifications';
  static const String banners = '/api/banners';
  static const String commission = '/api/commission';
}
