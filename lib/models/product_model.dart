import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductReviewModel with _$ProductReviewModel {
  const factory ProductReviewModel({
    required String id,
    required String userName,
    required double rating,
    required String comment,
    required String date,
    String? userAvatarUrl,
  }) = _ProductReviewModel;

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) => _$ProductReviewModelFromJson(json);
}

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required String id,
    required String title,
    required String description,
    required double price,
    required double originalPrice,
    required double discountPercentage,
    required String imageUrl,
    @Default([]) List<String> additionalImages,
    required String categoryId,
    @Default('Collections') String subcategory,
    required double rating,
    required int reviewCount,
    @Default([]) List<ProductReviewModel> reviews,
    @Default([]) List<String> sizes,
    @Default([]) List<String> colors,
    @Default(true) bool isAvailable,
    @Default(false) bool isTrending,
    @Default(false) bool isNewArrival,
    @Default(false) bool isFeatured,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);
}
