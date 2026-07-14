import 'package:dio/dio.dart';
import 'package:hopscotch/api/api_service.dart';

class ProductsApi {
  final ApiService _apiService;
  
  ProductsApi(this._apiService);
  
  Future<Response> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    return await _apiService.get('/api/products', queryParameters: {
      'page': page,
      'limit': limit,
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    });
  }
  
  Future<Response> getProductById(String id) async {
    return await _apiService.get('/api/products/$id');
  }
  
  Future<Response> getProductsByCategory(String categoryId) async {
    return await _apiService.get('/api/categories/$categoryId/products');
  }
  
  Future<Response> getFeaturedProducts() async {
    return await _apiService.get('/api/products', queryParameters: {
      'isFeatured': true,
    });
  }
  
  Future<Response> searchProducts(String query) async {
    return await _apiService.get('/api/products', queryParameters: {
      'search': query,
    });
  }
}
