class VisualSearchProduct {
  final String id;
  final String name;
  final String category;
  final String color;
  final double price;
  final String image;
  final String? description;
  final double? rating;
  final int? reviewCount;
  final bool? isAvailable;
  final String? brand;

  const VisualSearchProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.price,
    required this.image,
    this.description,
    this.rating,
    this.reviewCount,
    this.isAvailable,
    this.brand,
  });

  factory VisualSearchProduct.fromJson(Map<String, dynamic> json) {
    return VisualSearchProduct(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse('${json['price']}') ?? 0.0,
      image: (json['image'] ?? json['imageUrl'] ?? '').toString(),
      description: json['description'] as String?,
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : null,
      reviewCount:
          json['reviewCount'] is num ? (json['reviewCount'] as num).toInt() : null,
      isAvailable: json['isAvailable'] as bool?,
      brand: json['brand'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'color': color,
      'price': price,
      'image': image,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'brand': brand,
    };
  }

  static List<VisualSearchProduct> listFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(VisualSearchProduct.fromJson)
          .toList();
    }
    return [];
  }

  VisualSearchProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? color,
    double? price,
    String? image,
    String? description,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    String? brand,
  }) {
    return VisualSearchProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      brand: brand ?? this.brand,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is VisualSearchProduct && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}

class VisualSearchResult {
  final VisualSearchProduct product;
  final double similarityScore;
  final String matchType; // 'exact' or 'similar'
  final List<String>? matchedAttributes; // e.g., ['color', 'category', 'pattern']

  const VisualSearchResult({
    required this.product,
    required this.similarityScore,
    required this.matchType,
    this.matchedAttributes,
  });

  factory VisualSearchResult.fromJson(Map<String, dynamic> json) {
    return VisualSearchResult(
      product: VisualSearchProduct.fromJson(
        (json['product'] as Map<String, dynamic>?) ?? const {},
      ),
      similarityScore: json['similarityScore'] is num
          ? (json['similarityScore'] as num).toDouble()
          : double.tryParse('${json['similarityScore']}') ?? 0.0,
      matchType: (json['matchType'] ?? 'similar').toString(),
      matchedAttributes: json['matchedAttributes'] is List
          ? (json['matchedAttributes'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'similarityScore': similarityScore,
      'matchType': matchType,
      'matchedAttributes': matchedAttributes,
    };
  }

  static List<VisualSearchResult> listFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(VisualSearchResult.fromJson)
          .toList();
    }
    return [];
  }

  VisualSearchResult copyWith({
    VisualSearchProduct? product,
    double? similarityScore,
    String? matchType,
    List<String>? matchedAttributes,
  }) {
    return VisualSearchResult(
      product: product ?? this.product,
      similarityScore: similarityScore ?? this.similarityScore,
      matchType: matchType ?? this.matchType,
      matchedAttributes: matchedAttributes ?? this.matchedAttributes,
    );
  }
}

class VisualSearchResponse {
  final List<VisualSearchResult> results;
  final String status; // 'success', 'partial_match', 'no_match'
  final String message;
  final int processingTimeMs;

  const VisualSearchResponse({
    required this.results,
    required this.status,
    required this.message,
    required this.processingTimeMs,
  });

  factory VisualSearchResponse.fromJson(Map<String, dynamic> json) {
    return VisualSearchResponse(
      results: VisualSearchResult.listFromJson(json['results']),
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      processingTimeMs: json['processingTimeMs'] is num
          ? (json['processingTimeMs'] as num).toInt()
          : int.tryParse('${json['processingTimeMs']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((e) => e.toJson()).toList(),
      'status': status,
      'message': message,
      'processingTimeMs': processingTimeMs,
    };
  }

  VisualSearchResponse copyWith({
    List<VisualSearchResult>? results,
    String? status,
    String? message,
    int? processingTimeMs,
  }) {
    return VisualSearchResponse(
      results: results ?? this.results,
      status: status ?? this.status,
      message: message ?? this.message,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
    );
  }
}
