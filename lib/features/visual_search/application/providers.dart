import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/api/api_service.dart';
import '../data/datasources/database_helper.dart';
import '../data/datasources/local_product_datasource.dart';
import '../data/datasources/asset_seed_loader.dart';
import '../data/datasources/visual_search_remote_datasource.dart';
import '../data/matchers/image_matcher.dart';
import '../data/matchers/perceptual_hash_matcher.dart';
import '../data/repositories/remote_image_matching_repository.dart';
import '../data/repositories/local_image_matching_repository.dart';
import '../data/services/local_image_matching_service.dart';
import '../domain/repositories/image_matching_repository.dart';
import 'visual_search_controller.dart';
import 'visual_search_state.dart';

// Database helper
final databaseHelperProvider = Provider<VisualSearchDatabaseHelper>((ref) {
  return VisualSearchDatabaseHelper.instance;
});

// Local product data source
final localProductDataSourceProvider = Provider<LocalProductDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return LocalProductDataSource(dbHelper);
});

// Asset seed loader
final assetSeedLoaderProvider = Provider<AssetSeedLoader>((ref) {
  final dataSource = ref.watch(localProductDataSourceProvider);
  return AssetSeedLoader(dataSource);
});

// Image matcher
final imageMatcherProvider = Provider<ImageMatcher>((ref) {
  return PerceptualHashMatcher();
});

// API service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Visual search remote data source provider
final visualSearchRemoteDataSourceProvider = Provider<VisualSearchRemoteDataSource>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VisualSearchRemoteDataSource(apiService);
});

// Local image matching service provider
final localImageMatchingServiceProvider = Provider<LocalImageMatchingService>((ref) {
  return LocalImageMatchingService();
});

// Image matching repository - THE SWAP POINT
// To swap for remote API implementation, change this provider
final imageMatchingRepositoryProvider = Provider<ImageMatchingRepository>((ref) {
  final localService = ref.watch(localImageMatchingServiceProvider);
  return LocalImageMatchingRepository(matchingService: localService);
});

// Visual search controller
final visualSearchControllerProvider =
    StateNotifierProvider.autoDispose<VisualSearchController, VisualSearchState>((ref) {
  final repository = ref.watch(imageMatchingRepositoryProvider);
  return VisualSearchController(repository);
});
