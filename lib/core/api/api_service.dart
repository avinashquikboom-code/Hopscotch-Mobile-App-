import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000'; // Update with your actual backend URL
  
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
      onRequest: (options, handler) {
        final timestamp = DateTime.now().toIso8601String();
        print('[API] 📤 ${options.method.toUpperCase()} ${options.uri}');
        print('[API] 📤 Timestamp: $timestamp');
        print('[API] 📤 Headers: ${options.headers}');
        if (options.data != null) {
          print('[API] 📤 Body: ${options.data}');
        }
        
        // Add auth token if available
        final token = _getToken();
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
  
  String? _getToken() {
    // TODO: Implement token retrieval from secure storage
    return null;
  }
  
  Dio get dio => _dio;
  
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
