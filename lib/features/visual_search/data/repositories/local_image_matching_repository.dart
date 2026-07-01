import 'dart:io';
import '../../domain/entities/scored_product.dart';
import '../../domain/entities/visual_search_result.dart';
import '../../domain/failures/visual_search_failure.dart';
import '../../domain/repositories/image_matching_repository.dart';
import '../datasources/local_product_datasource.dart';
import '../matchers/image_matcher.dart';

/// Local implementation of ImageMatchingRepository
/// Uses SQLite data source + perceptual hash matcher
/// Works completely offline
class LocalImageMatchingRepository implements ImageMatchingRepository {
  final LocalProductDataSource _dataSource;
  final ImageMatcher _matcher;

  LocalImageMatchingRepository({
    required LocalProductDataSource dataSource,
    required ImageMatcher matcher,
  })  : _dataSource = dataSource,
        _matcher = matcher;

  @override
  Future<VisualSearchResult> search(File image) async {
    try {
      // Ensure database is seeded
      if (!await _dataSource.isSeeded()) {
        throw EmptyCatalog('Preparing catalog... Please try again in a moment.');
      }

      // Compute signature of uploaded image
      final imageBytes = await image.readAsBytes();
      final querySignature = await _matcher.computeSignature(imageBytes);

      // Get all products from database
      final allProducts = await _dataSource.getAllProducts();

      if (allProducts.isEmpty) {
        throw EmptyCatalog();
      }

      // Compare with all product images
      final List<ScoredProduct> scoredProducts = [];

      for (final product in allProducts) {
        final images = await _dataSource.getProductImages(product.id);

        for (final img in images) {
          final imageId = img['id'] as String;

          // Check if we have a cached signature
          final cachedSignature = await _dataSource.getImageSignature(imageId);

          ImageSignature? productSignature;

          if (cachedSignature != null) {
            // Use cached signature
            productSignature = ImageSignature(
              dHash: BigInt.parse(cachedSignature['d_hash'] as String, radix: 16),
              hsvHistogram: List<double>.from(
                (cachedSignature['hsv_histogram'] as String)
                    .split(',')
                    .map((s) => double.parse(s)),
              ),
            );
          } else {
            // For now, skip images without cached signatures
            // In production, compute and cache them
            continue;
          }

          // Compare signatures
          final similarity = _matcher.compare(querySignature, productSignature);

          if (similarity >= 0.75) {
            scoredProducts.add(ScoredProduct(
              product: product,
              similarityScore: similarity,
            ));
          }
        }
      }

      // Sort by similarity score descending
      scoredProducts.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

      // Classify result
      if (scoredProducts.isNotEmpty && scoredProducts.first.similarityScore >= 0.98) {
        // Exact match
        return ExactMatch(scoredProducts.first.product);
      } else if (scoredProducts.isNotEmpty) {
        // Similar matches - return top 10
        return SimilarMatches(scoredProducts.take(10).toList());
      } else {
        // No match
        return NoMatchFound();
      }
    } on EmptyCatalog {
      rethrow;
    } catch (e) {
      throw UnknownFailure('An error occurred during visual search: $e');
    }
  }
}
