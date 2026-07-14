import 'package:hopscotch/visual_search/domain/entities/product.dart';

/// Product with a similarity score (0.0 - 1.0)
/// Used for similar product results
class ScoredProduct {
  final Product product;
  final double similarityScore;

  ScoredProduct({
    required this.product,
    required this.similarityScore,
  });

  /// Convert similarity score to percentage (e.g., 0.95 -> "95%")
  String get percentage => '${(similarityScore * 100).toStringAsFixed(0)}%';
}
