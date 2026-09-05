import 'package:dio/dio.dart';
import 'package:hopscotch/api/api_service.dart';

class OrdersApi {
  final ApiService _apiService;
  
  OrdersApi(this._apiService);
  
  Future<Response> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    return await _apiService.get('/api/orders', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    });
  }
  
  Future<Response> getOrderById(String orderId) async {
    return await _apiService.get('/api/orders/$orderId');
  }

  Future<Response> calculateCheckout({
    String? couponCode,
    bool? giftWrap,
    List<dynamic>? items,
  }) async {
    return await _apiService.post(
      '/api/orders/calculate',
      data: {
        if (couponCode != null) 'couponCode': couponCode,
        if (giftWrap != null) 'giftWrap': giftWrap,
        if (items != null) 'items': items,
      },
    );
  }
  
  Future<Response> createOrder({
    String? addressId,
    dynamic address,
    List<dynamic>? items,
    String? paymentMethod,
    double? subtotal,
    double? shippingFee,
    double? taxAmount,
    double? totalAmount,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
    bool? giftWrap,
    String? sellerName,
    String? sellerContact,
    String? sellerAddress,
    bool? useWallet,
    double? walletAmountUsed,
  }) async {
    return await _apiService.post(
      '/api/v1/mobile/orders',
      data: {
        if (addressId != null) 'addressId': addressId,
        if (address != null) 'address': address,
        if (items != null) 'items': items,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (subtotal != null) 'subtotal': subtotal,
        if (shippingFee != null) 'shippingFee': shippingFee,
        if (taxAmount != null) 'taxAmount': taxAmount,
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
        if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
        if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
        if (giftWrap != null) 'giftWrap': giftWrap,
        if (sellerName != null && sellerName.trim().isNotEmpty) 'sellerName': sellerName.trim(),
        if (sellerContact != null && sellerContact.trim().isNotEmpty) 'sellerContact': sellerContact.trim(),
        if (sellerAddress != null && sellerAddress.trim().isNotEmpty) 'sellerAddress': sellerAddress.trim(),
        if (useWallet == true) 'useWallet': true,
        if (walletAmountUsed != null && walletAmountUsed > 0) 'walletAmountUsed': walletAmountUsed,
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
