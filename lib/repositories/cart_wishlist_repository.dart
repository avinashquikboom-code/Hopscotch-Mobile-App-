import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopscotch/models/cart_item_model.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/repositories/profile_repository.dart';

// Wishlist State Notifier (User-specific persistent storage)
class WishlistNotifier extends StateNotifier<List<ProductModel>> {
  final String userId;

  WishlistNotifier(this.userId) : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'wishlist_items_$userId';
      final raw = prefs.getString(key);
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw);
        state = list
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'wishlist_items_$userId';
      final jsonList = state.map((item) => item.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (_) {}
  }

  void toggleWishlist(ProductModel product) {
    if (state.any((p) => p.id == product.id)) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      state = [...state, product];
    }
    _saveToPrefs();
  }

  bool isFavorite(String productId) {
    return state.any((p) => p.id == productId);
  }

  void clearWishlist() {
    state = [];
    _saveToPrefs();
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<ProductModel>>((ref) {
  final userProfile = ref.watch(profileNotifierProvider);
  final userId = userProfile != null ? userProfile['id']?.toString() : 'guest';
  return WishlistNotifier(userId ?? 'guest');
});

// Cart State Notifier (User-specific persistent storage)
class CartNotifier extends StateNotifier<List<CartItemModel>> {
  final String userId;

  CartNotifier(this.userId) : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cart_items_$userId';
      final raw = prefs.getString(key);
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw);
        state = list
            .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cart_items_$userId';
      final jsonList = state.map((item) => item.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (_) {}
  }

  void addToCart(ProductModel product, {String? size, String? color}) {
    final existingIndex = state.indexWhere((item) =>
        item.product.id == product.id &&
        item.selectedSize == size &&
        item.selectedColor == color);

    if (existingIndex != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      final newItem = CartItemModel(
        id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
        product: product,
        quantity: 1,
        selectedSize: size,
        selectedColor: color,
      );
      state = [...state, newItem];
    }
    _saveToPrefs();
  }

  void removeFromCart(String cartItemId) {
    state = state.where((item) => item.id != cartItemId).toList();
    _saveToPrefs();
  }

  void updateQuantity(String cartItemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(cartItemId);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == cartItemId) item.copyWith(quantity: quantity) else item
    ];
    _saveToPrefs();
  }

  bool get isPersistenceSupportEnabled => true;

  List<CartItemModel> get getCartItems => state;

  int get getCartCount => state.fold(0, (sum, item) => sum + item.quantity);

  void removeItemFromCart(String cartItemId) {
    removeFromCart(cartItemId);
  }

  void clearCart() {
    state = [];
    _saveToPrefs();
  }

  double get subtotal {
    return state.fold(
        0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  double get totalDiscount {
    return state.fold(0.0, (sum, item) {
      final original = item.product.originalPrice;
      final current = item.product.price;
      if (original > current) {
        return sum + ((original - current) * item.quantity);
      }
      return sum;
    });
  }

  double get taxAmount {
    return state.fold(0.0, (sum, item) {
      final p = item.product;
      if (p.taxType.toUpperCase() == 'INCLUSIVE') return sum;
      final rate = p.taxPercent > 0 ? p.taxPercent : 18.0;
      return sum + ((p.price * item.quantity) * (rate / 100));
    });
  }

  double get totalAmount {
    if (state.isEmpty) return 0.0;
    return subtotal + 150.00 + taxAmount;
  }

  double get getTotalAmount => totalAmount;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  final userProfile = ref.watch(profileNotifierProvider);
  final userId = userProfile != null ? userProfile['id']?.toString() : 'guest';
  return CartNotifier(userId ?? 'guest');
});
