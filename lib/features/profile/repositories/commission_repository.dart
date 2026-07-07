import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/providers/api_provider.dart';
import '../../../../core/constants/app_urls.dart';
import '../models/commission_model.dart';

class CommissionRepository {
  final ApiService _apiService;

  CommissionRepository(this._apiService);

  Future<CommissionModel?> getCommission() async {
    try {
      final response = await _apiService.get(AppUrls.commission);
      if (response.statusCode == 200) {
        final data = response.data;
        final commissionData = data is Map ? data['data'] : data;
        if (commissionData is Map) {
          return CommissionModel.fromJson(commissionData as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('[CommissionRepository] Error fetching commission: $e');
    }
    return null;
  }
}

final commissionRepositoryProvider = Provider<CommissionRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CommissionRepository(apiService);
});

final commissionProvider = FutureProvider<CommissionModel?>((ref) {
  return ref.watch(commissionRepositoryProvider).getCommission();
});
