import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/utils/dev_logger.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/product_model.dart';

ProductModel mapBackendToMobileProduct(Map<String, dynamic> raw) {
  final id = raw['id']?.toString() ?? '';
  final title = raw['name']?.toString() ?? 'Unnamed';
  final description = raw['description']?.toString() ?? '';
  
  // Safely parse price/basePrice (handles both num and string representation of decimals)
  double price = 0.0;
  if (raw['price'] != null) {
    if (raw['price'] is num) {
      price = (raw['price'] as num).toDouble();
    } else {
      price = double.tryParse(raw['price'].toString()) ?? 0.0;
    }
  } else if (raw['basePrice'] != null) {
    if (raw['basePrice'] is num) {
      price = (raw['basePrice'] as num).toDouble();
    } else {
      price = double.tryParse(raw['basePrice'].toString()) ?? 0.0;
    }
  }
  
  // Safely parse discountValue
  double discountValue = 0.0;
  if (raw['discountValue'] != null) {
    if (raw['discountValue'] is num) {
      discountValue = (raw['discountValue'] as num).toDouble();
    } else {
      discountValue = double.tryParse(raw['discountValue'].toString()) ?? 0.0;
    }
  }
  
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
        final resolvedImgUrl = AppUrls.resolveUrl(imgUrl);
        if (i == 0) {
          imageUrl = resolvedImgUrl;
        } else {
          additionalImages.add(resolvedImgUrl);
        }
      }
    }
  } else if (raw['thumbnailUrl'] != null) {
    final thumb = raw['thumbnailUrl'].toString();
    imageUrl = AppUrls.resolveUrl(thumb);
  }

  final categoryName = raw['category']?['name']?.toString() ?? 'Collections';
  final categoryId = raw['categoryId']?.toString() ?? '1';
  final isTrending = raw['isTrending'] as bool? ?? false;
  final isNewArrival = raw['isNewArrival'] as bool? ?? false;
  final isFeatured = raw['isFeatured'] as bool? ?? false;
  
  // Safely parse avgRating
  double rating = 4.5;
  if (raw['avgRating'] != null) {
    if (raw['avgRating'] is num) {
      rating = (raw['avgRating'] as num).toDouble();
    } else {
      rating = double.tryParse(raw['avgRating'].toString()) ?? 4.5;
    }
  }

  // Safely parse reviewCount
  int reviewCount = 0;
  if (raw['reviewCount'] != null) {
    if (raw['reviewCount'] is num) {
      reviewCount = (raw['reviewCount'] as num).toInt();
    } else {
      reviewCount = int.tryParse(raw['reviewCount'].toString()) ?? 0;
    }
  }
  
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
      final response = await _apiService.get(AppUrls.products);
      if (response.statusCode == 200) {
        final data = response.data;
        List? rawList;
        if (data is Map) {
          final dataField = data['data'];
          if (dataField is Map) {
            rawList = dataField['products'] as List?;
          } else if (dataField is List) {
            rawList = dataField;
          }
        }
        if (rawList != null) {
          return rawList.map((e) => mapBackendToMobileProduct(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (e) {
      DevLogger.logError('Error fetching products: $e', context: 'ProductRepository');
      throw Exception('Failed to fetch products');
    }

    return [];
  }

  Future<List<ProductModel>> getTrendingProducts() async {
    final products = await getProducts();
    final filtered = products.where((element) => element.isTrending).toList();
    if (filtered.isEmpty && products.isNotEmpty) {
      return products.take(6).toList();
    }
    return filtered;
  }

  Future<List<ProductModel>> getNewArrivals() async {
    final products = await getProducts();
    final filtered = products.where((element) => element.isNewArrival).toList();
    if (filtered.isEmpty && products.isNotEmpty) {
      return products.reversed.take(6).toList();
    }
    return filtered;
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final products = await getProducts();
    final filtered = products.where((element) => element.isFeatured).toList();
    if (filtered.isEmpty && products.isNotEmpty) {
      return products.take(6).toList();
    }
    return filtered;
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
      DevLogger.logError('Error fetching product details: $e', context: 'ProductRepository');
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
