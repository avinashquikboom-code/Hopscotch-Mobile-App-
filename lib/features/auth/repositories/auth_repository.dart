import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuthService _firebaseAuthService;

  AuthRepository(this._firebaseAuthService);

  // Send OTP to phone number
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

  // Verify OTP and sign in
  Future<UserModel> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final user = await _firebaseAuthService.verifyOTP(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      if (user != null) {
        // Save user data to Firestore
        await _firebaseAuthService.saveUserData(
          userId: user.uid,
          phoneNumber: user.phoneNumber ?? '',
        );

        // Get user data from Firestore
        final userData = await _firebaseAuthService.getUserData(user.uid);

        return UserModel(
          id: user.uid,
          email: userData?['email'] ?? '',
          name: userData?['name'] ?? 'User',
          phoneNumber: userData?['phoneNumber'] ?? user.phoneNumber,
          avatarUrl: userData?['avatarUrl'],
          address: userData?['address'],
          city: userData?['city'],
          zipCode: userData?['zipCode'],
        );
      } else {
        throw Exception('Failed to verify OTP');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Update user profile
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    try {
      await _firebaseAuthService.updateUserProfile(
        userId: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        avatarUrl: updatedUser.avatarUrl,
      );

      return updatedUser;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Sign out
  Future<void> logout() async {
    await _firebaseAuthService.signOut();
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuthService.currentUser;
    if (user != null) {
      final userData = await _firebaseAuthService.getUserData(user.uid);
      return UserModel(
        id: user.uid,
        email: userData?['email'] ?? '',
        name: userData?['name'] ?? 'User',
        phoneNumber: userData?['phoneNumber'] ?? user.phoneNumber,
        avatarUrl: userData?['avatarUrl'],
        address: userData?['address'],
        city: userData?['city'],
        zipCode: userData?['zipCode'],
      );
    }
    return null;
  }

  // Sign up with email and password
  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _firebaseAuthService.signup(
        name: name,
        email: email,
        password: password,
      );

      if (user != null) {
        final userData = await _firebaseAuthService.getUserData(user.uid);
        return UserModel(
          id: user.uid,
          email: userData?['email'] ?? email,
          name: userData?['name'] ?? name,
          phoneNumber: userData?['phoneNumber'] ?? '',
          avatarUrl: userData?['avatarUrl'],
          address: userData?['address'],
          city: userData?['city'],
          zipCode: userData?['zipCode'],
        );
      } else {
        throw Exception('Failed to create account');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuthService = FirebaseAuthService();
  return AuthRepository(firebaseAuthService);
});

// A StateNotifier to manage user authentication state
class AuthStateNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository) : super(null);

  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final user = await _repository.verifyOTP(
        verificationId: verificationId,
        smsCode: smsCode,
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
}

final authNotifierProvider = StateNotifierProvider<AuthStateNotifier, UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});
