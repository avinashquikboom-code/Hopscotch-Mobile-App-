import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/auth_api.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/models/user_model.dart';
import 'package:hopscotch/firebase/firebase_auth_service.dart';

class AuthRepository {
  final AuthApi _authApi;
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  AuthRepository(this._authApi);

  // Login with email and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authApi.login(
        email: email,
        password: password,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return UserModel(
          id: data['user']['id'] ?? '',
          email: data['user']['email'] ?? email,
          name: data['user']['name'] ?? 'User',
          phoneNumber: data['user']['phone'] ?? '',
          avatarUrl: data['user']['avatarUrl'],
          address: data['user']['address'],
          city: data['user']['city'],
          zipCode: data['user']['zipCode'],
        );
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Sign up with email and password
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authApi.register(
        firstName: name,
        lastName: '',
        email: email,
        password: password,
        phone: '',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        return UserModel(
          id: data['user']['id'] ?? '',
          email: data['user']['email'] ?? email,
          name: data['user']['name'] ?? name,
          phoneNumber: data['user']['phone'] ?? '',
          avatarUrl: data['user']['avatarUrl'],
          address: data['user']['address'],
          city: data['user']['city'],
          zipCode: data['user']['zipCode'],
        );
      } else {
        throw Exception('Signup failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Update user profile
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    try {
      final response = await _authApi.updateProfile(
        firstName: updatedUser.name,
        lastName: '',
        phone: updatedUser.phoneNumber,
        avatar: null,
      );

      if (response.statusCode == 200) {
        return updatedUser;
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Sign out
  Future<void> logout() async {
    // Implement logout logic if needed
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _authApi.getProfile();
      if (response.statusCode == 200) {
        final data = response.data;
        return UserModel(
          id: data['id'] ?? '',
          email: data['email'] ?? '',
          name: data['name'] ?? 'User',
          phoneNumber: data['phone'] ?? '',
          avatarUrl: data['avatarUrl'],
          address: data['address'],
          city: data['city'],
          zipCode: data['zipCode'],
        );
      }
    } catch (e) {
      // Return null if user not found
    }
    return null;
  }

  // Send OTP using Firebase Auth Service
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
  }) async {
    await _firebaseAuthService.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  // Verify OTP using Firebase Auth Service
  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    await _firebaseAuthService.verifyOTP(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ApiService();
  final authApi = AuthApi(apiService);
  return AuthRepository(authApi);
});

// A StateNotifier to manage user authentication state
class AuthStateNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository) : super(null);

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _repository.login(
        email: email,
        password: password,
      );
      state = user;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _repository.signup(
        name: name,
        email: email,
        password: password,
      );
      state = user;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      final user = await _repository.updateProfile(updatedUser);
      state = user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = null;
  }

  Future<void> loadCurrentUser() async {
    final user = await _repository.getCurrentUser();
    state = user;
  }

  // Verify OTP for forgot password flow
  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      await _repository.verifyOTP(
        verificationId: verificationId,
        smsCode: smsCode,
      );
    } catch (e) {
      rethrow;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthStateNotifier, UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});
