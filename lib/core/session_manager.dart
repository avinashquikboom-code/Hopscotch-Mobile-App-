import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final _secureStorage = SecureStorageService();
  static const _kOnboarded = 'onboarding_done';

  // ── In-memory cache for sync redirect checks ──────────────
  static bool _sessionActive = false;
  static bool _onboardingDone = false;

  static bool get sessionActiveSync => _sessionActive;
  static bool get onboardingDoneSync => _onboardingDone;

  static void initCache({required bool session, required bool onboarded}) {
    _sessionActive = session;
    _onboardingDone = onboarded;
  }

  // ── TOKENS ────────────────────────────────────────────────
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _secureStorage.saveAccessToken(accessToken);
      await _secureStorage.saveRefreshToken(refreshToken);
    } catch (e) {
      print('[SessionManager] Error saving tokens: $e');
    }
    _sessionActive = true; // keep cache in sync
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.getAccessToken();
    } catch (e) {
      print('[SessionManager] Error getting access token: $e');
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.getRefreshToken();
    } catch (e) {
      print('[SessionManager] Error getting refresh token: $e');
      return null;
    }
  }

  static Future<void> clearTokens() async {
    try {
      await _secureStorage.clearAll();
    } catch (e) {
      print('[SessionManager] Error clearing secure storage: $e');
    }
    _sessionActive = false; // keep cache in sync
  }

  static Future<bool> hasSession() async {
    try {
      final token = await getRefreshToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ── ONBOARDING ────────────────────────────────────────────
  static Future<void> setOnboardingDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboarded, true);
    } catch (e) {
      print('[SessionManager] Error setting onboarding done: $e');
    }
    _onboardingDone = true; // keep cache in sync
  }

  static Future<bool> isOnboardingDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kOnboarded) ?? false;
    } catch (e) {
      return false;
    }
  }
}

// ── APP STARTUP STATE ───────────────────────────────────────
enum StartupState { onboarding, login, home }

final startupStateProvider = FutureProvider<StartupState>((ref) async {
  final onboarded = await SessionManager.isOnboardingDone();
  if (!onboarded) {
    SessionManager.initCache(session: false, onboarded: false);
    return StartupState.onboarding;
  }

  final hasSession = await SessionManager.hasSession();
  SessionManager.initCache(session: hasSession, onboarded: true);
  return hasSession ? StartupState.home : StartupState.login;
});

