import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/loyalty_api.dart';
import 'package:hopscotch/models/loyalty_models.dart';
import 'package:hopscotch/services/offline_loyalty_service.dart';
import 'package:hopscotch/services/loyalty_notification_service.dart';

class LoyaltyState {
  final int rewardBalance;
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final int pointsExpiringSoon;
  final double walletBalance;
  final double cashbackBalance;
  final double referralEarnings;
  final double giftCardBalance;
  final String referralCode;
  final double conversionRate;
  final bool isLoading;
  final bool isOffline;

  // Checkout Selections
  final bool useRewardPoints;
  final bool useWallet;
  final int pointsToRedeem;
  final double walletAmountUsed;

  // Detailed Transaction Lists
  final List<WalletTransaction> walletTransactions;
  final List<RewardHistoryItem> rewardHistory;
  final List<CashbackItem> cashbackHistory;
  final List<GiftCardItem> giftCardHistory;
  final ReferralData? referralData;

  const LoyaltyState({
    this.rewardBalance = 0,
    this.lifetimeEarned = 0,
    this.lifetimeRedeemed = 0,
    this.pointsExpiringSoon = 0,
    this.walletBalance = 0.0,
    this.cashbackBalance = 0.0,
    this.referralEarnings = 0.0,
    this.giftCardBalance = 0.0,
    this.referralCode = '',
    this.conversionRate = 0.01,
    this.isLoading = false,
    this.isOffline = false,
    this.useRewardPoints = false,
    this.useWallet = false,
    this.pointsToRedeem = 0,
    this.walletAmountUsed = 0.0,
    this.walletTransactions = const [],
    this.rewardHistory = const [],
    this.cashbackHistory = const [],
    this.giftCardHistory = const [],
    this.referralData,
  });

  double get rewardDiscountAmount => pointsToRedeem * conversionRate;

  LoyaltyState copyWith({
    int? rewardBalance,
    int? lifetimeEarned,
    int? lifetimeRedeemed,
    int? pointsExpiringSoon,
    double? walletBalance,
    double? cashbackBalance,
    double? referralEarnings,
    double? giftCardBalance,
    String? referralCode,
    double? conversionRate,
    bool? isLoading,
    bool? isOffline,
    bool? useRewardPoints,
    bool? useWallet,
    int? pointsToRedeem,
    double? walletAmountUsed,
    List<WalletTransaction>? walletTransactions,
    List<RewardHistoryItem>? rewardHistory,
    List<CashbackItem>? cashbackHistory,
    List<GiftCardItem>? giftCardHistory,
    ReferralData? referralData,
  }) {
    return LoyaltyState(
      rewardBalance: rewardBalance ?? this.rewardBalance,
      lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
      lifetimeRedeemed: lifetimeRedeemed ?? this.lifetimeRedeemed,
      pointsExpiringSoon: pointsExpiringSoon ?? this.pointsExpiringSoon,
      walletBalance: walletBalance ?? this.walletBalance,
      cashbackBalance: cashbackBalance ?? this.cashbackBalance,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      giftCardBalance: giftCardBalance ?? this.giftCardBalance,
      referralCode: referralCode ?? this.referralCode,
      conversionRate: conversionRate ?? this.conversionRate,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      useRewardPoints: useRewardPoints ?? this.useRewardPoints,
      useWallet: useWallet ?? this.useWallet,
      pointsToRedeem: pointsToRedeem ?? this.pointsToRedeem,
      walletAmountUsed: walletAmountUsed ?? this.walletAmountUsed,
      walletTransactions: walletTransactions ?? this.walletTransactions,
      rewardHistory: rewardHistory ?? this.rewardHistory,
      cashbackHistory: cashbackHistory ?? this.cashbackHistory,
      giftCardHistory: giftCardHistory ?? this.giftCardHistory,
      referralData: referralData ?? this.referralData,
    );
  }
}

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  final LoyaltyApi _api = LoyaltyApi();
  final OfflineLoyaltyService _offlineService = OfflineLoyaltyService();
  final LoyaltyNotificationService _notifService = LoyaltyNotificationService();

  LoyaltyNotifier() : super(const LoyaltyState()) {
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    // Load from offline cache first for instantaneous startup
    await loadFromOfflineCache();
    // Synchronize with API
    await fetchSummary();
  }

  Future<void> loadFromOfflineCache() async {
    try {
      final cachedSummary = await _offlineService.getCachedRewardSummary();
      final cachedWallet = await _offlineService.getCachedWalletData();

      if (cachedSummary != null || cachedWallet != null) {
        int balance = state.rewardBalance;
        int earned = state.lifetimeEarned;
        int redeemed = state.lifetimeRedeemed;
        int expiring = state.pointsExpiringSoon;
        String code = state.referralCode;
        double rate = state.conversionRate;
        double wBalance = state.walletBalance;

        if (cachedSummary != null) {
          balance = cachedSummary['balance'] ?? balance;
          earned = cachedSummary['lifetimeEarned'] ?? earned;
          redeemed = cachedSummary['lifetimeRedeemed'] ?? redeemed;
          expiring = cachedSummary['expiringSoon'] ?? expiring;
          code = cachedSummary['referralCode'] ?? code;
          rate = (cachedSummary['conversionRate'] as num?)?.toDouble() ?? rate;
        }

        if (cachedWallet != null) {
          wBalance = (cachedWallet['balance'] as num?)?.toDouble() ?? wBalance;
        }

        state = state.copyWith(
          rewardBalance: balance,
          lifetimeEarned: earned,
          lifetimeRedeemed: redeemed,
          pointsExpiringSoon: expiring,
          referralCode: code,
          conversionRate: rate,
          walletBalance: wBalance,
          isOffline: true,
        );
      }
    } catch (e) {
      debugPrint('Error loading offline cache: $e');
    }
  }

  Future<void> fetchSummary() async {
    state = state.copyWith(isLoading: true);
    try {
      final summary = await _api.getRewardSummary();
      final walletData = await _api.getWallet();

      int balance = state.rewardBalance;
      int earned = state.lifetimeEarned;
      int redeemed = state.lifetimeRedeemed;
      int expiring = state.pointsExpiringSoon;
      String code = state.referralCode;
      double rate = state.conversionRate;
      double wBalance = state.walletBalance;

      if (summary != null) {
        balance = (summary['balance'] as num?)?.toInt() ?? 0;
        earned = (summary['lifetimeEarned'] as num?)?.toInt() ?? 0;
        redeemed = (summary['lifetimeRedeemed'] as num?)?.toInt() ?? 0;
        expiring = (summary['expiringSoon'] as num?)?.toInt() ?? 0;
        code = summary['referralCode']?.toString() ?? '';
        rate = (summary['conversionRate'] as num?)?.toDouble() ?? 0.01;
        await _offlineService.cacheRewardSummary(summary);
      }

      if (walletData != null) {
        wBalance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
        await _offlineService.cacheWalletData(walletData);
      }

      state = state.copyWith(
        rewardBalance: balance,
        lifetimeEarned: earned,
        lifetimeRedeemed: redeemed,
        pointsExpiringSoon: expiring,
        referralCode: code,
        conversionRate: rate,
        walletBalance: wBalance,
        isLoading: false,
        isOffline: false,
      );
    } catch (e) {
      debugPrint('Error fetching loyalty summary: $e');
      state = state.copyWith(isLoading: false, isOffline: true);
    }
  }

  Future<void> fetchRewardHistory({String filter = 'All'}) async {
    try {
      final rawList = await _api.getRewardHistory(filter: filter);
      if (rawList != null) {
        final items = rawList.map((e) => RewardHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(rewardHistory: items);
      }
    } catch (e) {
      debugPrint('Error fetching reward history: $e');
    }
  }

  Future<void> fetchReferralData() async {
    try {
      final data = await _api.getReferrals();
      if (data != null) {
        final refData = ReferralData.fromJson(data);
        state = state.copyWith(
          referralData: refData,
          referralEarnings: refData.referralEarnings,
          referralCode: refData.referralCode,
        );
      }
    } catch (e) {
      debugPrint('Error fetching referral data: $e');
    }
  }

  Future<void> fetchCashbackData() async {
    try {
      final data = await _api.getCashbackData();
      if (data != null) {
        final double balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        final rawItems = (data['history'] as List<dynamic>?) ?? [];
        final items = rawItems.map((e) => CashbackItem.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(
          cashbackBalance: balance,
          cashbackHistory: items,
        );
      }
    } catch (e) {
      debugPrint('Error fetching cashback data: $e');
    }
  }

  Future<void> fetchGiftCardsData() async {
    try {
      final data = await _api.getGiftCardsData();
      if (data != null) {
        final double balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        final rawItems = (data['cards'] as List<dynamic>?) ?? [];
        final items = rawItems.map((e) => GiftCardItem.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(
          giftCardBalance: balance,
          giftCardHistory: items,
        );
      }
    } catch (e) {
      debugPrint('Error fetching gift cards data: $e');
    }
  }

  Future<bool> topupWallet(double amount) async {
    final success = await _api.topupWallet(amount);
    if (success) {
      final newBalance = state.walletBalance + amount;
      state = state.copyWith(walletBalance: newBalance);
      _notifService.showNotification('Wallet Credited', '₹${amount.toStringAsFixed(2)} has been added to your Wallet.');
      await fetchSummary();
      await fetchWalletTransactions();
    }
    return success;
  }

  Future<void> fetchWalletTransactions() async {
    try {
      final walletData = await _api.getWallet();
      final master = await _api.getMasterTransactions();

      double? wBalance;
      List<WalletTransaction> txs = [];

      if (walletData != null) {
        wBalance = (walletData['balance'] as num?)?.toDouble();
        final raw = (walletData['transactions'] as List<dynamic>?) ??
            (walletData['history'] as List<dynamic>?) ??
            [];
        txs = raw
            .whereType<Map>()
            .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (txs.isEmpty && master != null) {
        final raw = (master['transactions'] as List<dynamic>?) ??
            (master['wallet'] as List<dynamic>?) ??
            (master['history'] as List<dynamic>?) ??
            [];
        txs = raw
            .whereType<Map>()
            .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      state = state.copyWith(
        walletBalance: wBalance ?? state.walletBalance,
        walletTransactions: txs,
      );
    } catch (e) {
      debugPrint('Error fetching wallet transactions: $e');
    }
  }

  Future<bool> redeemGiftCard(String code) async {
    final success = await _api.redeemGiftCard(code);
    if (success) {
      _notifService.showNotification('Gift Card Redeemed', 'Gift Card $code successfully redeemed to your wallet.');
      await fetchSummary();
      await fetchGiftCardsData();
    }
    return success;
  }

  Future<bool> claimDailyReward() async {
    final success = await _api.claimDailyReward();
    if (success) {
      _notifService.showNotification('Daily Reward Claimed!', 'You earned bonus reward points for today.');
      await fetchSummary();
    }
    return success;
  }

  void toggleUseRewardPoints(bool value, int maxRedeemable) {
    int points = 0;
    if (value) {
      points = state.rewardBalance < maxRedeemable ? state.rewardBalance : maxRedeemable;
    }
    state = state.copyWith(useRewardPoints: value, pointsToRedeem: points);
  }

  void toggleUseWallet(bool value, double maxApplicableAmount) {
    double walletAmt = 0.0;
    if (value) {
      walletAmt = state.walletBalance < maxApplicableAmount ? state.walletBalance : maxApplicableAmount;
    }
    state = state.copyWith(useWallet: value, walletAmountUsed: walletAmt);
  }

  void resetCheckoutSelections() {
    state = state.copyWith(
      useRewardPoints: false,
      useWallet: false,
      pointsToRedeem: 0,
      walletAmountUsed: 0.0,
    );
  }
}

final loyaltyProvider = StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  return LoyaltyNotifier();
});
