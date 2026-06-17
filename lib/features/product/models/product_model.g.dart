// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductReviewModelImpl _$$ProductReviewModelImplFromJson(
  Map<String, dynamic> json,
) => _$ProductReviewModelImpl(
  id: json['id'] as String,
  userName: json['userName'] as String,
  rating: (json['rating'] as num).toDouble(),
  comment: json['comment'] as String,
  date: json['date'] as String,
  userAvatarUrl: json['userAvatarUrl'] as String?,
);

Map<String, dynamic> _$$ProductReviewModelImplToJson(
  _$ProductReviewModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userName': instance.userName,
  'rating': instance.rating,
  'comment': instance.comment,
  'date': instance.date,
  'userAvatarUrl': instance.userAvatarUrl,
};

_$ProductModelImpl _$$ProductModelImplFromJson(
  Map<String, dynamic> json,
) => _$ProductModelImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  originalPrice: (json['originalPrice'] as num).toDouble(),
  discountPercentage: (json['discountPercentage'] as num).toDouble(),
  imageUrl: json['imageUrl'] as String,
  additionalImages:
      (json['additionalImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  categoryId: json['categoryId'] as String,
  subcategory: json['subcategory'] as String,
  rating: (json['rating'] as num).toDouble(),
  reviewCount: (json['reviewCount'] as num).toInt(),
  reviews:
      (json['reviews'] as List<dynamic>?)
          ?.map((e) => ProductReviewModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  sizes:
      (json['sizes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  colors:
      (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isAvailable: json['isAvailable'] as bool? ?? true,
  isTrending: json['isTrending'] as bool? ?? false,
  isNewArrival: json['isNewArrival'] as bool? ?? false,
  isFeatured: json['isFeatured'] as bool? ?? false,
);

Map<String, dynamic> _$$ProductModelImplToJson(_$ProductModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'originalPrice': instance.originalPrice,
      'discountPercentage': instance.discountPercentage,
      'imageUrl': instance.imageUrl,
      'additionalImages': instance.additionalImages,
      'categoryId': instance.categoryId,
      'subcategory': instance.subcategory,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'reviews': instance.reviews,
      'sizes': instance.sizes,
      'colors': instance.colors,
      'isAvailable': instance.isAvailable,
      'isTrending': instance.isTrending,
      'isNewArrival': instance.isNewArrival,
      'isFeatured': instance.isFeatured,
    };
