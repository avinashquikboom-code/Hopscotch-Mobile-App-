import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/cart_item_model.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';

class CheckoutState {
  final List<CartItemModel> items;
  final bool isInitialized;

  const CheckoutState({
    this.items = const [],
    this.isInitialized = false,
  });

  CheckoutState copyWith({
    List<CartItemModel>? items,
    bool? isInitialized,
  }) {
    return CheckoutState(
      items: items ?? this.items,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  int get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);

  double _round2(double val) => (val * 100.0).roundToDouble() / 100.0;

  double get subtotal {
    final raw = items.fold(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    return _round2(raw);
  }

  double get totalDiscount {
    final raw = items.fold(0.0, (sum, item) {
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
    final raw = items.fold(0.0, (sum, item) {
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
    final raw = items.fold(0.0, (sum, item) {
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

  double get totalTaxAmount {
    return _round2(exclusiveTaxAmount + inclusiveTaxAmount);
  }

  double get taxAmount => totalTaxAmount;

  List<dynamic> get taxBreakdown {
    final Map<String, Map<String, dynamic>> map = {};
    for (final item in items) {
      if (item.quantity <= 0) continue;
      final p = item.product;
      final rate = p.taxPercent > 0 ? p.taxPercent : 0.0;
      if (rate <= 0) continue;
      final rawType = p.taxType.toUpperCase();
      final isInclusive = _isInclusiveTax(rawType);
      final taxType = isInclusive ? 'INCLUSIVE' : 'EXCLUSIVE';
      const name = 'Taxes';

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
          'taxableAmount':
              _round2((existing['taxableAmount'] as double) + lineSubtotal),
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
    if (totalQuantity == 0) return 0.0;
    if (subtotal >= 999) return 0.0;

    double productShipping = 0.0;
    for (final item in items) {
      final charge = item.product.shippingCharge;
      if (charge > 0) {
        productShipping += (charge * item.quantity);
      }
    }
    return _round2(productShipping);
  }

  List<CartItemModel> get activeOrderItems =>
      items.where((item) => item.quantity > 0).toList();

  bool get canPlaceOrder => totalQuantity > 0 && items.isNotEmpty;
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref? _ref;

  CheckoutNotifier([this._ref]) : super(const CheckoutState());

  /// Initialize checkout items from cart.
  /// Quantities always start at cart quantity (minimum 1, never 0).
  void initFromCart(List<CartItemModel> cartItems) {
    if (cartItems.isEmpty) {
      state = const CheckoutState(items: [], isInitialized: true);
      return;
    }
    // Items must initialize to their cart quantity (strictly >= 1, never 0)
    final checkoutItems = cartItems
        .where((item) => item.quantity > 0)
        .map((item) => item.copyWith(
              quantity: item.quantity > 0 ? item.quantity : 1,
            ))
        .toList();
    state = CheckoutState(items: checkoutItems, isInitialized: true);
  }

  /// Increment quantity with stock limit check.
  /// 1 -> 2 -> 3 -> 4 -> 5 ...
  void increment(String itemId) {
    final itemIndex = state.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    final maxStock = item.product.stock;
    if (maxStock > 0 && item.quantity >= maxStock) {
      return; // respect inventory limit
    }

    final newQty = item.quantity + 1;
    state = state.copyWith(
      items: [
        for (int i = 0; i < state.items.length; i++)
          if (i == itemIndex)
            state.items[i].copyWith(quantity: newQty)
          else
            state.items[i],
      ],
    );

    // Sync with Riverpod cartProvider
    _ref?.read(cartProvider.notifier).updateQuantity(itemId, newQty);
  }

  /// Decrement quantity down to 0.
  /// 5 -> 4 -> 3 -> 2 -> 1 -> 0.
  /// When quantity reaches 0:
  /// THE PRODUCT MUST BE REMOVED FROM THE CART/CHECKOUT.
  /// Do NOT leave [ − ] 0 [ + ] inside the Order Summary.
  void decrement(String itemId) {
    final itemIndex = state.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    if (item.quantity <= 1) {
      // Remove product immediately when reaching 0
      removeItem(itemId);
    } else {
      final newQty = item.quantity - 1;
      state = state.copyWith(
        items: [
          for (int i = 0; i < state.items.length; i++)
            if (i == itemIndex)
              state.items[i].copyWith(quantity: newQty)
            else
              state.items[i],
        ],
      );
      // Sync with Riverpod cartProvider
      _ref?.read(cartProvider.notifier).updateQuantity(itemId, newQty);
    }
  }

  /// Remove item immediately from checkout and cart.
  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != itemId).toList(),
    );
    // Sync with Riverpod cartProvider
    _ref?.read(cartProvider.notifier).removeFromCart(itemId);
  }

  /// Explicit set quantity with clamping [1, maxStock].
  /// Quantity <= 0 removes item.
  void setQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final itemIndex = state.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    final maxStock = item.product.stock;
    final clamped = maxStock > 0 ? quantity.clamp(1, maxStock) : quantity;

    state = state.copyWith(
      items: [
        for (int i = 0; i < state.items.length; i++)
          if (i == itemIndex)
            state.items[i].copyWith(quantity: clamped)
          else
            state.items[i],
      ],
    );

    // Sync with Riverpod cartProvider
    _ref?.read(cartProvider.notifier).updateQuantity(itemId, clamped);
  }

  void reset() {
    state = const CheckoutState();
  }
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});
