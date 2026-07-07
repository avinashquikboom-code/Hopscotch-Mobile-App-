import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/api/auth_api.dart';
import '../../../../core/providers/api_provider.dart';

class ProfileRepository {
  final ApiService _apiService;

  ProfileRepository(this._apiService);

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final authApi = AuthApi(_apiService);
      final response = await authApi.getProfile();
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('[ProfileRepository] Error fetching profile: $e');
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
    final profile = await _repository.getProfile();
    state = profile;
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, Map<String, dynamic>?>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository)..loadProfile();
});
