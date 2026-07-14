import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:hopscotch/visual_search/data/datasources/database_helper.dart';
import 'package:hopscotch/visual_search/domain/entities/product.dart';

/// Data source for local product data
/// Handles SQLite operations for products, images, and signatures
class LocalProductDataSource {
  final VisualSearchDatabaseHelper _dbHelper;

  LocalProductDataSource(this._dbHelper);

  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return maps.map((map) => _mapToProduct(map)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _mapToProduct(maps.first);
  }

  Future<List<Map<String, dynamic>>> getProductImages(String productId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'product_images',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'sort_order ASC',
    );
  }

  Future<Map<String, dynamic>?> getImageSignature(String imageId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'product_image_signatures',
      where: 'image_id = ?',
      whereArgs: [imageId],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.insert('products', _productToMap(product));
  }

  Future<void> insertProductImage(Map<String, dynamic> image) async {
    final db = await _dbHelper.database;
    await db.insert('product_images', image);
  }

  Future<void> insertImageSignature(Map<String, dynamic> signature) async {
    final db = await _dbHelper.database;
    await db.insert('product_image_signatures', signature);
  }

  Future<bool> isSeeded() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Product _mapToProduct(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String,
      category: map['category'] as String,
      subcategory: map['subcategory'] as String? ?? 'Casual',
      familyId: map['family_id'] as String?,
      variantId: map['variant_id'] as String?,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String?,
      rating: (map['rating'] as num).toDouble(),
      ratingCount: map['rating_count'] as int,
      stock: map['stock'] as int,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      colors: List<String>.from(jsonDecode(map['colors'] as String)),
      sizes: List<String>.from(jsonDecode(map['sizes'] as String)),
      keywords: map['keywords'] != null ? List<String>.from(jsonDecode(map['keywords'] as String)) : const [],
      tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'] as String)) : const [],
      thumbnail: map['thumbnail'] as String?,
      multipleImages: map['multiple_images'] != null ? List<String>.from(jsonDecode(map['multiple_images'] as String)) : const [],
      relatedProducts: map['related_products'] != null ? List<String>.from(jsonDecode(map['related_products'] as String)) : const [],
      similarProducts: map['similar_products'] != null ? List<String>.from(jsonDecode(map['similar_products'] as String)) : const [],
      recommendedProducts: map['recommended_products'] != null ? List<String>.from(jsonDecode(map['recommended_products'] as String)) : const [],
      createdAt: map['created_at'] as String,
      primaryImagePath: map['primary_image_path'] as String?,
    );
  }

  Map<String, dynamic> _productToMap(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'brand': product.brand,
      'category': product.category,
      'price': product.price,
      'description': product.description,
      'sizes': jsonEncode(product.sizes),
      'colors': jsonEncode(product.colors),
      'rating': product.rating,
      'rating_count': product.ratingCount,
      'stock': product.stock,
      'created_at': product.createdAt,
    };
  }
}
