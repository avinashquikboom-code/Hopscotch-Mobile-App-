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
}
