import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/services/secure_storage_service.dart';
import 'package:hopscotch/services/device_info_service.dart';

class AuthApi {
  final ApiService _apiService;
  final SecureStorageService _secureStorage = SecureStorageService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  
  AuthApi(this._apiService);
  
  Future<Response> login({
    required String email,
    required String password,
    bool keepMeSignedIn = true,
  }) async {
    final deviceId = await _deviceInfoService.getDeviceId();
    final sessionId = await _deviceInfoService.getOrCreateSessionId();
    
    final response = await _apiService.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
        'deviceId': deviceId,
        'sessionId': sessionId,
        'keepMeSignedIn': keepMeSignedIn,
      },
    );
    
    // Save token and user data if login successful
    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = response.data['token'] ?? response.data['accessToken'] ?? response.data['data']?['token'] ?? response.data['data']?['accessToken'];
      final refreshToken = response.data['refreshToken'] ?? response.data['data']?['refreshToken'];
      
      if (token != null) {
        await _secureStorage.saveAccessToken(token, expiryInMinutes: 1440); // 24 hours
      }
      
      if (refreshToken != null) {
        // If keep me signed in is true, use 7 days, otherwise use shorter expiry (e.g., 1 day)
        final expiryDays = keepMeSignedIn ? 7 : 1;
        await _secureStorage.saveRefreshToken(refreshToken, expiryInDays: expiryDays);
      }
      
      // Save session ID from response if provided
      final responseSessionId = response.data['sessionId'] ?? response.data['data']?['sessionId'];
      if (responseSessionId != null) {
        await _secureStorage.saveSessionId(responseSessionId);
      }
      
      // Save user data
      final userData = response.data['data'] ?? response.data;
      final userId = userData['id']?.toString() ?? userData['_id']?.toString();
      final userName = userData['firstName'] ?? userData['name'] ?? '';
      final userEmail = userData['email'] ?? '';
      
      if (userId != null) {
        await _secureStorage.saveUserData(userId: userId, userName: userName, userEmail: userEmail);
      }
    }
    
    return response;
  }
  
  Future<Response> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    File? profileImage,
    bool keepMeSignedIn = true,
  }) async {
    final deviceId = await _deviceInfoService.getDeviceId();
    final sessionId = await _deviceInfoService.getOrCreateSessionId();
    
    Response response;
    if (profileImage != null) {
      final formData = FormData.fromMap({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'deviceId': deviceId,
        'sessionId': sessionId,
        'keepMeSignedIn': keepMeSignedIn,
        'profileImage': await MultipartFile.fromFile(
          profileImage.path,
          filename: profileImage.path.split('/').last,
        ),
      });
      response = await _apiService.post(
        '/api/auth/register',
        data: formData,
      );
    } else {
      response = await _apiService.post(
        '/api/auth/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'phone': phone,
          'deviceId': deviceId,
          'sessionId': sessionId,
          'keepMeSignedIn': keepMeSignedIn,
        },
      );
    }
    
    // Save token and user data if register successful
    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = response.data['token'] ?? response.data['accessToken'] ?? response.data['data']?['token'] ?? response.data['data']?['accessToken'];
      final refreshToken = response.data['refreshToken'] ?? response.data['data']?['refreshToken'];
      
      if (token != null) {
        await _secureStorage.saveAccessToken(token, expiryInMinutes: 1440); // 24 hours
      }
      
      if (refreshToken != null) {
        // If keep me signed in is true, use 7 days, otherwise use shorter expiry (e.g., 1 day)
        final expiryDays = keepMeSignedIn ? 7 : 1;
        await _secureStorage.saveRefreshToken(refreshToken, expiryInDays: expiryDays);
      }
      
      // Save session ID from response if provided
      final responseSessionId = response.data['sessionId'] ?? response.data['data']?['sessionId'];
      if (responseSessionId != null) {
        await _secureStorage.saveSessionId(responseSessionId);
      }
      
      // Save user data
      final userData = response.data['data'] ?? response.data;
      final userId = userData['id']?.toString() ?? userData['_id']?.toString();
      final userName = userData['firstName'] ?? userData['name'] ?? '';
      final userEmail = userData['email'] ?? '';
      
      if (userId != null) {
        await _secureStorage.saveUserData(userId: userId, userName: userName, userEmail: userEmail);
      }
    }
    
    return response;
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
    return await _apiService.get('/api/auth/me');
  }
  
  Future<Response> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    File? avatar,
  }) async {
    if (avatar != null) {
      final formData = FormData.fromMap({
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        'avatar': await MultipartFile.fromFile(
          avatar.path,
          filename: avatar.path.split('/').last,
        ),
      });
      return await _apiService.patch(
        '/api/users/me',
        data: formData,
      );
    } else {
      return await _apiService.patch(
        '/api/users/me',
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (phone != null) 'phone': phone,
        },
      );
    }
  }

  Future<Response?> logout() async {
    Response? response;
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      response = await _apiService.post(
        AppUrls.logout,
        data: {
          if (refreshToken != null) 'refreshToken': refreshToken,
        },
      );
    } catch (e) {
      print('[AuthApi] Server logout failed (expected if token expired/invalid): $e');
    } finally {
      // Clear all secure storage data regardless of response
      await _secureStorage.clearAll();
    }
    
    return response;
  }

  Future<Response> refreshToken(String refreshToken) async {
    return await _apiService.post(
      AppUrls.refreshToken,
      data: {'refreshToken': refreshToken},
    );
  }

  Future<Response> keepMeSignedIn() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }
    
    return await _apiService.post(
      AppUrls.keepMeSignedIn,
      data: {'refreshToken': refreshToken},
    );
  }
}
