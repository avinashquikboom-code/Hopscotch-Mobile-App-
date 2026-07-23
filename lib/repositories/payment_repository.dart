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

  ApiService get apiService => _apiService;

  Future<Map<String, dynamic>> createRazorpayOrder({int? orderId, double? amount}) async {
    final amtInPaise = ((amount ?? 100) * 100).toInt();
    return {
      'razorpayOrderId': 'order_demo_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amtInPaise,
      'currency': 'INR',
      'keyId': 'rzp_test_1DP5mmOlF5G5ag',
    };
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return {
      'status': 'success',
      'verified': true,
      'paymentId': razorpayPaymentId,
      'orderId': razorpayOrderId,
    };
  }
}
