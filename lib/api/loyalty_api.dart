import 'package:hopscotch/api/api_service.dart';

class LoyaltyApi {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>?> getRewardSummary() async {
    try {
      final response = await _apiService.get('/loyalty/summary');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting reward summary: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWallet() async {
    try {
      final response = await _apiService.get('/loyalty/wallet');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting wallet: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> calculateCartRewards(List<Map<String, dynamic>> items) async {
    try {
      final response = await _apiService.post(
        '/loyalty/calculate-cart',
        data: {'items': items},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error calculating cart rewards: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getReferrals() async {
    try {
      final response = await _apiService.get('/loyalty/referrals');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting referrals: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMasterTransactions() async {
    try {
      final response = await _apiService.get('/loyalty/transactions');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting transactions: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getRewardHistory({String filter = 'All'}) async {
    try {
      final response = await _apiService.get(
        '/loyalty/rewards/history',
        queryParameters: {'filter': filter.toLowerCase()},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as List<dynamic>?;
      }
    } catch (e) {
      print('Error getting reward history: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCashbackData() async {
    try {
      final response = await _apiService.get('/loyalty/cashback');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting cashback data: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getGiftCardsData() async {
    try {
      final response = await _apiService.get('/loyalty/gift-cards');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error getting gift cards data: $e');
    }
    return null;
  }

  Future<bool> redeemGiftCard(String code) async {
    try {
      final response = await _apiService.post(
        '/loyalty/gift-cards/redeem',
        data: {'code': code},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error redeeming gift card: $e');
      return false;
    }
  }

  Future<bool> topupWallet(double amount) async {
    try {
      final response = await _apiService.post(
        '/loyalty/wallet/topup',
        data: {'amount': amount},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error topping up wallet: $e');
      return false;
    }
  }

  Future<bool> claimDailyReward() async {
    try {
      final response = await _apiService.post('/loyalty/daily-reward/claim');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('Error claiming daily reward: $e');
      return false;
    }
  }

  /// Creates a Razorpay order for wallet top-up. Returns {orderId, amount, currency, keyId}.
  Future<Map<String, dynamic>?> createWalletLoadOrder(int amount) async {
    try {
      final response = await _apiService.post(
        '/mobile/wallet/load-order',
        data: {'amount': amount},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error creating wallet load order: $e');
    }
    return null;
  }

  /// Verifies the Razorpay signature for wallet top-up and credits the wallet.
  Future<Map<String, dynamic>?> verifyWalletLoad({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _apiService.post(
        '/mobile/wallet/verify',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error verifying wallet load: $e');
    }
    return null;
  }
}
