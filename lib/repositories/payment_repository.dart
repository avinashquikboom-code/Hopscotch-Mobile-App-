import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_service.dart';
import '../providers/api_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentRepository(apiService);
});

class PaymentRepository {
  final ApiService _apiService;

  PaymentRepository(this._apiService);

  Future<Map<String, dynamic>> createRazorpayOrder({int? orderId}) async {
    final response = await _apiService.post('/mobile/payments/order', data: {
      if (orderId != null) 'orderId': orderId,
    });
    if (response.data != null && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data?['message'] ?? 'Failed to create Razorpay order');
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await _apiService.post('/mobile/payments/verify', data: {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    });
    if (response.data != null && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data?['message'] ?? 'Failed to verify payment signature');
  }
}
