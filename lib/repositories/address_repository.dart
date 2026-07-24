import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopscotch/api/address_api.dart';
import 'package:hopscotch/models/address_model.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/utils/dev_logger.dart';

class AddressRepository {
  static const String _kAddressPrefsKey = 'user_saved_addresses_v1';
  static const String _kAddressHasLoadedKey = 'user_saved_addresses_has_loaded_v1';
  final AddressApi? _api;

  AddressRepository([this._api]);

  static final List<AddressModel> _defaultInitial = [
    AddressModel(
      id: 'addr_home',
      fullName: 'Default User',
      phone: '+91 98765 43210',
      addressLine1: '123 Fashion Street',
      addressLine2: 'Apartment 4B',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400001',
      country: 'India',
      isDefault: true,
      type: 'home',
    ),
    AddressModel(
      id: 'addr_current',
      fullName: 'Default User',
      phone: '+91 98765 43210',
      addressLine1: '789 Central Residency',
      addressLine2: 'Block C, Flat 201',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400012',
      country: 'India',
      isDefault: false,
      type: 'current',
    ),
    AddressModel(
      id: 'addr_office',
      fullName: 'Default User',
      phone: '+91 98765 43210',
      addressLine1: '456 Business Park',
      addressLine2: 'Tower A, Floor 12',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400051',
      country: 'India',
      isDefault: false,
      type: 'work',
    ),
  ];

  Future<List<AddressModel>> loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLoadedBefore = prefs.getBool(_kAddressHasLoadedKey) ?? false;

    // 1. Try fetching from remote API if API client is available
    if (_api != null) {
      try {
        final apiList = await _api.fetchAddresses();
        await saveAddresses(apiList);
        await prefs.setBool(_kAddressHasLoadedKey, true);
        return apiList;
      } catch (e) {
        DevLogger.logError('Failed to fetch addresses from API: $e', context: 'AddressRepository');
      }
    }

    // 2. Fallback to local disk storage
    try {
      final raw = prefs.getString(_kAddressPrefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      DevLogger.logError('Failed to load addresses from disk: $e', context: 'AddressRepository');
    }

    // 3. Fallback to default initial mock addresses ONLY if app has never initialized
    if (!hasLoadedBefore) {
      await saveAddresses(_defaultInitial);
      await prefs.setBool(_kAddressHasLoadedKey, true);
      return _defaultInitial;
    }

    return [];
  }

  Future<void> saveAddresses(List<AddressModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_kAddressPrefsKey, encoded);
      await prefs.setBool(_kAddressHasLoadedKey, true);
    } catch (e) {
      DevLogger.logError('Failed to save addresses to disk: $e', context: 'AddressRepository');
    }
  }

  Future<AddressModel?> apiCreate(AddressModel address) async {
    if (_api != null) {
      return await _api.createAddress(address);
    }
    return null;
  }

  Future<void> apiUpdate(AddressModel address) async {
    if (_api != null) {
      await _api.updateAddress(address);
    }
  }

  Future<void> apiDelete(String id) async {
    if (_api != null) {
      await _api.deleteAddress(id);
    }
  }

  Future<void> apiSetDefault(String id) async {
    if (_api != null) {
      await _api.setDefaultAddress(id);
    }
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final addressApi = AddressApi(apiService);
  return AddressRepository(addressApi);
});

class AddressNotifier extends StateNotifier<List<AddressModel>> {
  final AddressRepository _repository;

  AddressNotifier(this._repository) : super([]) {
    load();
  }

  Future<void> load() async {
    final list = await _repository.loadAddresses();
    state = list;
  }

  Future<void> addAddress(AddressModel address) async {
    final updated = [...state];
    if (address.isDefault) {
      for (var a in updated) {
        a.isDefault = false;
      }
    }
    updated.add(address);
    state = updated;
    await _repository.saveAddresses(updated);
    
    try {
      final serverAddress = await _repository.apiCreate(address);
      if (serverAddress != null && serverAddress.id.isNotEmpty) {
        final synced = state.map((a) => a.id == address.id ? serverAddress : a).toList();
        state = synced;
        await _repository.saveAddresses(synced);
      }
    } catch (_) {}
  }

  Future<void> updateAddress(AddressModel address) async {
    final updated = state.map((a) {
      if (a.id == address.id) return address;
      if (address.isDefault) a.isDefault = false;
      return a;
    }).toList();
    state = updated;
    await _repository.saveAddresses(updated);
    await _repository.apiUpdate(address);
  }

  Future<void> deleteAddress(String id) async {
    final updated = state.where((a) => a.id != id).toList();
    state = updated;
    await _repository.saveAddresses(updated);
    await _repository.apiDelete(id);
  }

  Future<void> setDefault(String id) async {
    final updated = state.map((a) {
      a.isDefault = (a.id == id);
      return a;
    }).toList();
    state = updated;
    await _repository.saveAddresses(updated);
    await _repository.apiSetDefault(id);
  }
}

final addressNotifierProvider = StateNotifierProvider<AddressNotifier, List<AddressModel>>((ref) {
  final repo = ref.watch(addressRepositoryProvider);
  return AddressNotifier(repo);
});
