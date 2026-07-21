class SubCategoryModel {
  final String id;
  final String name;
  final String imageUrl;

  const SubCategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['iconUrl'] ?? json['bannerUrl'] ?? json['image'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final String? icon;
  final List<String> subcategories;
  final List<SubCategoryModel> subCategoryObjects;
  final bool isFeatured;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.icon,
    this.subcategories = const [],
    this.subCategoryObjects = const [],
    this.isFeatured = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    List<SubCategoryModel> subObjs = [];
    List<String> subNames = [];

    final rawSubs = json['children'] ?? json['subcategories'];
    if (rawSubs is List) {
      for (final item in rawSubs) {
        if (item is Map<String, dynamic>) {
          subObjs.add(SubCategoryModel.fromJson(item));
          final nameStr = item['name']?.toString() ?? '';
          if (nameStr.isNotEmpty) subNames.add(nameStr);
        } else if (item != null) {
          final str = item.toString();
          if (str.isNotEmpty) {
            subNames.add(str);
            subObjs.add(SubCategoryModel(id: str, name: str, imageUrl: ''));
          }
        }
      }
    }

    return CategoryModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['iconUrl'] ?? json['bannerUrl'] ?? json['image'] ?? '').toString(),
      icon: json['icon'] as String?,
      subcategories: subNames,
      subCategoryObjects: subObjs,
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
      'subCategoryObjects': subCategoryObjects.map((s) => s.toJson()).toList(),
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
    List<SubCategoryModel>? subCategoryObjects,
    bool? isFeatured,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      subcategories: subcategories ?? this.subcategories,
      subCategoryObjects: subCategoryObjects ?? this.subCategoryObjects,
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
