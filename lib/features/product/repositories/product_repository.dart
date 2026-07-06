import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/providers/api_provider.dart';
import '../../../../core/dummy_data/dummy_data.dart';
import '../models/product_model.dart';

ProductModel mapBackendToMobileProduct(Map<String, dynamic> raw) {
  final id = raw['id']?.toString() ?? '';
  final title = raw['name']?.toString() ?? 'Unnamed';
  final description = raw['description']?.toString() ?? '';
  
  final price = (raw['price'] as num?)?.toDouble() ?? 
                (raw['basePrice'] as num?)?.toDouble() ?? 0.0;
  
  final discountValue = (raw['discountValue'] as num?)?.toDouble() ?? 0.0;
  
  const apiBase = ApiService.baseUrl;
  
  String imageUrl = 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&auto=format&fit=crop&q=80';
  List<String> additionalImages = [];
  
  final rawImages = raw['images'] as List?;
  if (rawImages != null && rawImages.isNotEmpty) {
    for (var i = 0; i < rawImages.length; i++) {
      final img = rawImages[i];
      String imgUrl = '';
      if (img is Map) {
        imgUrl = img['url']?.toString() ?? '';
      } else {
        imgUrl = img.toString();
      }
      
      if (imgUrl.isNotEmpty) {
        if (!imgUrl.startsWith('http')) {
          imgUrl = '$apiBase/$imgUrl';
        }
        if (i == 0) {
          imageUrl = imgUrl;
        } else {
          additionalImages.add(imgUrl);
        }
      }
    }
  } else if (raw['thumbnailUrl'] != null) {
    final thumb = raw['thumbnailUrl'].toString();
    imageUrl = thumb.startsWith('http') ? thumb : '$apiBase/$thumb';
  }

  final categoryName = raw['category']?['name']?.toString() ?? 'Collections';
  final categoryId = raw['categoryId']?.toString() ?? '1';
  final isTrending = raw['isTrending'] as bool? ?? false;
  final isNewArrival = raw['isNewArrival'] as bool? ?? false;
  final isFeatured = raw['isFeatured'] as bool? ?? false;
  final rating = (raw['avgRating'] as num?)?.toDouble() ?? 4.5;
  final reviewCount = (raw['reviewCount'] as num?)?.toInt() ?? 0;
  
  final rawVariants = raw['variants'] as List?;
  List<String> sizes = [];
  List<String> colors = [];
  if (rawVariants != null) {
    for (var v in rawVariants) {
      if (v is Map) {
        if (v['size'] != null && !sizes.contains(v['size'].toString())) {
          sizes.add(v['size'].toString());
        }
        if (v['color'] != null && !colors.contains(v['color'].toString())) {
          colors.add(v['color'].toString());
        }
      }
    }
  }

  if (sizes.isEmpty) sizes = ['S', 'M', 'L', 'XL'];
  if (colors.isEmpty) colors = ['Beige', 'Black', 'Olive'];

  return ProductModel(
    id: id,
    title: title,
    description: description,
    price: price,
    originalPrice: price,
    discountPercentage: discountValue,
    imageUrl: imageUrl,
    additionalImages: additionalImages,
    categoryId: categoryId,
    subcategory: categoryName,
    rating: rating,
    reviewCount: reviewCount,
    reviews: [],
    sizes: sizes,
    colors: colors,
    isAvailable: true,
    isTrending: isTrending,
    isNewArrival: isNewArrival,
    isFeatured: isFeatured,
  );
}

class ProductRepository {
  final ApiService _apiService;

  ProductRepository(this._apiService);

  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _apiService.get('/api/products');
      if (response.statusCode == 200) {
        final data = response.data;
        final List? rawList = data is Map ? data['data'] : data;
        if (rawList != null) {
          return rawList.map((e) => mapBackendToMobileProduct(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (e) {
      print('[ProductRepository] Error fetching products: $e');
    }

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
    try {
      final response = await _apiService.get('/api/products/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        final raw = data is Map ? data['data'] : data;
        if (raw != null) {
          return mapBackendToMobileProduct(Map<String, dynamic>.from(raw));
        }
      }
    } catch (e) {
      print('[ProductRepository] Error fetching product details: $e');
    }

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

  Future<List<ProductModel>> searchProductsByImage(String imagePath) async {
    final products = await getProducts();
    await Future.delayed(const Duration(seconds: 2));
    products.shuffle();
    return products.take(4).toList();
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProductRepository(apiService);
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
