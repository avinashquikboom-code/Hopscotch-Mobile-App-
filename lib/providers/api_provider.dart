import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
