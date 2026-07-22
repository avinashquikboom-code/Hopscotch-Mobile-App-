import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/api/auth_api.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/utils/dev_logger.dart';

class ProfileRepository {
  static Map<String, dynamic>? _cachedProfile;
  static DateTime? _cacheTime;
  static const Duration _cacheTtl = Duration(minutes: 5);
  static Future<Map<String, dynamic>?>? _inflight;

  static bool get _isCacheValid =>
      _cachedProfile != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  static void clearCache() {
    _cachedProfile = null;
    _cacheTime = null;
    _inflight = null;
  }

  final ApiService _apiService;

  ProfileRepository(this._apiService);

  Future<Map<String, dynamic>?> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedProfile;
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
      }
      return profile;
    } finally {
      _inflight = null;
    }
  }

  Future<Map<String, dynamic>?> _fetchFromApi() async {
    try {
      final authApi = AuthApi(_apiService);
      final response = await authApi.getProfile();
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
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

  ProfileNotifier(this._repository) : super(null);

  Future<void> loadProfile() async {
    final profile = await _repository.getProfile();
    state = profile;
  }

  Future<void> refreshProfile() async {
    final profile = await _repository.getProfile(forceRefresh: true);
    state = profile;
  }

  void clearProfile() {
    state = null;
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, Map<String, dynamic>?>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository)..loadProfile();
});
