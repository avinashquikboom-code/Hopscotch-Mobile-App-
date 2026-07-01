import 'dart:io';
import '../../domain/entities/scored_product.dart';
import '../../domain/entities/visual_search_result.dart';
import '../../domain/failures/visual_search_failure.dart';
import '../../domain/repositories/image_matching_repository.dart';
import '../datasources/visual_search_remote_datasource.dart';

/// Remote implementation of ImageMatchingRepository
/// Uses backend API for AI-powered visual search
class RemoteImageMatchingRepository implements ImageMatchingRepository {
  final VisualSearchRemoteDataSource _remoteDataSource;

  RemoteImageMatchingRepository(this._remoteDataSource);

  @override
  Future<VisualSearchResult> search(File image) async {
    try {
      final response = await _remoteDataSource.searchWithImage(image);
      
      final matches = response['matches'] as List<dynamic>? ?? [];
      final similarSuggestions = response['similarSuggestions'] as List<dynamic>? ?? [];
      
      final List<ScoredProduct> scoredProducts = [];
      
      // Convert API response to ScoredProduct entities
      for (final match in matches) {
        scoredProducts.add(ScoredProduct(
          product: _convertToProduct(match),
          similarityScore: 1.0, // API provides confidence score
        ));
      }
      
      // Add similar suggestions with lower scores
      for (final suggestion in similarSuggestions) {
        scoredProducts.add(ScoredProduct(
          product: _convertToProduct(suggestion),
          similarityScore: 0.5, // Similar suggestions have lower score
        ));
      }
      
      // Sort by similarity score descending
      scoredProducts.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
      
      // Classify result based on confidence
      final confidence = response['confidence'] as double? ?? 0.0;
      
      if (scoredProducts.isNotEmpty && confidence >= 0.9) {
        return ExactMatch(scoredProducts.first.product);
      } else if (scoredProducts.isNotEmpty) {
        return SimilarMatches(scoredProducts.take(10).toList());
      } else {
        return NoMatchFound();
      }
    } on Exception catch (e) {
      throw NetworkFailure('Failed to connect to visual search service: ${e.toString()}');
    } catch (e) {
      throw UnknownFailure('An error occurred during visual search: $e');
    }
  }
  
  /// Convert API response to Product entity
  dynamic _convertToProduct(dynamic data) {
    // This is a simplified conversion - you may need to adjust based on your Product entity structure
    return {
      'id': data['id'] as String,
      'name': data['name'] as String? ?? '',
      'price': data['price'] as num? ?? 0,
      'images': data['images'] as List<dynamic>? ?? [],
      'category': data['category'] as Map<String, dynamic>? ?? {},
      'brand': data['brand'] as Map<String, dynamic>? ?? {},
    };
  }
}
