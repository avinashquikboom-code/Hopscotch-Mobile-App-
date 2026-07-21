import 'package:dio/dio.dart';
import 'package:hopscotch/api/api_service.dart';

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
    String? addressId,
    dynamic address,
    List<dynamic>? items,
    String? paymentMethod,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    return await _apiService.post(
      '/api/v1/mobile/orders',
      data: {
        if (addressId != null) 'addressId': addressId,
        if (address != null) 'address': address,
        if (items != null) 'items': items,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
        if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
        if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
      },
    );
  }
  
  Future<Response> cancelOrder(String orderId, {String? reason}) async {
    return await _apiService.patch(
      '/api/orders/$orderId/cancel',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }
}
