import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/dummy_data/dummy_data.dart';
import '../models/product_model.dart';

class ProductRepository {
  Future<List<ProductModel>> getProducts() async {
    // Simulate networking delay
    await Future.delayed(const Duration(milliseconds: 400));
    return DummyData.dummyProducts.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> getTrendingProducts() async {
    final products = await getProducts();
    return products.where((element) => element.isTrending).toList();
  }

  Future<List<ProductModel>> getNewArrivals() async {
    final products = await getProducts();
    return products.where((element) => element.isNewArrival).toList();
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final products = await getProducts();
    return products.where((element) => element.isFeatured).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final products = await getProducts();
    return products.where((element) => element.categoryId == categoryId).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final products = await getProducts();
    try {
      return products.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final products = await getProducts();
    if (query.isEmpty) return [];
    return products.where((p) => 
      p.title.toLowerCase().contains(query.toLowerCase()) || 
      p.description.toLowerCase().contains(query.toLowerCase()) ||
      p.subcategory.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final allProductsProvider = FutureProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).getProducts();
});

final trendingProductsProvider = FutureProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).getTrendingProducts();
});

final newArrivalsProvider = FutureProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).getNewArrivals();
});

final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).getFeaturedProducts();
});

final categoryProductsProvider = FutureProvider.family<List<ProductModel>, String>((ref, categoryId) {
  return ref.watch(productRepositoryProvider).getProductsByCategory(categoryId);
});

final productDetailProvider = FutureProvider.family<ProductModel?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).getProductById(id);
});
