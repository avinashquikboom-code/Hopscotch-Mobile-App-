import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map) {
        final data = error.response!.data as Map;
        final message = data['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 400) {
            return 'Bad request. Please check your input.';
          } else if (statusCode == 401) {
            return 'Unauthorized. Please check your credentials.';
          } else if (statusCode == 403) {
            return 'Access forbidden.';
          } else if (statusCode == 404) {
            return 'Requested resource not found.';
          } else if (statusCode == 429) {
            return 'Too many requests. Please try again later.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Internal server error. Please try again later.';
          }
          return 'Server returned an error: ${error.response?.statusMessage ?? "Status code $statusCode"}';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'Connection error. Please check your internet connection.';
        default:
          return 'An unexpected error occurred. Please try again.';
      }
    }
    
    return error?.toString().replaceAll('Exception: ', '') ?? 'An unexpected error occurred.';
  }
}
