import 'package:freezed_annotation/freezed_annotation.dart';

part 'visual_search_product.freezed.dart';
part 'visual_search_product.g.dart';

@freezed
class VisualSearchProduct with _$VisualSearchProduct {
  const factory VisualSearchProduct({
    required String id,
    required String name,
    required String category,
    required String color,
    required double price,
    required String image,
    String? description,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    String? brand,
  }) = _VisualSearchProduct;

  factory VisualSearchProduct.fromJson(Map<String, dynamic> json) =>
      _$VisualSearchProductFromJson(json);
}

@freezed
class VisualSearchResult with _$VisualSearchResult {
  const factory VisualSearchResult({
    required VisualSearchProduct product,
    required double similarityScore,
    required String matchType, // 'exact' or 'similar'
    List<String>? matchedAttributes, // e.g., ['color', 'category', 'pattern']
  }) = _VisualSearchResult;

  factory VisualSearchResult.fromJson(Map<String, dynamic> json) =>
      _$VisualSearchResultFromJson(json);
}

@freezed
class VisualSearchResponse with _$VisualSearchResponse {
  const factory VisualSearchResponse({
    required List<VisualSearchResult> results,
    required String status, // 'success', 'partial_match', 'no_match'
    required String message,
    required int processingTimeMs,
  }) = _VisualSearchResponse;

  factory VisualSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$VisualSearchResponseFromJson(json);
}
