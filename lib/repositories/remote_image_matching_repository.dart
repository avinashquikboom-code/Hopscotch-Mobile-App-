import 'dart:io';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/visual_search/domain/entities/product.dart';
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
      
      final rawExact = response['exactMatches'] as List<dynamic>? ?? [];
      final rawSimilar = response['similarMatches'] as List<dynamic>? ?? [];
      final extractedAttributes = response['extractedAttributes'] as Map<String, dynamic>?;

      final List<Product> exactMatches = rawExact.map((item) => _convertToProduct(item)).toList();
      final List<Product> similarMatches = rawSimilar.map((item) => _convertToProduct(item)).toList();

      if (exactMatches.isEmpty && similarMatches.isEmpty) {
        final noMatch = NoMatchFound();
        noMatch.queryImage = image;
        noMatch.extractedAttributes = extractedAttributes;
        return noMatch;
      }

      return VisualSearchSuccessResult(
        exactMatches: exactMatches,
        similarMatches: similarMatches,
        extractedAttributes: extractedAttributes,
        queryImage: image,
      );
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      throw NetworkFailure('Unable to search image: $msg');
    } catch (e) {
      throw UnknownFailure('An unexpected error occurred during visual search: $e');
    }
  }

  /// Convert API response product map to Flutter Product entity
  Product _convertToProduct(dynamic data) {
    if (data is! Map) {
      return Product(
        id: '0',
        name: 'Unknown Item',
        brand: 'Luxury',
        category: 'Fashion',
        subcategory: 'Apparel',
        price: 0.0,
        rating: 4.5,
        ratingCount: 10,
        stock: 5,
        discount: 0.0,
        colors: const [],
        sizes: const [],
        keywords: const [],
        tags: const [],
        multipleImages: const [],
        relatedProducts: const [],
        similarProducts: const [],
        recommendedProducts: const [],
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    final map = data.cast<String, dynamic>();

    // Brand extraction
    String brandName = 'FCISeller';
    if (map['brand'] is Map) {
      brandName = (map['brand'] as Map)['name']?.toString() ?? 'FCISeller';
    } else if (map['brand'] != null) {
      brandName = map['brand'].toString();
    }

    // Category extraction
    String categoryName = 'Clothing';
    if (map['category'] is Map) {
      categoryName = (map['category'] as Map)['name']?.toString() ?? 'Clothing';
    } else if (map['category'] != null) {
      categoryName = map['category'].toString();
    }

    // Image URL resolution
    String? primaryImagePath = map['thumbnailUrl']?.toString();
    if ((primaryImagePath == null || primaryImagePath.isEmpty) && map['images'] is List && (map['images'] as List).isNotEmpty) {
      final firstImg = (map['images'] as List).first;
      if (firstImg is Map && firstImg['url'] != null) {
        primaryImagePath = firstImg['url'].toString();
      } else if (firstImg is String) {
        primaryImagePath = firstImg;
      }
    }

    if (primaryImagePath != null && primaryImagePath.isNotEmpty) {
      primaryImagePath = AppUrls.resolveUrl(primaryImagePath);
    }

    // Price resolution
    double price = 0.0;
    if (map['basePrice'] != null) {
      price = double.tryParse(map['basePrice'].toString()) ?? 0.0;
    } else if (map['price'] != null) {
      price = double.tryParse(map['price'].toString()) ?? 0.0;
    }

    // Extract variants colors & sizes
    final List<String> colors = [];
    final List<String> sizes = [];

    if (map['variants'] is List) {
      for (final v in (map['variants'] as List)) {
        if (v is Map) {
          if (v['color'] != null && !colors.contains(v['color'].toString())) {
            colors.add(v['color'].toString());
          }
          if (v['size'] != null && !sizes.contains(v['size'].toString())) {
            sizes.add(v['size'].toString());
          }
        }
      }
    }

    return Product(
      id: map['id']?.toString() ?? '0',
      name: map['name']?.toString() ?? 'Product',
      brand: brandName,
      category: categoryName,
      subcategory: map['subcategory']?.toString() ?? 'Apparel',
      familyId: map['familyId']?.toString(),
      variantId: map['variantId']?.toString(),
      price: price,
      description: map['description']?.toString(),
      rating: double.tryParse(map['avgRating']?.toString() ?? map['rating']?.toString() ?? '4.2') ?? 4.2,
      ratingCount: int.tryParse(map['reviewCount']?.toString() ?? map['ratingCount']?.toString() ?? '25') ?? 25,
      stock: int.tryParse(map['stock']?.toString() ?? '10') ?? 10,
      discount: double.tryParse(map['discount']?.toString() ?? '0.0') ?? 0.0,
      colors: colors,
      sizes: sizes,
      keywords: map['keywords'] is List ? List<String>.from(map['keywords'] as List) : const [],
      tags: map['tags'] is List ? List<String>.from(map['tags'] as List) : const [],
      thumbnail: primaryImagePath,
      multipleImages: const [],
      relatedProducts: const [],
      similarProducts: const [],
      recommendedProducts: const [],
      createdAt: map['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      primaryImagePath: primaryImagePath,
    );
  }
}
