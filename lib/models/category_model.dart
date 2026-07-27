import 'package:hopscotch/constants/app_urls.dart';

class SubCategoryModel {
  final String id;
  final String name;
  final String imageUrl;

  const SubCategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory SubCategoryModel.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawImg = (map['imageUrl'] ?? map['iconUrl'] ?? map['bannerUrl'] ?? map['image'] ?? '').toString();
    return SubCategoryModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? '').toString(),
      imageUrl: AppUrls.resolveUrl(rawImg),
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

  factory CategoryModel.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    List<SubCategoryModel> subObjs = [];
    List<String> subNames = [];

    final rawSubs = map['children'] ?? map['subcategories'];
    if (rawSubs is List) {
      for (final item in rawSubs) {
        if (item is Map) {
          final subModel = SubCategoryModel.fromJson(item);
          subObjs.add(subModel);
          if (subModel.name.isNotEmpty) subNames.add(subModel.name);
        } else if (item != null) {
          final str = item.toString();
          if (str.isNotEmpty) {
            subNames.add(str);
            subObjs.add(SubCategoryModel(id: str, name: str, imageUrl: ''));
          }
        }
      }
    }

    final rawImg = (map['iconUrl'] ?? map['bannerUrl'] ?? map['imageUrl'] ?? map['image'] ?? '').toString();
    final resolvedImg = AppUrls.resolveUrl(rawImg);

    return CategoryModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? '').toString(),
      imageUrl: resolvedImg,
      icon: map['icon']?.toString() ?? map['iconUrl']?.toString(),
      subcategories: subNames,
      subCategoryObjects: subObjs,
      isFeatured: map['isFeatured'] == true ||
          map['is_featured'] == true ||
          '${map['isFeatured']}' == 'true',
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
          .whereType<Map>()
          .map((e) => CategoryModel.fromJson(e))
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

