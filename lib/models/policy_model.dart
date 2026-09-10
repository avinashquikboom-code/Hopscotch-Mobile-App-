class PolicyCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final List<PolicyModel> policies;

  PolicyCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
    this.policies = const [],
  });

  factory PolicyCategoryModel.fromJson(Map<String, dynamic> json) {
    var rawPolicies = json['policies'];
    List<PolicyModel> parsedPolicies = [];
    if (rawPolicies is List) {
      parsedPolicies = rawPolicies
          .whereType<Map<String, dynamic>>()
          .map((p) => PolicyModel.fromJson(p))
          .toList();
    }

    return PolicyCategoryModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder'] as int
          : json['sort_order'] is int
              ? json['sort_order'] as int
              : int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      policies: parsedPolicies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'policies': policies.map((p) => p.toJson()).toList(),
    };
  }
}

class PolicyModel {
  final int id;
  final int categoryId;
  final String? categoryName;
  final String title;
  final String slug;
  final String content;
  final String? metaTitle;
  final String? metaDescription;
  final bool isActive;
  final DateTime? updatedAt;

  PolicyModel({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.title,
    required this.slug,
    required this.content,
    this.metaTitle,
    this.metaDescription,
    this.isActive = true,
    this.updatedAt,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['category'] is Map) {
      catName = json['category']['name']?.toString();
    } else if (json['categoryName'] != null) {
      catName = json['categoryName']?.toString();
    }

    return PolicyModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      categoryId: json['categoryId'] is int
          ? json['categoryId'] as int
          : json['category_id'] is int
              ? json['category_id'] as int
              : int.tryParse(json['categoryId']?.toString() ?? json['category_id']?.toString() ?? '0') ?? 0,
      categoryName: catName,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      metaTitle: json['metaTitle']?.toString() ?? json['meta_title']?.toString(),
      metaDescription: json['metaDescription']?.toString() ?? json['meta_description']?.toString(),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.tryParse(json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '')
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'title': title,
      'slug': slug,
      'content': content,
      'metaTitle': metaTitle,
      'metaDescription': metaDescription,
      'isActive': isActive,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Converts HTML tags to clean readable plain text while maintaining section breaks and bullet points.
  String get plainTextContent {
    if (content.isEmpty) return '';
    var text = content;
    // Normalize newlines for headers and paragraphs
    text = text.replaceAll(RegExp(r'<\s*h[1-6][^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<\s*/\s*h[1-6]\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<\s*p[^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<\s*/\s*p\s*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '\n• ');
    text = text.replaceAll(RegExp(r'<\s*/\s*li\s*>', caseSensitive: false), '');
    // Strip remaining tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    // Unescape common HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    // Collapse multiple blank lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}
