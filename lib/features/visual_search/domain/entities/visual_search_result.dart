import 'product.dart';
import 'scored_product.dart';

/// Sealed class for visual search results
/// Represents either an exact match, similar matches, or no match
sealed class VisualSearchResult {}

/// Exact match found - single product with 100% match
class ExactMatch extends VisualSearchResult {
  final Product product;

  ExactMatch(this.product);
}

/// Similar matches found - ranked list of products with scores
class SimilarMatches extends VisualSearchResult {
  final List<ScoredProduct> matches;

  SimilarMatches(this.matches);
}

/// No match found - no products above threshold
class NoMatchFound extends VisualSearchResult {}
