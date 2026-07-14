import 'dart:io';
import 'package:hopscotch/visual_search/domain/entities/product.dart';
import 'package:hopscotch/visual_search/domain/entities/scored_product.dart';
import 'package:hopscotch/visual_search/domain/entities/visual_search_result.dart';
import 'package:hopscotch/visual_search/domain/failures/visual_search_failure.dart';
import 'package:hopscotch/repositories/image_matching_repository.dart';
import 'package:hopscotch/visual_search/data/datasources/visual_search_remote_datasource.dart';

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
  Product _convertToProduct(dynamic data) {
    // Extract brand name
    String brandName = '';
    if (data['brand'] is Map) {
      brandName = data['brand']['name'] as String? ?? '';
    } else if (data['brand'] is String) {
      brandName = data['brand'] as String;
    }

    // Extract category name
    String categoryName = '';
    if (data['category'] is Map) {
      categoryName = data['category']['name'] as String? ?? '';
    } else if (data['category'] is String) {
      categoryName = data['category'] as String;
    }

    // Extract primary image path if any
    String? primaryImagePath;
    if (data['images'] is List && (data['images'] as List).isNotEmpty) {
      final firstImage = (data['images'] as List).first;
      if (firstImage is Map) {
        primaryImagePath = firstImage['url'] as String?;
      } else if (firstImage is String) {
        primaryImagePath = firstImage;
      }
    }

    // Parse price
    double price = 0.0;
    if (data['price'] is num) {
      price = (data['price'] as num).toDouble();
    } else if (data['basePrice'] is num) {
      price = (data['basePrice'] as num).toDouble();
    }

    return Product(
      id: data['id'] as String,
      name: data['name'] as String? ?? '',
      brand: brandName,
      category: categoryName,
      subcategory: data['subcategory'] as String? ?? 'Casual',
      familyId: data['familyId'] as String?,
      variantId: data['variantId'] as String?,
      price: price,
      description: data['description'] as String?,
      rating: data['rating'] is num ? (data['rating'] as num).toDouble() : (data['avgRating'] is num ? (data['avgRating'] as num).toDouble() : 0.0),
      ratingCount: data['ratingCount'] is int ? data['ratingCount'] as int : (data['reviewCount'] is int ? data['reviewCount'] as int : 0),
      stock: data['stock'] is int ? data['stock'] as int : 10,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      sizes: data['sizes'] is List ? List<String>.from(data['sizes'] as List) : const [],
      colors: data['colors'] is List ? List<String>.from(data['colors'] as List) : const [],
      keywords: data['keywords'] is List ? List<String>.from(data['keywords'] as List) : const [],
      tags: data['tags'] is List ? List<String>.from(data['tags'] as List) : const [],
      thumbnail: data['thumbnail'] as String?,
      multipleImages: data['multipleImages'] is List ? List<String>.from(data['multipleImages'] as List) : const [],
      relatedProducts: data['relatedProducts'] is List ? List<String>.from(data['relatedProducts'] as List) : const [],
      similarProducts: data['similarProducts'] is List ? List<String>.from(data['similarProducts'] as List) : const [],
      recommendedProducts: data['recommendedProducts'] is List ? List<String>.from(data['recommendedProducts'] as List) : const [],
      createdAt: data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      primaryImagePath: primaryImagePath,
    );
  }
}
