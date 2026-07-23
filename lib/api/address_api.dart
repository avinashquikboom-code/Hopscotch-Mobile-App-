import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/models/address_model.dart';

class AddressApi {
  final ApiService _apiService;

  AddressApi(this._apiService);

  static const List<String> _baseEndpoints = [
    '/api/addresses',
    '/api/v1/addresses',
    '/api/v1/user/addresses',
    '/mobile/addresses',
  ];

  Future<List<AddressModel>> fetchAddresses() async {
    for (final endpoint in _baseEndpoints) {
      try {
        final response = await _apiService.get(endpoint);
        if (response.statusCode == 200) {
          final raw = response.data;
          final list = (raw is Map<String, dynamic>)
              ? (raw['data'] ?? raw['addresses'] ?? raw)
              : raw;
          if (list is List) {
            return list
                .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (e) {
        // Fallthrough to try next endpoint or fallback to local disk storage
      }
    }
    return [];
  }

  Future<AddressModel?> createAddress(AddressModel address) async {
    for (final endpoint in _baseEndpoints) {
      try {
        final response = await _apiService.post(
          endpoint,
          data: address.toJson(),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final raw = response.data;
          final data = (raw is Map<String, dynamic>) ? (raw['data'] ?? raw) : raw;
          if (data is Map<String, dynamic>) {
            return AddressModel.fromJson(data);
          }
        }
      } catch (e) {
        // Continue to next endpoint
      }
    }
    return null;
  }

  Future<AddressModel?> updateAddress(AddressModel address) async {
    for (final endpoint in _baseEndpoints) {
      try {
        final response = await _apiService.put(
          '$endpoint/${address.id}',
          data: address.toJson(),
        );
        if (response.statusCode == 200) {
          final raw = response.data;
          final data = (raw is Map<String, dynamic>) ? (raw['data'] ?? raw) : raw;
          if (data is Map<String, dynamic>) {
            return AddressModel.fromJson(data);
          }
        }
      } catch (e) {
        // Continue to next endpoint
      }
    }
    return null;
  }

  Future<bool> deleteAddress(String id) async {
    for (final endpoint in _baseEndpoints) {
      try {
        final response = await _apiService.delete('$endpoint/$id');
        if (response.statusCode == 200) return true;
      } catch (e) {
        // Continue
      }
    }
    return false;
  }

  Future<bool> setDefaultAddress(String id) async {
    for (final endpoint in _baseEndpoints) {
      try {
        final response = await _apiService.patch('$endpoint/$id/default');
        if (response.statusCode == 200) return true;
      } catch (e) {
        // Continue
      }
    }
    return false;
  }
}
