import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/policy_model.dart';
import 'package:hopscotch/repositories/policy_repository.dart';

/// Provider for list of all active policy categories
final policyCategoriesProvider = FutureProvider.autoDispose<List<PolicyCategoryModel>>((ref) async {
  final repo = ref.watch(policyRepositoryProvider);
  return repo.getPolicyCategories();
});

/// Provider for a specific policy by its slug
final policyDetailProvider = FutureProvider.autoDispose.family<PolicyModel?, String>((ref, slug) async {
  final repo = ref.watch(policyRepositoryProvider);
  return repo.getPolicyBySlug(slug);
});

/// State provider for tracking the currently selected tab/category index in LegalPoliciesScreen
final selectedPolicyCategoryIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
