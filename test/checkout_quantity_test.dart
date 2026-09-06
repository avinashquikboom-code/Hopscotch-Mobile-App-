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

    test('Initial checkout quantity starts strictly at 0', () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      final state = notifier.state;
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 0,
          reason: 'Checkout quantity must start at 0, not 1');
      expect(state.totalQuantity, 0);
      expect(state.canPlaceOrder, false);
      expect(state.activeOrderItems, isEmpty);
    });

    test('At quantity 0: Subtotal, Tax, Shipping, Total are all 0', () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      final state = notifier.state;
      expect(state.subtotal, 0.0);
      expect(state.exclusiveTaxAmount, 0.0);
      expect(state.inclusiveTaxAmount, 0.0);
      expect(state.totalTaxAmount, 0.0);
      expect(state.shippingFee, 0.0);
      expect(state.canPlaceOrder, false);
    });

    test('Minus button at quantity 0 must NOT decrease further (never negative)',
        () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      // At quantity 0, tap minus multiple times
      notifier.decrement('cart_item_1');
      expect(notifier.state.items.first.quantity, 0);

      notifier.decrement('cart_item_1');
      expect(notifier.state.items.first.quantity, 0);

      notifier.setQuantity('cart_item_1', -5);
      expect(notifier.state.items.first.quantity, 0,
          reason: 'Quantity must never be negative');
    });

    test('Tapping plus increments: 0 -> 1 -> 2 and updates calculations dynamically',
        () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      // 0 -> 1
      notifier.increment('cart_item_1');
      var state = notifier.state;
      expect(state.items.first.quantity, 1);
      expect(state.totalQuantity, 1);
      expect(state.subtotal, 499.0);
      expect(state.exclusiveTaxAmount, 89.82); // 499 * 0.18
      expect(state.shippingFee, 40.0);
      expect(state.canPlaceOrder, true);
      expect(state.activeOrderItems.length, 1);

      // 1 -> 2
      notifier.increment('cart_item_1');
      state = notifier.state;
      expect(state.items.first.quantity, 2);
      expect(state.totalQuantity, 2);
      expect(state.subtotal, 998.0);
      expect(state.exclusiveTaxAmount, 179.64); // 998 * 0.18
      // Subtotal >= 999 gets free shipping, 998 < 999 has shipping: 2 * 40 = 80.0
      expect(state.shippingFee, 80.0);
    });

    test('Tapping minus decrements: 2 -> 1 -> 0, minus disabled at 0', () {
      final notifier = CheckoutNotifier();
      notifier.initFromCart([cartItem]);

      notifier.increment('cart_item_1'); // 1
      notifier.increment('cart_item_1'); // 2
      expect(notifier.state.items.first.quantity, 2);

      notifier.decrement('cart_item_1'); // 2 -> 1
      expect(notifier.state.items.first.quantity, 1);
      expect(notifier.state.subtotal, 499.0);

      notifier.decrement('cart_item_1'); // 1 -> 0
      expect(notifier.state.items.first.quantity, 0);
      expect(notifier.state.subtotal, 0.0);
      expect(notifier.state.totalTaxAmount, 0.0);
      expect(notifier.state.canPlaceOrder, false);

      // Decrement again at 0
      notifier.decrement('cart_item_1');
      expect(notifier.state.items.first.quantity, 0);
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
