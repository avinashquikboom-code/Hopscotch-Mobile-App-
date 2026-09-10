import 'package:flutter_test/flutter_test.dart';
import 'package:hopscotch/models/cart_item_model.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/providers/checkout_provider.dart';

void main() {
  group('Checkout Quantity & Calculations Tests', () {
    const testProduct = ProductModel(
      id: 'prod_1',
      title: 'Premium Baby Romper',
      description: 'Cotton soft romper',
      price: 499.0,
      originalPrice: 799.0,
      discountPercentage: 37.5,
      imageUrl: 'https://example.com/image.jpg',
      categoryId: 'cat_1',
      rating: 4.8,
      reviewCount: 12,
      variants: [
        ProductVariantModel(
          id: 'var_1',
          size: '6M',
          color: 'Blue',
          price: 499.0,
          stock: 5,
        ),
      ],
      taxPercent: 18.0,
      taxType: 'EXCLUSIVE',
      shippingCharge: 40.0,
    );

    const cartItem = CartItemModel(
      id: 'cart_item_1',
      product: testProduct,
      quantity: 1, // entered from cart with qty 1
      selectedSize: '6M',
      selectedColor: 'Blue',
    );

    test('Initial checkout quantity starts strictly at 1, not 0', () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      final state = notifier.state;
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 1,
          reason: 'Checkout quantity must start at 1, never 0');
      expect(state.totalQuantity, 1);
      expect(state.canPlaceOrder, true);
      expect(state.activeOrderItems.length, 1);
      expect(state.subtotal, 499.0);
      expect(state.exclusiveTaxAmount, 89.82);
      expect(state.shippingFee, 40.0);
    });

    test('Tapping plus increments normally: 1 -> 2 -> 3 and recalculates', () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      // 1 -> 2
      notifier.increment('cart_item_1');
      var state = notifier.state;
      expect(state.items.first.quantity, 2);
      expect(state.totalQuantity, 2);
      expect(state.subtotal, 998.0);
      expect(state.exclusiveTaxAmount, 179.64);
      expect(state.shippingFee, 80.0);
      expect(state.canPlaceOrder, true);

      // 2 -> 3
      notifier.increment('cart_item_1');
      state = notifier.state;
      expect(state.items.first.quantity, 3);
      expect(state.totalQuantity, 3);
      expect(state.subtotal, 1497.0);
      // Subtotal >= 999 gets free shipping
      expect(state.shippingFee, 0.0);
    });

    test('Tapping minus decrements: 3 -> 2 -> 1, and at 1 REMOVES product', () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      notifier.increment('cart_item_1'); // 1 -> 2
      notifier.increment('cart_item_1'); // 2 -> 3
      expect(notifier.state.items.first.quantity, 3);

      notifier.decrement('cart_item_1'); // 3 -> 2
      expect(notifier.state.items.first.quantity, 2);
      expect(notifier.state.subtotal, 998.0);

      notifier.decrement('cart_item_1'); // 2 -> 1
      expect(notifier.state.items.first.quantity, 1);
      expect(notifier.state.subtotal, 499.0);

      // Decrement at 1: MUST REMOVE PRODUCT
      notifier.decrement('cart_item_1'); // 1 -> REMOVE
      final emptyState = notifier.state;
      expect(emptyState.items, isEmpty,
          reason: 'Product must be removed from checkout items at quantity 0');
      expect(emptyState.activeOrderItems, isEmpty);
      expect(emptyState.totalQuantity, 0);
      expect(emptyState.subtotal, 0.0,
          reason: 'Subtotal must be 0 after item removal');
      expect(emptyState.exclusiveTaxAmount, 0.0,
          reason: 'Tax must be 0 after item removal');
      expect(emptyState.totalTaxAmount, 0.0);
      expect(emptyState.shippingFee, 0.0,
          reason: 'Shipping must be 0 after item removal');
      expect(emptyState.canPlaceOrder, false,
          reason: 'Cannot place order with empty cart');
    });

    test('Negative and zero quantity prevention: removes item', () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      // setQuantity <= 0 removes item
      notifier.setQuantity('cart_item_1', 0);
      expect(notifier.state.items, isEmpty);

      final notifier2 = CheckoutNotifier();
      notifier2.initFromCart([cartItem]);
      notifier2.setQuantity('cart_item_1', -3);
      expect(notifier2.state.items, isEmpty);
    });

    test('Stock limit protection: cannot exceed variant stock (5)', () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      for (int i = 0; i < 10; i++) {
        notifier.increment('cart_item_1');
      }

      // Stock is 5
      expect(notifier.state.items.first.quantity, 5);
    });
  });
}
