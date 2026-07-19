import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/visual_search/data/datasources/database_helper.dart';
import 'package:hopscotch/visual_search/data/datasources/local_product_datasource.dart';
import 'package:hopscotch/visual_search/data/datasources/asset_seed_loader.dart';
import 'package:hopscotch/visual_search/data/datasources/visual_search_remote_datasource.dart';
import 'package:hopscotch/visual_search/data/matchers/image_matcher.dart';
import 'package:hopscotch/visual_search/data/matchers/perceptual_hash_matcher.dart';
import 'package:hopscotch/repositories/local_image_matching_repository.dart';
import 'package:hopscotch/visual_search/data/services/local_image_matching_service.dart';
import 'package:hopscotch/repositories/image_matching_repository.dart';
import 'package:hopscotch/visual_search/application/visual_search_controller.dart';
import 'package:hopscotch/visual_search/application/visual_search_state.dart';

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

// API service provider (imported from core/providers/api_provider.dart)

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
