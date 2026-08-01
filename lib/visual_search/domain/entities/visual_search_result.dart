import 'dart:io';
import 'package:hopscotch/visual_search/domain/entities/product.dart';
import 'package:hopscotch/visual_search/domain/entities/scored_product.dart';

/// Sealed class for visual search results
/// Represents exact matches, similar matches, or no match
sealed class VisualSearchResult {
  File? queryImage;
  Map<String, dynamic>? extractedAttributes;
  List<Product> exactMatches = [];
  List<Product> similarMatches = [];
}

/// Success result containing exactMatches and similarMatches sections
class VisualSearchSuccessResult extends VisualSearchResult {
  VisualSearchSuccessResult({
    required List<Product> exactMatches,
    required List<Product> similarMatches,
    Map<String, dynamic>? extractedAttributes,
    File? queryImage,
  }) {
    this.exactMatches = exactMatches;
    this.similarMatches = similarMatches;
    this.extractedAttributes = extractedAttributes;
    this.queryImage = queryImage;
  }
}

/// Exact match found - single product with 100% match
class ExactMatch extends VisualSearchResult {
  final Product product;

  ExactMatch(this.product) {
    exactMatches = [product];
  }
}

/// Similar matches found - ranked list of products with scores
class SimilarMatches extends VisualSearchResult {
  final List<ScoredProduct> matches;

  SimilarMatches(this.matches) {
    similarMatches = matches.map((m) => m.product).toList();
  }
}

/// No match found - no products above threshold
class NoMatchFound extends VisualSearchResult {}
