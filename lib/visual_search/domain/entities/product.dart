/// Domain entity for a Product
/// Used by visual search to represent matched products
class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String subcategory;
  final String? familyId;
  final String? variantId;
  final double price;
  final String? description;
  final double rating;
  final int ratingCount;
  final int stock;
  final double discount;
  final List<String> colors;
  final List<String> sizes;
  final List<String> keywords;
  final List<String> tags;
  final String? thumbnail;
  final List<String> multipleImages;
  final List<String> relatedProducts;
  final List<String> similarProducts;
  final List<String> recommendedProducts;
  final String createdAt;
  final String? primaryImagePath;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.subcategory,
    this.familyId,
    this.variantId,
    required this.price,
    this.description,
    required this.rating,
    required this.ratingCount,
    required this.stock,
    required this.discount,
    required this.colors,
    required this.sizes,
    required this.keywords,
    required this.tags,
    this.thumbnail,
    required this.multipleImages,
    required this.relatedProducts,
    required this.similarProducts,
    required this.recommendedProducts,
    required this.createdAt,
    this.primaryImagePath,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
