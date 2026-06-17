import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/dummy_data/dummy_data.dart';
import '../models/user_model.dart';

class AuthRepository {
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }
    // Return dummy user for simulation
    return UserModel.fromJson(DummyData.dummyUser);
  }

  Future<UserModel> signup(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }
    return UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
    );
  }

  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.isEmpty) {
      throw Exception('Email is required');
    }
    // Simulate email send
  }

  Future<UserModel> updateProfile(UserModel updatedUser) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return updatedUser;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// A StateNotifier to manage user authentication state
class AuthStateNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository) : super(null);

  Future<void> login(String email, String password) async {
    try {
      final user = await _repository.login(email, password);
      state = user;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      final user = await _repository.signup(name, email, password);
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

  void logout() {
    state = null;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthStateNotifier, UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});
