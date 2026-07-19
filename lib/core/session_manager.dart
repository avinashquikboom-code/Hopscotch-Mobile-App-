import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kOnboarded = 'onboarding_done';

  // ── TOKENS ────────────────────────────────────────────────
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  static Future<String?> getAccessToken() => _storage.read(key: _kAccess);
  static Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);

  static Future<void> clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  static Future<bool> hasSession() async =>
      (await getRefreshToken())?.isNotEmpty == true;

  // ── ONBOARDING ────────────────────────────────────────────
  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarded, true);
  }

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboarded) ?? false;
  }
}

// ── APP STARTUP STATE ───────────────────────────────────────
enum StartupState { onboarding, login, home }

final startupStateProvider = FutureProvider<StartupState>((ref) async {
  final onboarded = await SessionManager.isOnboardingDone();
  if (!onboarded) return StartupState.onboarding;

  final hasSession = await SessionManager.hasSession();
  return hasSession ? StartupState.home : StartupState.login;
});
