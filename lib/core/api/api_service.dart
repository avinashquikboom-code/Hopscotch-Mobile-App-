import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_urls.dart';
import '../services/secure_storage_service.dart';

class ApiService {
  static const String baseUrl = AppUrls.mobileBaseUrl;
  final SecureStorageService _secureStorage = SecureStorageService();
  
  // ANSI color codes for terminal
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  
  late final Dio _dio;
  bool _isRefreshing = false;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 90),
      receiveTimeout: const Duration(seconds: 90),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final timestamp = DateTime.now().toIso8601String();
        _logColored('$_cyan[API]$_reset $_magenta📤$_reset $_green${options.method.toUpperCase()}$_reset $_blue${options.uri}$_reset');
        _logColored('$_cyan[API]$_reset $_magenta📤$_reset Timestamp: $timestamp');
        _logColored('$_cyan[API]$_reset $_magenta📤$_reset Headers: ${options.headers}');
        if (options.data != null) {
          _logColored('$_cyan[API]$_reset $_magenta📤$_reset Body: $_yellow${options.data}$_reset');
        }
        
        // Add auth token if available
        final token = await _secureStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          _logColored('$_cyan[API]$_reset $_magenta📤$_reset $_green${'Auth token present'}$_reset');
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final timestamp = DateTime.now().toIso8601String();
        _logColored('$_cyan[API]$_reset $_magenta📥$_reset $_green${'Response:'}$_reset ${response.statusCode} $_blue${response.requestOptions.uri}$_reset');
        _logColored('$_cyan[API]$_reset $_magenta📥$_reset Timestamp: $timestamp');
        _logColored('$_cyan[API]$_reset $_magenta📥$_reset Status: $_green${response.statusCode}$_reset');
        _logColored('$_cyan[API]$_reset $_magenta📥$_reset Data: $_yellow${response.data}$_reset');
        return handler.next(response);
      },
      onError: (error, handler) async {
        final timestamp = DateTime.now().toIso8601String();
        _logColored('$_cyan[API]$_reset $_red❌$_reset Error: $_blue${error.requestOptions.uri}$_reset');
        _logColored('$_cyan[API]$_reset $_red❌$_reset Timestamp: $timestamp');
        _logColored('$_cyan[API]$_reset $_red❌$_reset Status: ${error.response?.statusCode}');
        _logColored('$_cyan[API]$_reset $_red❌$_reset Message: $_red${error.message}$_reset');
        _logColored('$_cyan[API]$_reset $_red❌$_reset Type: $_yellow${error.type}$_reset');
        if (error.response?.data != null) {
          _logColored('$_cyan[API]$_reset $_red❌$_reset Error Data: $_red${error.response?.data}$_reset');
        }
        
        // Handle 401 errors with token refresh
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshToken = await _secureStorage.getRefreshToken();
            if (refreshToken != null) {
              _logColored('$_cyan[API]$_reset $_yellow🔄$_reset Attempting to refresh token...');
              
              final refreshResponse = await _dio.post(
                AppUrls.refreshToken,
                data: {'refreshToken': refreshToken},
              );
              
              if (refreshResponse.statusCode == 200 || refreshResponse.statusCode == 201) {
                final newAccessToken = refreshResponse.data['accessToken'] ?? refreshResponse.data['data']?['accessToken'];
                final newRefreshToken = refreshResponse.data['refreshToken'] ?? refreshResponse.data['data']?['refreshToken'];
                
                if (newAccessToken != null) {
                  await _secureStorage.saveAccessToken(newAccessToken, expiryInMinutes: 15);
                  _logColored('$_cyan[API]$_reset $_green✓$_reset Token refreshed successfully');
                  
                  if (newRefreshToken != null) {
                    await _secureStorage.saveRefreshToken(newRefreshToken);
                  }
                  
                  // Update the request with new token and retry
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final opts = Options(
                    method: error.requestOptions.method,
                    headers: error.requestOptions.headers,
                  );
                  
                  final response = await _dio.request(
                    error.requestOptions.path,
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                    options: opts,
                  );
                  
                  _isRefreshing = false;
                  return handler.resolve(response);
                }
              }
            }
          } catch (e) {
            _logColored('$_cyan[API]$_reset $_red❌$_reset Token refresh failed: $e');
            await _secureStorage.clearAll();
          } finally {
            _isRefreshing = false;
          }
        }
        
        return handler.next(error);
      },
    ));
  }
  
  void _logColored(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
  
  Dio get dio => _dio;
  
  // Session Restoration
  Future<bool> restoreSession() async {
    try {
      // Check if refresh token exists
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }
      
      // Check if access token exists and is not expired
      final accessToken = await _secureStorage.getAccessToken();
      final isExpired = await _secureStorage.isAccessTokenExpired();
      
      if (accessToken != null && accessToken.isNotEmpty && !isExpired) {
        _logColored('$_cyan[API]$_reset $_green✓$_reset Session valid, no refresh needed');
        return true;
      }
      
      // Access token expired or missing, try to refresh
      _logColored('$_cyan[API]$_reset $_yellow🔄$_reset Attempting to refresh session...');
      
      final refreshResponse = await _dio.post(
        AppUrls.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      
      if (refreshResponse.statusCode == 200 || refreshResponse.statusCode == 201) {
        final newAccessToken = refreshResponse.data['accessToken'] ?? refreshResponse.data['data']?['accessToken'];
        final newRefreshToken = refreshResponse.data['refreshToken'] ?? refreshResponse.data['data']?['refreshToken'];
        
        if (newAccessToken != null) {
          await _secureStorage.saveAccessToken(newAccessToken, expiryInMinutes: 15);
          _logColored('$_cyan[API]$_reset $_green✓$_reset Session refreshed successfully');
          
          if (newRefreshToken != null) {
            await _secureStorage.saveRefreshToken(newRefreshToken);
          }
          
          return true;
        }
      }
      
      _logColored('$_cyan[API]$_reset $_red❌$_reset Session refresh failed');
      return false;
    } catch (e) {
      _logColored('$_cyan[API]$_reset $_red❌$_reset Session restoration error: $e');
      return false;
    }
  }
  
  // Public methods for secure storage management
  Future<bool> hasValidSession() async {
    return await _secureStorage.hasValidSession();
  }
  
  Future<bool> isLoggedIn() async {
    return await _secureStorage.isLoggedIn();
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }
  
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _dio.put(path, data: data, queryParameters: queryParameters);
  }
  
  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.delete(path, queryParameters: queryParameters);
  }
  
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return _dio.patch(path, data: data, queryParameters: queryParameters);
  }
}
