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
    final endpoints = [
      '/api/settings/countries',
      '/settings/countries',
      '/api/v1/settings/countries',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await _apiService.get(endpoint);
        if (response.statusCode == 200 && response.data != null) {
          final rawData = response.data['data'] ?? response.data['countries'] ?? response.data;
          if (rawData is List) {
            final parsed = rawData
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            if (parsed.isNotEmpty) {
              return parsed;
            }
          }
        }
      } catch (e) {
        DevLogger.logError('Error fetching countries from $endpoint: $e', context: 'ConfigRepository');
      }
    }
    return [];
  }

  Future<Map<String, String>> fetchSellerDetails() async {
    final endpoints = [
      '/api/v1/settings/app',
      '/api/settings/app',
      '/settings/app',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await _apiService.get(endpoint);
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data['data'] ?? response.data;
          if (data is Map) {
            final name = (data['sellerName'] ?? data['siteName'] ?? '').toString();
            final phone = (data['sellerContactNumber'] ?? data['contactPhone'] ?? '').toString();
            if (name.isNotEmpty || phone.isNotEmpty) {
              return {
                'sellerName': name.isNotEmpty ? name : 'FCI Seller Retail Pvt. Ltd.',
                'sellerContactNumber': phone.isNotEmpty ? phone : '+91 9876543210',
              };
            }
          }
        }
      } catch (e) {
        DevLogger.logError('Error fetching seller details from $endpoint: $e', context: 'ConfigRepository');
      }
    }
    return {
      'sellerName': 'FCI Seller Retail Pvt. Ltd.',
      'sellerContactNumber': '+91 9876543210',
    };
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

final apiSellerInfoProvider = FutureProvider<Map<String, String>>((ref) {
  return ref.watch(configRepositoryProvider).fetchSellerDetails();
});
