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

  double shippingCharge = 0.0;
  final rawShipping = raw['shippingCharge'] ?? raw['shipping_charge'] ?? raw['shippingFee'] ?? raw['shipping_fee'];
  if (rawShipping != null) {
    if (rawShipping is num) {
      shippingCharge = rawShipping.toDouble();
    } else {
      shippingCharge = double.tryParse(rawShipping.toString()) ?? 0.0;
    }
  }

  double margin = 0.0;
  final rawMargin = raw['margin'] ?? raw['maxMargin'] ?? raw['max_margin'] ?? raw['margin_ceiling'];
  if (rawMargin != null) {
    if (rawMargin is num) {
      margin = rawMargin.toDouble();
    } else {
      margin = double.tryParse(rawMargin.toString()) ?? 0.0;
    }
  }

  // ── Tax parsing ──────────────────────────────────────────────────────────
  final categoryObj = raw['category'] is Map ? raw['category'] as Map : null;
  final effectiveTax = raw['effectiveTaxRule'] ??
      raw['taxRule'] ??
      raw['tax_rule'] ??
      (categoryObj != null
          ? (categoryObj['effectiveTaxRule'] ??
              categoryObj['taxRule'] ??
              categoryObj['tax_rule'])
          : null);

  double parseTaxRate(dynamic v) {
    if (v == null) return -1.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? -1.0;
  }

  final rawTaxRate = raw['taxPercent'] ??
      raw['tax_percent'] ??
      raw['taxRate'] ??
      raw['tax_rate'] ??
      raw['gstPercent'] ??
      raw['gst_percent'] ??
      raw['gstRate'] ??
      (effectiveTax is Map
          ? (effectiveTax['rate'] ??
              effectiveTax['taxPercent'] ??
              effectiveTax['taxRate'] ??
              effectiveTax['tax_rate'])
          : null) ??
      (categoryObj != null
          ? (categoryObj['taxPercent'] ??
              categoryObj['taxRate'] ??
              categoryObj['tax_rate'] ??
              categoryObj['rate'])
          : null);
  final parsedTaxRate = parseTaxRate(rawTaxRate);
  final taxPercent = parsedTaxRate >= 0 ? parsedTaxRate : 0.0;

  final rawTaxType = raw['taxType'] ??
      raw['tax_type'] ??
      raw['type'] ??
      (effectiveTax is Map
          ? (effectiveTax['taxType'] ??
              effectiveTax['type'] ??
              effectiveTax['tax_type'])
          : null) ??
      (categoryObj != null
          ? (categoryObj['taxType'] ??
              categoryObj['tax_type'] ??
              categoryObj['type'])
          : null);
  final taxType = (rawTaxType != null && rawTaxType.toString().trim().isNotEmpty)
      ? rawTaxType.toString()
      : 'EXCLUSIVE';

  final taxRuleId = (raw['taxRuleId'] ??
          raw['tax_rule_id'] ??
          (effectiveTax is Map ? effectiveTax['id'] : null))
      ?.toString();

  final hsnCode = (raw['hsnCode'] ??
          raw['hsn_code'] ??
          (effectiveTax is Map ? effectiveTax['hsnCode'] : null) ??
          (categoryObj != null ? categoryObj['hsnCode'] : null))
      ?.toString();

  final categoryParentObj = categoryObj != null && categoryObj['parent'] is Map ? categoryObj['parent'] as Map : null;
  final parentCategoryId = raw['parentCategoryId']?.toString() ??
      (categoryParentObj != null ? categoryParentObj['id']?.toString() : null) ??
      (categoryObj != null && categoryObj['parentId'] != null ? categoryObj['parentId']?.toString() : null) ??
      (categoryObj != null && categoryObj['parentId'] == null ? categoryObj['id']?.toString() : null) ??
      categoryId;
  final subCategoryId = raw['subCategoryId']?.toString() ?? (categoryObj != null && categoryObj['parentId'] != null ? categoryObj['id']?.toString() : null);
  final subCategoryName = raw['subCategoryName']?.toString() ?? raw['subCategory']?.toString() ?? (categoryObj != null && categoryObj['parentId'] != null ? categoryObj['name']?.toString() : null);
  final mainCategoryName = raw['categoryName']?.toString() ?? (categoryParentObj != null ? categoryParentObj['name']?.toString() : null) ?? categoryName;

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
    parentCategoryId: parentCategoryId,
    subCategoryId: subCategoryId,
    subCategoryName: subCategoryName,
    subcategory: subCategoryName ?? mainCategoryName,
    rating: rating,
    reviewCount: reviewCount,
    reviews: [],
    sizes: sizes,
    colors: colors,
    isAvailable: true,
    isTrending: isTrending,
    isNewArrival: isNewArrival,
    isFeatured: isFeatured,
    taxRuleId: taxRuleId,
    taxPercent: taxPercent,
    taxType: taxType,
    hsnCode: hsnCode,
    shippingCharge: shippingCharge,
    margin: margin,
  );
}

/// Filters for paginated product listing API calls.
class ProductListFilters {
  const ProductListFilters({
    this.categoryId,
    this.search,
    this.isFeatured,
    this.isTrending,
    this.isNewArrival,
    this.sort = 'newest',
  });

  final String? categoryId;
  final String? search;
  final bool? isFeatured;
  final bool? isTrending;
  final bool? isNewArrival;
  final String sort;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'sort': sort};
    if (categoryId != null && categoryId!.trim().isNotEmpty) {
      params['categoryId'] = categoryId!.trim();
    }
    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    if (isFeatured == true) params['isFeatured'] = true;
    if (isTrending == true) params['isTrending'] = true;
    if (isNewArrival == true) params['isNewArrival'] = true;
    return params;
  }
}

/// One page of products from the catalog API.
class ProductPageResult {
  const ProductPageResult({
    required this.products,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  final List<ProductModel> products;
  final int page;
  final int total;
  final int totalPages;
  final bool hasMore;
}

class ProductRepository {
  static List<ProductModel>? _cachedProducts;
  static DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(minutes: 2);

  final ApiService _apiService;

  ProductRepository(this._apiService);

  static bool get _isCacheValid =>
      _cachedProducts != null &&
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < _cacheTtl;

  static void clearCache() {
    _cachedProducts = null;
    _lastFetchTime = null;
  }

  static const int _bulkPageSize = 100;
  static const int _maxPages = 50;
  static const int listingPageSize = 24;

  int _extractTotalCount(dynamic data) {
    if (data is! Map) return 0;
    final inner = data['data'];
    final pagination = (inner is Map ? inner['pagination'] : null) ??
        data['pagination'];
    if (pagination is Map && pagination['total'] is num) {
      return pagination['total'].toInt();
    }
    return 0;
  }

  List<dynamic> _extractRawProductList(dynamic data) {
    if (data is Map) {
      final innerData = data['data'];
      if (innerData is Map) {
        if (innerData['products'] is List) {
          return innerData['products'] as List;
        }
        if (innerData['data'] is List) {
          return innerData['data'] as List;
        }
      } else if (innerData is List) {
        return innerData;
      }
      if (data['products'] is List) {
        return data['products'] as List;
      }
    } else if (data is List) {
      return data;
    }
    return [];
  }

  int _extractTotalPages(dynamic data, {required int pageSize, required int pageCount}) {
    if (data is! Map) return pageCount;

    final inner = data['data'];
    final pagination = (inner is Map ? inner['pagination'] : null) ??
        data['pagination'];

    if (pagination is Map) {
      final totalPages = pagination['totalPages'];
      if (totalPages is num) return totalPages.toInt();
      final total = pagination['total'];
      if (total is num && total > 0) {
        return (total.toInt() + pageSize - 1) ~/ pageSize;
      }
    }
    return pageCount;
  }

  List<ProductModel> _mapRawProducts(List<dynamic> list) {
    return list
        .whereType<Map>()
        .map((item) => mapBackendToMobileProduct(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<ProductPageResult> fetchProductPage({
    required ProductListFilters filters,
    required int page,
    int limit = listingPageSize,
  }) async {
    final query = filters.toQueryParams();
    query['page'] = page;
    query['limit'] = limit;

    final response = await _apiService.get(
      AppUrls.products,
      queryParameters: query,
    );

    if (response.statusCode != 200) {
      return ProductPageResult(
        products: [],
        page: page,
        total: 0,
        totalPages: 0,
        hasMore: false,
      );
    }

    final list = _extractRawProductList(response.data);
    final products = _mapRawProducts(list);
    final totalPages = _extractTotalPages(
      response.data,
      pageSize: limit,
      pageCount: page,
    );
    final total = _extractTotalCount(response.data);

    return ProductPageResult(
      products: products,
      page: page,
      total: total > 0 ? total : products.length,
      totalPages: totalPages,
      hasMore: page < totalPages && products.isNotEmpty,
    );
  }

  Future<List<ProductModel>> _fetchProductsWithQuery(
    Map<String, dynamic> baseQuery, {
    bool paginate = true,
  }) async {
    final allRaw = <dynamic>[];
    int page = 1;
    int totalPages = 1;

    while (page <= totalPages && page <= _maxPages) {
      final query = Map<String, dynamic>.from(baseQuery);
      query['page'] = page;
      query['limit'] = _bulkPageSize;

      final response = await _apiService.get(
        AppUrls.products,
        queryParameters: query,
      );

      if (response.statusCode != 200) break;

      final list = _extractRawProductList(response.data);
      if (list.isEmpty) break;

      allRaw.addAll(list);
      totalPages = paginate
          ? _extractTotalPages(
              response.data,
              pageSize: _bulkPageSize,
              pageCount: page,
            )
          : page;

      if (!paginate || list.length < _bulkPageSize) break;
      page++;
    }

    return _mapRawProducts(allRaw);
  }

  Future<List<ProductModel>> getProducts({bool forceRefresh = false}) async {
    if (forceRefresh) {
      clearCache();
    } else if (_isCacheValid) {
      DevLogger.log('📦 Using cached products (${_cachedProducts!.length} items)');
      return _cachedProducts!;
    }

    try {
      final products = await _fetchProductsWithQuery(
        {'sort': 'newest'},
        paginate: true,
      );

      if (products.isNotEmpty) {
        _cachedProducts = products;
        _lastFetchTime = DateTime.now();
        DevLogger.log('✅ Updated product cache (${products.length} items)');
        return products;
      }
    } catch (e) {
      DevLogger.logError(
        '❌ Failed to fetch products from backend API: $e',
        context: 'ProductRepository',
      );
    }

    if (_cachedProducts != null) {
      return _cachedProducts!;
    }

    return [];
  }

  Future<List<ProductModel>> getTrendingProducts() async {
    try {
      final products = await _fetchProductsWithQuery(
        {'isTrending': true, 'sort': 'popular'},
        paginate: true,
      );
      if (products.isNotEmpty) return products;
    } catch (e) {
      DevLogger.logError(
        '❌ Failed to fetch trending products: $e',
        context: 'ProductRepository',
      );
    }

    final cached = await getProducts();
    final list = cached.where((p) => p.isTrending).toList();
    return list.isNotEmpty ? list : cached.take(10).toList();
  }

  Future<List<ProductModel>> getNewArrivals() async {
    try {
      final products = await _fetchProductsWithQuery(
        {'isNewArrival': true, 'sort': 'newest'},
        paginate: true,
      );
      if (products.isNotEmpty) return products;
    } catch (e) {
      DevLogger.logError(
        '❌ Failed to fetch new arrivals: $e',
        context: 'ProductRepository',
      );
    }

    final cached = await getProducts();
    final markedNew = cached.where((p) => p.isNewArrival).toList();
    final remaining = cached.where((p) => !p.isNewArrival).toList();
    return [...markedNew, ...remaining];
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final result = await fetchProductPage(
        filters: const ProductListFilters(isFeatured: true),
        page: 1,
        limit: 100,
      );
      if (result.products.isNotEmpty) return result.products;
    } catch (e) {
      DevLogger.logError(
        '❌ Failed to fetch featured products: $e',
        context: 'ProductRepository',
      );
    }

    final cached = await getProducts();
    final list = cached.where((p) => p.isFeatured).toList();
    return list.isNotEmpty ? list : cached.take(10).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(String categoryIdOrName) async {
    try {
      final result = await fetchProductPage(
        filters: ProductListFilters(categoryId: categoryIdOrName),
        page: 1,
        limit: 100,
      );
      if (result.products.isNotEmpty) return result.products;

      final allPages = await _fetchProductsWithQuery(
        {'categoryId': categoryIdOrName},
        paginate: true,
      );
      if (allPages.isNotEmpty) return allPages;
    } catch (e) {
      DevLogger.logError(
        '❌ Failed to fetch category products from API: $e',
        context: 'ProductRepository',
      );
    }

    final cached = await getProducts();
    if (cached.isEmpty) return [];

    final target = categoryIdOrName.trim().toLowerCase();

    return cached.where((p) {
      final pCatId = p.categoryId.trim().toLowerCase();
      final pParentCatId = (p.parentCategoryId ?? '').trim().toLowerCase();
      final pSubCatId = (p.subCategoryId ?? '').trim().toLowerCase();
      final pSubName = p.subcategory.trim().toLowerCase();
      final pSubCatName = (p.subCategoryName ?? '').trim().toLowerCase();

      return pCatId == target ||
          pParentCatId == target ||
          pSubCatId == target ||
          pSubName == target ||
          pSubCatName == target;
    }).toList();
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

  Future<List<ProductModel>> searchProducts(
    String query, {
    int page = 1,
    int limit = listingPageSize,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final result = await fetchProductPage(
        filters: ProductListFilters(search: trimmed),
        page: page,
        limit: limit,
      );
      if (result.products.isNotEmpty) return result.products;
    } catch (e) {
      DevLogger.logError(
        '❌ Failed to search products via API: $e',
        context: 'ProductRepository',
      );
    }

    if (page > 1) return [];

    final cached = await getProducts();
    final q = trimmed.toLowerCase();
    return cached
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.subcategory.toLowerCase().contains(q) ||
              (p.subCategoryName != null &&
                  p.subCategoryName!.toLowerCase().contains(q)) ||
              p.categoryId.toLowerCase().contains(q) ||
              p.id.contains(q),
        )
        .toList();
  }

  Future<ProductPageResult> searchProductsPage(
    String query, {
    required int page,
    int limit = listingPageSize,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const ProductPageResult(
        products: [],
        page: 1,
        total: 0,
        totalPages: 0,
        hasMore: false,
      );
    }

    return fetchProductPage(
      filters: ProductListFilters(search: trimmed),
      page: page,
      limit: limit,
    );
  }

  Future<List<ProductReviewModel>> fetchProductReviews(String productId) async {
    try {
      final response = await _apiService.get('/api/v1/mobile/products/$productId/reviews');
      if (response.statusCode == 200) {
        final data = response.data;
        dynamic rawList;
        if (data is Map) {
          final inner = data['data'];
          if (inner is Map && inner['reviews'] != null) {
            rawList = inner['reviews'];
          } else if (data['reviews'] != null) {
            rawList = data['reviews'];
          } else {
            rawList = inner;
          }
        }
        return ProductReviewModel.listFromJson(rawList);
      }
    } catch (e) {
      DevLogger.logError('Error fetching product reviews: $e', context: 'ProductRepository');
    }
    return [];
  }

  Future<List<ProductModel>> getRelatedProducts(String productId) async {
    try {
      final response = await _apiService.get('/api/products/$productId/related');
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> list = [];
        if (data is Map) {
          final innerData = data['data'];
          if (innerData is List) {
            list = innerData;
          } else if (data['products'] is List) {
            list = data['products'] as List;
          }
        } else if (data is List) {
          list = data;
        }

        if (list.isNotEmpty) {
          return list
              .map((item) => mapBackendToMobileProduct(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      }
    } catch (e) {
      DevLogger.logError('Error fetching related products: $e', context: 'ProductRepository');
    }
    return [];
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

final relatedProductsProvider = FutureProvider.family<List<ProductModel>, String>((ref, productId) async {
  final repo = ref.watch(productRepositoryProvider);
  final related = await repo.getRelatedProducts(productId);
  if (related.isNotEmpty) return related;

  final product = await ref.watch(productDetailProvider(productId).future);
  if (product != null) {
    return repo.getProductsByCategory(product.categoryId);
  }
  return [];
});

final productDetailProvider = FutureProvider.family<ProductModel?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).getProductById(id);
});

final productReviewsProvider = FutureProvider.family<List<ProductReviewModel>, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).fetchProductReviews(productId);
});

final topRatedProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final products = await ref.watch(productRepositoryProvider).getProducts();
  return products.take(4).toList();
});
