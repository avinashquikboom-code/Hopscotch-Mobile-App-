import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/database_helper.dart';
import '../data/datasources/local_product_datasource.dart';
import '../data/datasources/asset_seed_loader.dart';
import '../data/matchers/image_matcher.dart';
import '../data/matchers/perceptual_hash_matcher.dart';
import '../data/repositories/local_image_matching_repository.dart';
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

// Image matching repository - THE SWAP POINT
// To swap for Gemini implementation, only change this provider
final imageMatchingRepositoryProvider = Provider<ImageMatchingRepository>((ref) {
  final dataSource = ref.watch(localProductDataSourceProvider);
  final matcher = ref.watch(imageMatcherProvider);
  return LocalImageMatchingRepository(
    dataSource: dataSource,
    matcher: matcher,
  );
});

// Visual search controller
final visualSearchControllerProvider =
    StateNotifierProvider<VisualSearchController, VisualSearchState>((ref) {
  final repository = ref.watch(imageMatchingRepositoryProvider);
  return VisualSearchController(repository);
});
