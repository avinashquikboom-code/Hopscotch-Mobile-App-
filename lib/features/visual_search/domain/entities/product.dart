/// Domain entity for a Product
/// Used by visual search to represent matched products
class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String? description;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int ratingCount;
  final int stock;
  final String createdAt;
  final String? primaryImagePath;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.description,
    required this.sizes,
    required this.colors,
    required this.rating,
    required this.ratingCount,
    required this.stock,
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
