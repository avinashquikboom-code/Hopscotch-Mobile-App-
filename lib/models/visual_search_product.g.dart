// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visual_search_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VisualSearchProductImpl _$$VisualSearchProductImplFromJson(
  Map<String, dynamic> json,
) => _$VisualSearchProductImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
  color: json['color'] as String,
  price: (json['price'] as num).toDouble(),
  image: json['image'] as String,
  description: json['description'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  reviewCount: (json['reviewCount'] as num?)?.toInt(),
  isAvailable: json['isAvailable'] as bool?,
  brand: json['brand'] as String?,
);

Map<String, dynamic> _$$VisualSearchProductImplToJson(
  _$VisualSearchProductImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category': instance.category,
  'color': instance.color,
  'price': instance.price,
  'image': instance.image,
  'description': instance.description,
  'rating': instance.rating,
  'reviewCount': instance.reviewCount,
  'isAvailable': instance.isAvailable,
  'brand': instance.brand,
};

_$VisualSearchResultImpl _$$VisualSearchResultImplFromJson(
  Map<String, dynamic> json,
) => _$VisualSearchResultImpl(
  product: VisualSearchProduct.fromJson(
    json['product'] as Map<String, dynamic>,
  ),
  similarityScore: (json['similarityScore'] as num).toDouble(),
  matchType: json['matchType'] as String,
  matchedAttributes: (json['matchedAttributes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$$VisualSearchResultImplToJson(
  _$VisualSearchResultImpl instance,
) => <String, dynamic>{
  'product': instance.product,
  'similarityScore': instance.similarityScore,
  'matchType': instance.matchType,
  'matchedAttributes': instance.matchedAttributes,
};

_$VisualSearchResponseImpl _$$VisualSearchResponseImplFromJson(
  Map<String, dynamic> json,
) => _$VisualSearchResponseImpl(
  results: (json['results'] as List<dynamic>)
      .map((e) => VisualSearchResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: json['status'] as String,
  message: json['message'] as String,
  processingTimeMs: (json['processingTimeMs'] as num).toInt(),
);

Map<String, dynamic> _$$VisualSearchResponseImplToJson(
  _$VisualSearchResponseImpl instance,
) => <String, dynamic>{
  'results': instance.results,
  'status': instance.status,
  'message': instance.message,
  'processingTimeMs': instance.processingTimeMs,
};
