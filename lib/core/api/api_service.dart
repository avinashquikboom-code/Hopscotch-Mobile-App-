import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5001'; // Update with your actual backend URL
  
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final timestamp = DateTime.now().toIso8601String();
        print('[API] 📤 ${options.method.toUpperCase()} ${options.uri}');
        print('[API] 📤 Timestamp: $timestamp');
        print('[API] 📤 Headers: ${options.headers}');
        if (options.data != null) {
          print('[API] 📤 Body: ${options.data}');
        }
        
        // Add auth token if available
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('[API] 📤 Auth token present');
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final timestamp = DateTime.now().toIso8601String();
        print('[API] 📥 Response: ${response.statusCode} ${response.requestOptions.uri}');
        print('[API] 📥 Timestamp: $timestamp');
        print('[API] 📥 Status: ${response.statusCode}');
        print('[API] 📥 Data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        final timestamp = DateTime.now().toIso8601String();
        print('[API] ❌ Error: ${error.requestOptions.uri}');
        print('[API] ❌ Timestamp: $timestamp');
        print('[API] ❌ Status: ${error.response?.statusCode}');
        print('[API] ❌ Message: ${error.message}');
        print('[API] ❌ Type: ${error.type}');
        if (error.response?.data != null) {
          print('[API] ❌ Error Data: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
  }
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  Dio get dio => _dio;
  
  // Public methods for token management
  Future<void> saveAuthToken(String token) async {
    await _saveToken(token);
  }
  
  Future<void> removeAuthToken() async {
    await _removeToken();
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
