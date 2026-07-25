class AppUrls {
  // Base API URLs
  //static const String mobileBaseUrl = 'http://192.168.1.100:5001';
  static const String mobileBaseUrl = 'https://api.fciseller.com';

  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }
    final trimmed = url.trim();
    if (trimmed == 'null' ||
        trimmed == 'undefined' ||
        trimmed == 'N/A' ||
        trimmed == 'none') {
      return '';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (trimmed.contains('localhost') ||
          trimmed.contains('127.0.0.1') ||
          trimmed.contains('10.0.2.2') ||
          trimmed.contains(':5001') ||
          trimmed.contains(':5000') ||
          trimmed.contains(':3000')) {
        try {
          final uri = Uri.parse(trimmed);
          final pathWithQuery = uri.hasQuery
              ? '${uri.path}?${uri.query}'
              : uri.path;
          return '$mobileBaseUrl$pathWithQuery';
        } catch (_) {
          return trimmed;
        }
      }
      return trimmed;
    }
    // Prefix relative paths with mobileBaseUrl, taking care of double slashes
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$mobileBaseUrl$path';
  }

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
