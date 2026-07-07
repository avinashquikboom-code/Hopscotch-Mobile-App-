import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthApi {
  final ApiService _apiService;
  
  AuthApi(this._apiService);
  
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _apiService.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }
  
  Future<Response> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    return await _apiService.post(
      '/api/auth/register',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': phone,
      },
    );
  }
  
  Future<Response> forgotPassword({required String email}) async {
    return await _apiService.post(
      '/api/auth/forgot-password',
      data: {'email': email},
    );
  }
  
  Future<Response> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await _apiService.post(
      '/api/auth/reset-password',
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );
  }
  
  Future<Response> getProfile() async {
    return await _apiService.get('/api/auth/profile');
  }
  
  Future<Response> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
  }) async {
    return await _apiService.patch(
      '/api/auth/profile',
      data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (avatar != null) 'avatar': avatar,
      },
    );
  }
}
