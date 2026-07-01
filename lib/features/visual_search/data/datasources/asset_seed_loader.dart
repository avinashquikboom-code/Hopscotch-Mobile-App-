import 'dart:convert';
import 'package:flutter/services.dart';
import 'local_product_datasource.dart';
import '../../domain/entities/product.dart';

/// Loads seed data from assets and populates the database
/// Runs once on first app launch
class AssetSeedLoader {
  final LocalProductDataSource _dataSource;

  AssetSeedLoader(this._dataSource);

  Future<bool> isSeeded() async {
    return await _dataSource.isSeeded();
  }

  Future<void> seedDatabase() async {
    if (await isSeeded()) {
      return; // Already seeded
    }

    try {
      // Load products JSON from assets
      final jsonString = await rootBundle.loadString('assets/data/products.json');
      final jsonData = jsonDecode(jsonString) as List;

      for (final item in jsonData) {
        final productMap = item as Map<String, dynamic>;
        final product = Product(
          id: productMap['id'] as String,
          name: productMap['name'] as String,
          brand: productMap['brand'] as String,
          category: productMap['category'] as String,
          price: (productMap['price'] as num).toDouble(),
          description: productMap['description'] as String?,
          sizes: List<String>.from(productMap['sizes'] as List),
          colors: List<String>.from(productMap['colors'] as List),
          rating: (productMap['rating'] as num?)?.toDouble() ?? 0.0,
          ratingCount: (productMap['rating_count'] as int?) ?? 0,
          stock: (productMap['stock'] as int?) ?? 0,
          createdAt: productMap['created_at'] as String? ?? DateTime.now().toIso8601String(),
        );

        await _dataSource.insertProduct(product);

        // Insert product images
        final images = productMap['images'] as List?;
        if (images != null) {
          for (int i = 0; i < images.length; i++) {
            final img = images[i] as Map<String, dynamic>;
            await _dataSource.insertProductImage({
              'id': img['id'] as String,
              'product_id': product.id,
              'asset_path': img['asset_path'] as String,
              'is_primary': (img['is_primary'] as bool?) ?? false ? 1 : 0,
              'sort_order': i,
            });
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to seed database: $e');
    }
  }
}
