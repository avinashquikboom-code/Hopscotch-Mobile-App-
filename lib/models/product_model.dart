String _asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

double _asDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

bool _asBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final s = value.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}

class ProductReviewModel {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final String date;
  final String? userAvatarUrl;

  const ProductReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.userAvatarUrl,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      id: _asString(json['id'] ?? json['_id']),
      userName: _asString(json['userName'] ?? json['user_name'] ?? json['name']),
      rating: _asDouble(json['rating']),
      comment: _asString(json['comment'] ?? json['review'] ?? json['text']),
      date: _asString(json['date'] ?? json['createdAt'] ?? json['created_at']),
      userAvatarUrl: json['userAvatarUrl'] as String? ?? json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'date': date,
      'userAvatarUrl': userAvatarUrl,
    };
  }

  static List<ProductReviewModel> listFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(ProductReviewModel.fromJson)
          .toList();
    }
    return [];
  }

  ProductReviewModel copyWith({
    String? id,
    String? userName,
    double? rating,
    String? comment,
    String? date,
    String? userAvatarUrl,
  }) {
    return ProductReviewModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ProductReviewModel && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}

class ProductVariantModel {
  final String id;
  final String? size;
  final String? color;
  final double price;
  final int stock;
  final String? imageUrl;

  const ProductVariantModel({
    required this.id,
    this.size,
    this.color,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: _asString(json['id'] ?? json['_id']),
      size: json['size']?.toString().trim(),
      color: json['color']?.toString().trim(),
      price: _asDouble(json['price']),
      stock: _asInt(json['stock'] ?? json['quantity']),
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'size': size,
      'color': color,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }

  static List<ProductVariantModel> listFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(ProductVariantModel.fromJson)
          .toList();
    }
    return [];
  }
}

class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final double originalPrice;
  final double discountPercentage;
  final String imageUrl;
  final List<String> additionalImages;
  final String categoryId;
  final String subcategory;
  final double rating;
  final int reviewCount;
  final List<ProductReviewModel> reviews;
  final List<String> sizes;
  final List<String> colors;
  final List<ProductVariantModel> variants;
  final bool isAvailable;
  final bool isTrending;
  final bool isNewArrival;
  final bool isFeatured;
  final double taxPercent;
  final String taxType;
  final String? hsnCode;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.discountPercentage,
    required this.imageUrl,
    this.additionalImages = const [],
    required this.categoryId,
    this.subcategory = 'Collections',
    required this.rating,
    required this.reviewCount,
    this.reviews = const [],
    this.sizes = const [],
    this.colors = const [],
    this.variants = const [],
    this.isAvailable = true,
    this.isTrending = false,
    this.isNewArrival = false,
    this.isFeatured = false,
    this.taxPercent = 0.0,
    this.taxType = 'EXCLUSIVE',
    this.hsnCode,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final effectiveTax = json['effectiveTaxRule'] ?? json['taxRule'];
    final parsedTaxRate = _asDouble(
      json['taxPercent'] ?? json['tax_percent'] ?? (effectiveTax is Map ? (effectiveTax['rate'] ?? effectiveTax['taxPercent']) : null),
    );
    final parsedTaxType = _asString(
      json['taxType'] ?? json['tax_type'] ?? (effectiveTax is Map ? (effectiveTax['taxType'] ?? effectiveTax['type']) : null),
      'EXCLUSIVE',
    );
    final parsedHsn = _asString(
      json['hsnCode'] ?? json['hsn_code'] ?? (effectiveTax is Map ? effectiveTax['hsnCode'] : null),
    );

    return ProductModel(
      id: _asString(json['id'] ?? json['_id']),
      title: _asString(json['title'] ?? json['name']),
      description: _asString(json['description']),
      price: _asDouble(json['price']),
      originalPrice: _asDouble(json['originalPrice'] ?? json['original_price'] ?? json['price']),
      discountPercentage: _asDouble(json['discountPercentage'] ?? json['discount_percentage']),
      imageUrl: () {
        final direct = json['imageUrl'] ?? json['image_url'] ?? json['image'];
        if (direct != null && direct.toString().trim().isNotEmpty) {
          return direct.toString().trim();
        }
        final imgs = json['images'];
        if (imgs is List && imgs.isNotEmpty) {
          final first = imgs.first;
          if (first is String) return first;
          if (first is Map) {
            return (first['url'] ?? first['imageUrl'] ?? first['image_url'] ?? '').toString();
          }
        }
        return '';
      }(),
      additionalImages: _asStringList(json['additionalImages'] ?? json['additional_images']),
      categoryId: _asString(json['categoryId'] ?? json['category_id'] ?? json['category']),
      subcategory: _asString(json['subcategory'], 'Collections'),
      rating: _asDouble(json['rating']),
      reviewCount: _asInt(json['reviewCount'] ?? json['review_count']),
      reviews: ProductReviewModel.listFromJson(json['reviews']),
      sizes: () {
        final direct = _asStringList(json['sizes']);
        if (direct.isNotEmpty) return direct;
        final vars = json['variants'];
        if (vars is List) {
          final extracted = <String>{};
          for (final v in vars) {
            if (v is Map) {
              final s = v['size']?.toString().trim();
              if (s != null && s.isNotEmpty && s != 'One Size') {
                extracted.add(s);
              }
            }
          }
          if (extracted.isNotEmpty) return extracted.toList();
        }
        return <String>[];
      }(),
      colors: () {
        final direct = _asStringList(json['colors']);
        if (direct.isNotEmpty) return direct;
        final vars = json['variants'];
        if (vars is List) {
          final extracted = <String>{};
          for (final v in vars) {
            if (v is Map) {
              final c = v['color']?.toString().trim();
              if (c != null && c.isNotEmpty && c != 'Default') {
                extracted.add(c);
              }
            }
          }
          if (extracted.isNotEmpty) return extracted.toList();
        }
        return <String>[];
      }(),
      variants: ProductVariantModel.listFromJson(json['variants']),
      isAvailable: _asBool(json['isAvailable'] ?? json['is_available'], true),
      isTrending: _asBool(json['isTrending'] ?? json['is_trending']),
      isNewArrival: _asBool(json['isNewArrival'] ?? json['is_new_arrival']),
      isFeatured: _asBool(json['isFeatured'] ?? json['is_featured']),
      taxPercent: parsedTaxRate,
      taxType: parsedTaxType,
      hsnCode: parsedHsn.isNotEmpty ? parsedHsn : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'categoryId': categoryId,
      'subcategory': subcategory,
      'rating': rating,
      'reviewCount': reviewCount,
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'sizes': sizes,
      'colors': colors,
      'isAvailable': isAvailable,
      'isTrending': isTrending,
      'isNewArrival': isNewArrival,
      'isFeatured': isFeatured,
    };
  }

  static List<ProductModel> listFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    }
    return [];
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? originalPrice,
    double? discountPercentage,
    String? imageUrl,
    List<String>? additionalImages,
    String? categoryId,
    String? subcategory,
    double? rating,
    int? reviewCount,
    List<ProductReviewModel>? reviews,
    List<String>? sizes,
    List<String>? colors,
    bool? isAvailable,
    bool? isTrending,
    bool? isNewArrival,
    bool? isFeatured,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      reviews: reviews ?? this.reviews,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      isAvailable: isAvailable ?? this.isAvailable,
      isTrending: isTrending ?? this.isTrending,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is ProductModel && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}
