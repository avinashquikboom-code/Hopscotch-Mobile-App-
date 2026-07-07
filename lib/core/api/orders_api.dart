import 'package:dio/dio.dart';
import 'api_service.dart';

class OrdersApi {
  final ApiService _apiService;
  
  OrdersApi(this._apiService);
  
  Future<Response> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    return await _apiService.get('/api/orders', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    });
  }
  
  Future<Response> getOrderById(String orderId) async {
    return await _apiService.get('/api/orders/$orderId');
  }
  
  Future<Response> createOrder({
    required String addressId,
  }) async {
    return await _apiService.post(
      '/api/orders',
      data: {'addressId': addressId},
    );
  }
  
  Future<Response> cancelOrder(String orderId) async {
    return await _apiService.patch('/api/orders/$orderId/cancel');
  }
}
