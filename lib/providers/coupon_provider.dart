import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/coupon_model.dart';
import 'package:hopscotch/screens/coupons/coupons_screen.dart';

class AppliedCouponNotifier extends StateNotifier<CouponModel?> {
  AppliedCouponNotifier() : super(null);

  void applyCoupon(CouponModel coupon) {
    state = coupon;
  }

  void removeCoupon() {
    state = null;
  }

  double calculateDiscount(double subtotal) {
    if (state == null || subtotal <= 0) return 0.0;
    final coupon = state!;
    if (coupon.type == 'percentage') {
      final discount = subtotal * (coupon.discount / 100.0);
      return (discount * 100.0).roundToDouble() / 100.0;
    } else {
      final discount = coupon.discount;
      return (discount > subtotal ? subtotal : discount * 1.0);
    }
  }
}

final appliedCouponProvider =
    StateNotifierProvider<AppliedCouponNotifier, CouponModel?>((ref) {
      return AppliedCouponNotifier();
    });
