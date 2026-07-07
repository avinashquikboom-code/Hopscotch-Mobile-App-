import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Token keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';
  static const String _deviceIdKey = 'device_id';
  static const String _sessionIdKey = 'session_id';

  // User data keys
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  bool _useSecureStorage = true;

  SecureStorageService() {
    _checkSecureStorageAvailability();
  }

  Future<void> _checkSecureStorageAvailability() async {
    try {
      await _storage.write(key: '_test', value: '_test');
      await _storage.delete(key: '_test');
      _useSecureStorage = true;
    } catch (e) {
      print('[SecureStorageService] FlutterSecureStorage not available, using SharedPreferences fallback');
      _useSecureStorage = false;
    }
  }

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Token Management
  Future<void> saveAccessToken(String token, {int? expiryInMinutes}) async {
    if (_useSecureStorage) {
      await _storage.write(key: _accessTokenKey, value: token);
      if (expiryInMinutes != null) {
        final expiryTime = DateTime.now().add(Duration(minutes: expiryInMinutes)).toIso8601String();
        await _storage.write(key: _tokenExpiryKey, value: expiryTime);
      }
    } else {
      final prefs = await _prefs;
      await prefs.setString(_accessTokenKey, token);
      if (expiryInMinutes != null) {
        final expiryTime = DateTime.now().add(Duration(minutes: expiryInMinutes)).toIso8601String();
        await prefs.setString(_tokenExpiryKey, expiryTime);
      }
    }
  }

  Future<String?> getAccessToken() async {
    if (_useSecureStorage) {
      return await _storage.read(key: _accessTokenKey);
    } else {
      final prefs = await _prefs;
      return prefs.getString(_accessTokenKey);
    }
  }

  Future<void> saveRefreshToken(String token, {int? expiryInDays}) async {
    if (_useSecureStorage) {
      await _storage.write(key: _refreshTokenKey, value: token);
      if (expiryInDays != null) {
        final expiryTime = DateTime.now().add(Duration(days: expiryInDays)).toIso8601String();
        await _storage.write(key: _refreshTokenExpiryKey, value: expiryTime);
      }
    } else {
      final prefs = await _prefs;
      await prefs.setString(_refreshTokenKey, token);
      if (expiryInDays != null) {
        final expiryTime = DateTime.now().add(Duration(days: expiryInDays)).toIso8601String();
        await prefs.setString(_refreshTokenExpiryKey, expiryTime);
      }
    }
  }

  Future<String?> getRefreshToken() async {
    if (_useSecureStorage) {
      return await _storage.read(key: _refreshTokenKey);
    } else {
      final prefs = await _prefs;
      return prefs.getString(_refreshTokenKey);
    }
  }

  Future<DateTime?> getTokenExpiry() async {
    String? expiryStr;
    if (_useSecureStorage) {
      expiryStr = await _storage.read(key: _tokenExpiryKey);
    } else {
      final prefs = await _prefs;
      expiryStr = prefs.getString(_tokenExpiryKey);
    }
    if (expiryStr != null) {
      return DateTime.parse(expiryStr);
    }
    return null;
  }

  Future<DateTime?> getRefreshTokenExpiry() async {
    String? expiryStr;
    if (_useSecureStorage) {
      expiryStr = await _storage.read(key: _refreshTokenExpiryKey);
    } else {
      final prefs = await _prefs;
      expiryStr = prefs.getString(_refreshTokenExpiryKey);
    }
    if (expiryStr != null) {
      return DateTime.parse(expiryStr);
    }
    return null;
  }

  Future<bool> isAccessTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  Future<bool> isRefreshTokenExpired() async {
    final expiry = await getRefreshTokenExpiry();
    if (expiry == null) return false; // If no expiry set, assume not expired
    return DateTime.now().isAfter(expiry);
  }

  Future<void> clearTokens() async {
    if (_useSecureStorage) {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _tokenExpiryKey);
      await _storage.delete(key: _refreshTokenExpiryKey);
    } else {
      final prefs = await _prefs;
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpiryKey);
      await prefs.remove(_refreshTokenExpiryKey);
    }
  }

  // Device & Session Management
  Future<void> saveDeviceId(String deviceId) async {
    if (_useSecureStorage) {
      await _storage.write(key: _deviceIdKey, value: deviceId);
    } else {
      final prefs = await _prefs;
      await prefs.setString(_deviceIdKey, deviceId);
    }
  }

  Future<String?> getDeviceId() async {
    if (_useSecureStorage) {
      return await _storage.read(key: _deviceIdKey);
    } else {
      final prefs = await _prefs;
      return prefs.getString(_deviceIdKey);
    }
  }

  Future<void> saveSessionId(String sessionId) async {
    if (_useSecureStorage) {
      await _storage.write(key: _sessionIdKey, value: sessionId);
    } else {
      final prefs = await _prefs;
      await prefs.setString(_sessionIdKey, sessionId);
    }
  }

  Future<String?> getSessionId() async {
    if (_useSecureStorage) {
      return await _storage.read(key: _sessionIdKey);
    } else {
      final prefs = await _prefs;
      return prefs.getString(_sessionIdKey);
    }
  }

  Future<void> clearSession() async {
    if (_useSecureStorage) {
      await _storage.delete(key: _sessionIdKey);
    } else {
      final prefs = await _prefs;
      await prefs.remove(_sessionIdKey);
    }
  }

  // User Data Management
  Future<void> saveUserData({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    if (_useSecureStorage) {
      await _storage.write(key: _userIdKey, value: userId);
      await _storage.write(key: _userNameKey, value: userName);
      await _storage.write(key: _userEmailKey, value: userEmail);
    } else {
      final prefs = await _prefs;
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userNameKey, userName);
      await prefs.setString(_userEmailKey, userEmail);
    }
  }

  Future<Map<String, String?>> getUserData() async {
    if (_useSecureStorage) {
      return {
        'userId': await _storage.read(key: _userIdKey),
        'userName': await _storage.read(key: _userNameKey),
        'userEmail': await _storage.read(key: _userEmailKey),
      };
    } else {
      final prefs = await _prefs;
      return {
        'userId': prefs.getString(_userIdKey),
        'userName': prefs.getString(_userNameKey),
        'userEmail': prefs.getString(_userEmailKey),
      };
    }
  }

  Future<void> clearUserData() async {
    if (_useSecureStorage) {
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _userNameKey);
      await _storage.delete(key: _userEmailKey);
    } else {
      final prefs = await _prefs;
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userEmailKey);
    }
  }

  // Clear All
  Future<void> clearAll() async {
    if (_useSecureStorage) {
      await _storage.deleteAll();
    } else {
      final prefs = await _prefs;
      await prefs.clear();
    }
  }

  // Session Validation
  Future<bool> isLoggedIn() async {
    final refreshToken = await getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Future<bool> hasValidSession() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    
    final accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return false;
    
    return true;
  }
}
