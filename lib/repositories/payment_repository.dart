import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_service.dart';
import '../providers/api_provider.dart';
import '../models/cart_item_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentRepository(apiService);
});

class PaymentRepository {
  final ApiService _apiService;

  PaymentRepository(this._apiService);

  ApiService get apiService => _apiService;

  Future<Map<String, dynamic>> createRazorpayOrder({
    int? orderId,
    double? amount,
    List<CartItemModel>? cartItems,
    List<Map<String, dynamic>>? items,
    String? couponCode,
    double? discountAmount,
    bool? giftWrap,
  }) async {
    final amtInPaise = (((amount ?? 100)) * 100).round();
    final itemsPayload = items ?? cartItems
        ?.map((item) => {
              'productId': item.product.id,
              'quantity': item.quantity,
              if (item.selectedSize != null) 'size': item.selectedSize,
              if (item.selectedColor != null) 'color': item.selectedColor,
            })
        .toList();

    dev.log(
      'Creating Razorpay order on backend API: amount=₹$amount ($amtInPaise paise), itemsCount=${itemsPayload?.length ?? 0}, couponCode=$couponCode, discount=₹$discountAmount, giftWrap=$giftWrap',
      name: 'PaymentRepository',
    );
    try {
      final response = await _apiService.post(
        '/api/v1/mobile/payments/order',
        data: {
          'amount': amount,
          'currency': 'INR',
          if (itemsPayload != null && itemsPayload.isNotEmpty)
            'items': itemsPayload,
          if (orderId != null) 'orderId': orderId,
          if (couponCode != null && couponCode.isNotEmpty)
            'couponCode': couponCode,
          if (discountAmount != null && discountAmount > 0)
            'discountAmount': discountAmount,
          if (giftWrap != null) 'giftWrap': giftWrap,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        final razorpayOrderId = data['id'] ?? data['orderId'] ?? data['razorpayOrderId'];
        final keyId = data['keyId'] ?? data['key'] ?? 'rzp_test_1DP5mmOlF5G5ag';
        if (razorpayOrderId != null && razorpayOrderId.toString().isNotEmpty) {
          dev.log(
            'Razorpay order created successfully from backend API: orderId=$razorpayOrderId, amount=${data['amount']} paise',
            name: 'PaymentRepository',
          );
          return {
            'razorpayOrderId': razorpayOrderId.toString(),
            'amount': data['amount'] ?? amtInPaise,
            'currency': data['currency'] ?? 'INR',
            'keyId': keyId.toString(),
          };
        }
      }
      throw Exception('Backend returned empty or invalid Razorpay order response.');
    } catch (e, stackTrace) {
      dev.log('Failed to create Razorpay order on backend API: $e', name: 'PaymentRepository', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    dev.log('Verifying Razorpay payment signature: razorpayOrderId=$razorpayOrderId, razorpayPaymentId=$razorpayPaymentId', name: 'PaymentRepository');
    try {
      final response = await _apiService.post(
        '/api/v1/mobile/payments/verify',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final result = (response.data['data'] ?? response.data) as Map<String, dynamic>;
        dev.log('Razorpay payment verified successfully on backend API', name: 'PaymentRepository');
        return result;
      }
      throw Exception('Backend payment verification returned status ${response.statusCode}');
    } catch (e, stackTrace) {
      dev.log('Failed to verify Razorpay payment on backend API: $e', name: 'PaymentRepository', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
