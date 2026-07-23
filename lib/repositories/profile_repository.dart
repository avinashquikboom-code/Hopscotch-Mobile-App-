import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/api/auth_api.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/utils/dev_logger.dart';

class ProfileRepository {
  static Map<String, dynamic>? _cachedProfile;
  static DateTime? _cacheTime;
  static const Duration _cacheTtl = Duration(minutes: 5);
  static Future<Map<String, dynamic>?>? _inflight;
  static const String _kProfilePrefsKey = 'cached_user_profile_data';

  static bool get _isCacheValid =>
      _cachedProfile != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  static void clearCache() {
    _cachedProfile = null;
    _cacheTime = null;
    _inflight = null;
    SharedPreferences.getInstance().then((prefs) => prefs.remove(_kProfilePrefsKey)).catchError((_) {});
  }

  final ApiService _apiService;

  ProfileRepository(this._apiService);

  Future<Map<String, dynamic>?> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedProfile;
    }

    if (_cachedProfile == null) {
      final diskProfile = await _loadFromDisk();
      if (diskProfile != null) {
        _cachedProfile = diskProfile;
        _cacheTime = DateTime.now();
        if (!forceRefresh) {
          // Trigger background fetch to sync changes without blocking UI
          _fetchFromApi().then((fresh) {
            if (fresh != null) {
              _cachedProfile = fresh;
              _cacheTime = DateTime.now();
              _saveToDisk(fresh);
            }
          }).catchError((_) {});
          return diskProfile;
        }
      }
    }

    if (_inflight != null) {
      return _inflight;
    }

    _inflight = _fetchFromApi();
    try {
      final profile = await _inflight;
      if (profile != null) {
        _cachedProfile = profile;
        _cacheTime = DateTime.now();
        await _saveToDisk(profile);
      }
      return profile;
    } finally {
      _inflight = null;
    }
  }

  Future<void> updateCache(Map<String, dynamic> data) async {
    final merged = Map<String, dynamic>.from(_cachedProfile ?? {})..addAll(data);
    _cachedProfile = merged;
    _cacheTime = DateTime.now();
    await _saveToDisk(merged);
  }

  Future<Map<String, dynamic>?> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_kProfilePrefsKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        return jsonDecode(rawJson) as Map<String, dynamic>;
      }
    } catch (e) {
      DevLogger.logError('Failed to load profile from disk: $e', context: 'ProfileRepository');
    }
    return null;
  }

  Future<void> _saveToDisk(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfilePrefsKey, jsonEncode(profile));
    } catch (e) {
      DevLogger.logError('Failed to save profile to disk: $e', context: 'ProfileRepository');
    }
  }

  Future<Map<String, dynamic>?> _fetchFromApi() async {
    try {
      final authApi = AuthApi(_apiService);
      final response = await authApi.getProfile();
      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) {
          final userMap = raw['data'] ?? raw['user'] ?? raw;
          if (userMap is Map<String, dynamic>) {
            return userMap;
          }
        }
      }
      return null;
    } catch (e) {
      DevLogger.logError('Error fetching profile: $e', context: 'ProfileRepository');
      if (_cachedProfile != null) {
        return _cachedProfile;
      }
      return null;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProfileRepository(apiService);
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});

class ProfileNotifier extends StateNotifier<Map<String, dynamic>?> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(null) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final profile = await _repository.getProfile();
    if (profile != null) {
      state = profile;
    }
  }

  Future<void> refreshProfile() async {
    final profile = await _repository.getProfile(forceRefresh: true);
    if (profile != null) {
      state = profile;
    }
  }

  Future<void> updateProfileState(Map<String, dynamic> updatedData) async {
    await _repository.updateCache(updatedData);
    state = Map<String, dynamic>.from(state ?? {})..addAll(updatedData);
  }

  void clearProfile() {
    ProfileRepository.clearCache();
    state = null;
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, Map<String, dynamic>?>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});
