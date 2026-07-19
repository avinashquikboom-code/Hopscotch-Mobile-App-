class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final String? icon;
  final List<String> subcategories;
  final bool isFeatured;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.icon,
    this.subcategories = const [],
    this.isFeatured = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['image'] ?? '').toString(),
      icon: json['icon'] as String?,
      subcategories: json['subcategories'] is List
          ? (json['subcategories'] as List).map((e) => e.toString()).toList()
          : const [],
      isFeatured: json['isFeatured'] == true ||
          json['is_featured'] == true ||
          '${json['isFeatured']}' == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'icon': icon,
      'subcategories': subcategories,
      'isFeatured': isFeatured,
    };
  }

  static List<CategoryModel> listFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    }
    return [];
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? icon,
    List<String>? subcategories,
    bool? isFeatured,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      subcategories: subcategories ?? this.subcategories,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is CategoryModel && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}
