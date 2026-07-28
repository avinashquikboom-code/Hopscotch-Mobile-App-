import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/loyalty_api.dart';

class LoyaltyState {
  final int rewardBalance;
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final double walletBalance;
  final String referralCode;
  final double conversionRate;
  final bool isLoading;

  final bool useRewardPoints;
  final bool useWallet;
  final int pointsToRedeem;
  final double walletAmountUsed;

  const LoyaltyState({
    this.rewardBalance = 0,
    this.lifetimeEarned = 0,
    this.lifetimeRedeemed = 0,
    this.walletBalance = 0.0,
    this.referralCode = '',
    this.conversionRate = 0.01,
    this.isLoading = false,
    this.useRewardPoints = false,
    this.useWallet = false,
    this.pointsToRedeem = 0,
    this.walletAmountUsed = 0.0,
  });

  double get rewardDiscountAmount => pointsToRedeem * conversionRate;

  LoyaltyState copyWith({
    int? rewardBalance,
    int? lifetimeEarned,
    int? lifetimeRedeemed,
    double? walletBalance,
    String? referralCode,
    double? conversionRate,
    bool? isLoading,
    bool? useRewardPoints,
    bool? useWallet,
    int? pointsToRedeem,
    double? walletAmountUsed,
  }) {
    return LoyaltyState(
      rewardBalance: rewardBalance ?? this.rewardBalance,
      lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
      lifetimeRedeemed: lifetimeRedeemed ?? this.lifetimeRedeemed,
      walletBalance: walletBalance ?? this.walletBalance,
      referralCode: referralCode ?? this.referralCode,
      conversionRate: conversionRate ?? this.conversionRate,
      isLoading: isLoading ?? this.isLoading,
      useRewardPoints: useRewardPoints ?? this.useRewardPoints,
      useWallet: useWallet ?? this.useWallet,
      pointsToRedeem: pointsToRedeem ?? this.pointsToRedeem,
      walletAmountUsed: walletAmountUsed ?? this.walletAmountUsed,
    );
  }
}

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  final LoyaltyApi _api = LoyaltyApi();

  LoyaltyNotifier() : super(const LoyaltyState()) {
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    state = state.copyWith(isLoading: true);
    try {
      final summary = await _api.getRewardSummary();
      final walletData = await _api.getWallet();

      int balance = state.rewardBalance;
      int earned = state.lifetimeEarned;
      int redeemed = state.lifetimeRedeemed;
      String code = state.referralCode;
      double rate = state.conversionRate;
      double wBalance = state.walletBalance;

      if (summary != null) {
        balance = summary['balance'] ?? 0;
        earned = summary['lifetimeEarned'] ?? 0;
        redeemed = summary['lifetimeRedeemed'] ?? 0;
        code = summary['referralCode'] ?? '';
        rate = (summary['conversionRate'] as num?)?.toDouble() ?? 0.01;
      }

      if (walletData != null) {
        wBalance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
      }

      state = state.copyWith(
        rewardBalance: balance,
        lifetimeEarned: earned,
        lifetimeRedeemed: redeemed,
        referralCode: code,
        conversionRate: rate,
        walletBalance: wBalance,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error fetching loyalty summary: $e');
      state = state.copyWith(isLoading: false);
    }
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
