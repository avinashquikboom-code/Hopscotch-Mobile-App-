import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/utils/dev_logger.dart';
import 'package:hopscotch/screens/coupons/coupons_screen.dart';

class CouponRepository {
  final ApiService _apiService;

  CouponRepository(this._apiService);

  Future<List<CouponModel>> getCoupons() async {
    try {
      final response = await _apiService.get('/api/coupons');
      if (response.statusCode == 200) {
        final data = response.data;
        final List? rawList = data is Map ? data['data'] : data;
        if (rawList != null) {
          return rawList.map((c) {
            final id = c['id']?.toString() ?? '';
            final code = c['code']?.toString() ?? '';
            final typeStr = c['type']?.toString().toUpperCase() ?? 'FLAT';
            final discountVal = c['value'] != null ? double.tryParse(c['value'].toString()) ?? 0.0 : 0.0;
            final minOrderVal = c['minOrderValue'] != null ? double.tryParse(c['minOrderValue'].toString()) ?? 0.0 : 0.0;
            final maxDiscountVal = c['maxDiscount'] != null ? double.tryParse(c['maxDiscount'].toString()) ?? 0.0 : 0.0;
            final expiresAtStr = c['expiresAt']?.toString();
            final expiry = expiresAtStr != null ? DateTime.parse(expiresAtStr) : DateTime.now().add(const Duration(days: 7));
            
            // Map type flat / percentage
            final type = typeStr == 'PERCENTAGE' ? 'percentage' : 'flat';
            
            // Construct user-friendly title and description
            final title = typeStr == 'PERCENTAGE' 
                ? 'Save ${discountVal.toStringAsFixed(0)}%' 
                : 'Flat ₹${discountVal.toStringAsFixed(0)} Off';
                
            final description = typeStr == 'PERCENTAGE'
                ? 'Get ${discountVal.toStringAsFixed(0)}% off on your purchase'
                : 'Get flat ₹${discountVal.toStringAsFixed(0)} off on your purchase';

            return CouponModel(
              id: id,
              title: title,
              description: description,
              code: code,
              discount: discountVal.toInt(),
              type: type,
              minOrder: minOrderVal,
              maxDiscount: maxDiscountVal,
              expiry: expiry,
              category: 'All',
              isExclusive: false,
              isApplied: false,
            );
          }).toList();
        }
      }
    } catch (e) {
      DevLogger.logError('Error fetching coupons: $e', context: 'CouponRepository');
    }
    return [];
  }
}

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CouponRepository(apiService);
});

final couponsProvider = FutureProvider<List<CouponModel>>((ref) {
  return ref.watch(couponRepositoryProvider).getCoupons();
});
