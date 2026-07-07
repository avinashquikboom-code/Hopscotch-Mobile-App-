import 'package:dio/dio.dart';
import 'api_service.dart';

class CartApi {
  final ApiService _apiService;
  
  CartApi(this._apiService);
  
  Future<Response> getCart() async {
    return await _apiService.get('/api/cart');
  }
  
  Future<Response> addToCart({
    required String productId,
    required String variantId,
    required int quantity,
  }) async {
    return await _apiService.post(
      '/api/cart',
      data: {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
      },
    );
  }
  
  Future<Response> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async {
    return await _apiService.patch(
      '/api/cart/$cartItemId',
      data: {'quantity': quantity},
    );
  }
  
  Future<Response> removeFromCart(String cartItemId) async {
    return await _apiService.delete('/api/cart/$cartItemId');
  }
  
  Future<Response> clearCart() async {
    return await _apiService.delete('/api/cart');
  }
}
