class SellerConfig {
  static const String name = 'Fashion City India Ltd';
  static const String legalName = 'Fashion City India Ltd';
  static const String gstin = '24GUKPS9446A1ZA';
  static const String supportEmail = 'fashioncityinidia18@gmail.com';
  static const String address = 'F/7 Jethabhai Park, Narayan Nagar Road, Paldi, Ahmedabad, Gujarat - 380007, India';
  static const String city = 'Ahmedabad';
  static const String state = 'Gujarat';
  static const String pincode = '380007';
  static const String country = 'India';
  static const String contactNumber = '+91 96015 11596';

  static String normalizeSellerName(String? raw) {
    if (raw == null) return name;
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    if (trimmed.isEmpty ||
        lower == 'fci' ||
        lower == 'fci seller' ||
        lower == 'fci-seller' ||
        lower == 'fciseller' ||
        lower == 'fci ecommerce' ||
        lower == 'fashion city' ||
        lower == 'fashion city india' ||
        lower == 'fashion city india ltd' ||
        lower == 'fci seller retail pvt. ltd.' ||
        RegExp(r'\bfci\b', caseSensitive: false).hasMatch(trimmed) ||
        lower.startsWith('fci ') ||
        lower.endsWith(' fci')) {
      return name;
    }
    return trimmed;
  }
}

