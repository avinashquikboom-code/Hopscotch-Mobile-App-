import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/policy_model.dart';
import 'package:hopscotch/providers/api_provider.dart';

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PolicyRepository(apiService);
});

class PolicyRepository {
  final ApiService _apiService;

  // In-memory cache
  List<PolicyCategoryModel>? _cachedCategories;
  final Map<String, PolicyModel> _cachedPolicies = {};

  PolicyRepository(this._apiService);

  void clearCache() {
    _cachedCategories = null;
    _cachedPolicies.clear();
  }

  /// Fetches all active policy categories along with their policies
  Future<List<PolicyCategoryModel>> getPolicyCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }

    try {
      final response = await _apiService.get(AppUrls.policyCategories);
      if (response.statusCode == 200) {
        final dynamic body = response.data;
        final dynamic rawList = body is Map ? body['data'] : body;

        if (rawList is List) {
          final categories = rawList
              .whereType<Map<String, dynamic>>()
              .map((json) => PolicyCategoryModel.fromJson(json))
              .toList();

          if (categories.isNotEmpty) {
            _cachedCategories = categories;
            // Also cache individual policies by slug
            for (final cat in categories) {
              for (final pol in cat.policies) {
                _cachedPolicies[pol.slug] = pol;
              }
            }
            return categories;
          }
        }
      }
    } catch (e) {
      dev.log('Error fetching policy categories: $e', name: 'PolicyRepository');
    }

    // Fallback: try fetching all policies directly if category endpoint had issues
    try {
      final polResponse = await _apiService.get(AppUrls.policies);
      if (polResponse.statusCode == 200) {
        final dynamic body = polResponse.data;
        final dynamic rawList = body is Map ? body['data'] : body;
        if (rawList is List) {
          final policies = rawList
              .whereType<Map<String, dynamic>>()
              .map((json) => PolicyModel.fromJson(json))
              .toList();

          // Group by category or create synthetic categories
          final Map<int, List<PolicyModel>> grouped = {};
          for (final p in policies) {
            grouped.putIfAbsent(p.categoryId, () => []).add(p);
            _cachedPolicies[p.slug] = p;
          }

          final categories = grouped.entries.map((entry) {
            final first = entry.value.first;
            return PolicyCategoryModel(
              id: entry.key,
              name: first.categoryName ?? first.title,
              slug: first.slug,
              policies: entry.value,
            );
          }).toList();

          if (categories.isNotEmpty) {
            _cachedCategories = categories;
            return categories;
          }
        }
      }
    } catch (e) {
      dev.log('Fallback fetching policies failed: $e', name: 'PolicyRepository');
    }

    return _cachedCategories ?? [];
  }

  /// Fetches a specific policy by its slug
  Future<PolicyModel?> getPolicyBySlug(String slug, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPolicies.containsKey(slug)) {
      return _cachedPolicies[slug];
    }

    try {
      final response = await _apiService.get(AppUrls.policyBySlug(slug));
      if (response.statusCode == 200) {
        final dynamic body = response.data;
        final dynamic data = body is Map ? body['data'] : body;
        if (data is Map<String, dynamic>) {
          final policy = PolicyModel.fromJson(data);
          _cachedPolicies[slug] = policy;
          return policy;
        }
      }
    } catch (e) {
      dev.log('Error fetching policy slug "$slug": $e', name: 'PolicyRepository');
    }

    // Fallback: fetch from categories
    final categories = await getPolicyCategories();
    for (final cat in categories) {
      for (final pol in cat.policies) {
        if (pol.slug == slug) {
          _cachedPolicies[slug] = pol;
          return pol;
        }
      }
    }

    return _cachedPolicies[slug];
  }
}
