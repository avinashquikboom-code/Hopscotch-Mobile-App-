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

  void addToCart(ProductModel product, {String? size, String? color, String? selectedImage}) {
    final existingIndex = state.indexWhere((item) =>
        item.product.id == product.id &&
        item.selectedSize == size &&
        item.selectedColor == color &&
        item.selectedImage == selectedImage);

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
        selectedImage: selectedImage,
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

  double _round2(double val) => (val * 100.0).roundToDouble() / 100.0;

  double get subtotal {
    final raw = state.fold(
        0.0, (sum, item) => sum + (item.product.price * item.quantity));
    return _round2(raw);
  }

  double get totalDiscount {
    final raw = state.fold(0.0, (sum, item) {
      final original = item.product.originalPrice;
      final current = item.product.price;
      if (original > current) {
        return sum + ((original - current) * item.quantity);
      }
      return sum;
    });
    return _round2(raw);
  }

  bool _isInclusiveTax(String taxType) {
    return taxType.trim().toUpperCase() == 'INCLUSIVE';
  }

  double get exclusiveTaxAmount {
    final raw = state.fold(0.0, (sum, item) {
      final p = item.product;
      final type = p.taxType.toUpperCase();
      final isInclusive = _isInclusiveTax(type);
      final rate = p.taxPercent > 0 ? p.taxPercent : 0.0;
      if (!isInclusive && rate > 0) {
        return sum + ((p.price * item.quantity) * (rate / 100));
      }
      return sum;
    });
    return _round2(raw);
  }

  double get inclusiveTaxAmount {
    final raw = state.fold(0.0, (sum, item) {
      final p = item.product;
      final type = p.taxType.toUpperCase();
      final isInclusive = _isInclusiveTax(type);
      final rate = p.taxPercent > 0 ? p.taxPercent : 0.0;
      if (isInclusive && rate > 0) {
        final lineTotal = p.price * item.quantity;
        final lineTax = lineTotal - (lineTotal / (1 + rate / 100));
        return sum + lineTax;
      }
      return sum;
    });
    return _round2(raw);
  }

  double get effectiveTaxPercent {
    if (state.isEmpty) return 0.0;
    final rates = state.map((i) => i.product.taxPercent).toSet();
    if (rates.length == 1) {
      final rate = rates.first;
      return rate > 0 ? rate : 0.0;
    }
    return 0.0;
  }

  String get taxRateLabel {
    return 'Taxes';
  }

  double get totalTaxAmount {
    return _round2(exclusiveTaxAmount + inclusiveTaxAmount);
  }

  double get taxAmount => totalTaxAmount;

  bool get hasInclusiveTax => state.any((item) {
        final type = item.product.taxType.toUpperCase();
        return _isInclusiveTax(type);
      });

  bool get hasExclusiveTax => state.any((item) {
        final type = item.product.taxType.toUpperCase();
        return !_isInclusiveTax(type);
      });

  List<dynamic> get taxBreakdown {
    final Map<String, Map<String, dynamic>> map = {};
    for (final item in state) {
      final p = item.product;
      final rate = p.taxPercent > 0 ? p.taxPercent : 0.0;
      if (rate <= 0) continue;
      final rawType = p.taxType.toUpperCase();
      final isInclusive = _isInclusiveTax(rawType);
      final taxType = isInclusive ? 'INCLUSIVE' : 'EXCLUSIVE';
      final name = 'Taxes';

      final lineSubtotal = p.price * item.quantity;
      final lineTax = isInclusive
          ? lineSubtotal - (lineSubtotal / (1 + rate / 100))
          : lineSubtotal * (rate / 100);

      final key = '${rate}_$taxType';
      if (map.containsKey(key)) {
        final existing = map[key]!;
        map[key] = {
          'name': name,
          'rate': rate,
          'taxType': taxType,
          'taxableAmount': _round2((existing['taxableAmount'] as double) + lineSubtotal),
          'taxAmount': _round2((existing['taxAmount'] as double) + lineTax),
        };
      } else {
        map[key] = {
          'name': name,
          'rate': rate,
          'taxType': taxType,
          'taxableAmount': _round2(lineSubtotal),
          'taxAmount': _round2(lineTax),
        };
      }
    }
    return map.values.toList();
  }

  double get shippingFee {
    if (state.isEmpty) return 0.0;
    if (subtotal >= 999) return 0.0;

    double productShipping = 0.0;
    for (final item in state) {
      productShipping += item.product.shippingCharge * item.quantity;
    }
    return _round2(productShipping);
  }

  double get totalAmount {
    if (state.isEmpty) return 0.0;
    return _round2(subtotal + shippingFee + exclusiveTaxAmount);
  }

  double get getTotalAmount => totalAmount;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  final userProfile = ref.watch(profileNotifierProvider);
  final userId = userProfile != null ? userProfile['id']?.toString() : 'guest';
  return CartNotifier(userId ?? 'guest');
});
