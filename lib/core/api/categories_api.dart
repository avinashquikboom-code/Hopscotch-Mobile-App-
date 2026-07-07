import 'package:dio/dio.dart';
import 'api_service.dart';

class CategoriesApi {
  final ApiService _apiService;
  
  CategoriesApi(this._apiService);
  
  Future<Response> getCategories() async {
    return await _apiService.get('/api/categories');
  }
  
  Future<Response> getCategoryById(String id) async {
    return await _apiService.get('/api/categories/$id');
  }
  
  Future<Response> getSubCategories(String parentId) async {
    return await _apiService.get('/api/categories/$parentId/children');
  }
  
  Future<Response> getFeaturedCategories() async {
    return await _apiService.get('/api/categories', queryParameters: {
      'isFeatured': true,
    });
  }
}
