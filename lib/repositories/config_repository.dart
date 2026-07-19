import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/utils/dev_logger.dart';

class ConfigRepository {
  final ApiService _apiService;

  ConfigRepository(this._apiService);

  Future<List<Map<String, dynamic>>> fetchLanguages() async {
    try {
      final response = await _apiService.get('/api/settings/languages');
      if (response.statusCode == 200) {
        final list = response.data['data'] as List<dynamic>;
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      DevLogger.logError('Error fetching languages: $e', context: 'ConfigRepository');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchCurrencies() async {
    try {
      final response = await _apiService.get('/api/settings/currencies');
      if (response.statusCode == 200) {
        final list = response.data['data'] as List<dynamic>;
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      DevLogger.logError('Error fetching currencies: $e', context: 'ConfigRepository');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchCountries() async {
    try {
      final response = await _apiService.get('/api/settings/countries');
      if (response.statusCode == 200) {
        final list = response.data['data'] as List<dynamic>;
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      DevLogger.logError('Error fetching countries: $e', context: 'ConfigRepository');
    }
    return [];
  }
}

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ConfigRepository(apiService);
});

final apiLanguagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(configRepositoryProvider).fetchLanguages();
});

final apiCurrenciesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(configRepositoryProvider).fetchCurrencies();
});

final apiCountriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(configRepositoryProvider).fetchCountries();
});
