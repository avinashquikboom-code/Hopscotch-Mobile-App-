import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineLoyaltyService {
  static const String _keyRewardSummary = 'offline_reward_summary';
  static const String _keyWalletData = 'offline_wallet_data';
  static const String _keyRewardHistory = 'offline_reward_history';

  /// Save summary data locally
  Future<void> cacheRewardSummary(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRewardSummary, jsonEncode(data));
    } catch (e) {
      debugPrint('Offline cache reward summary error: $e');
    }
  }

  /// Get cached summary data
  Future<Map<String, dynamic>?> getCachedRewardSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyRewardSummary);
      if (str != null) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading cached reward summary: $e');
    }
    return null;
  }

  /// Save wallet data locally
  Future<void> cacheWalletData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyWalletData, jsonEncode(data));
    } catch (e) {
      debugPrint('Offline cache wallet data error: $e');
    }
  }

  /// Get cached wallet data
  Future<Map<String, dynamic>?> getCachedWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyWalletData);
      if (str != null) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading cached wallet data: $e');
    }
    return null;
  }

  /// Cache history lists
  Future<void> cacheRewardHistory(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRewardHistory, jsonEncode(items));
    } catch (e) {
      debugPrint('Error caching reward history: $e');
    }
  }

  /// Get cached reward history
  Future<List<Map<String, dynamic>>?> getCachedRewardHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyRewardHistory);
      if (str != null) {
        final list = jsonDecode(str) as List<dynamic>;
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached reward history: $e');
    }
    return null;
  }
}
