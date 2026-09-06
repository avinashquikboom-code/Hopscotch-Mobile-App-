import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/cart_item_model.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/providers/checkout_provider.dart';
import 'package:hopscotch/providers/currency_provider.dart';

void main() {
  testWidgets('Checkout Stepper UI test: starts at 0, minus disabled at 0, increments to 1',
      (WidgetTester tester) async {
    const testProduct = ProductModel(
      id: 'prod_1',
      title: 'Romper Suit',
      description: 'Cotton',
      price: 500.0,
      originalPrice: 800.0,
      discountPercentage: 37.5,
      imageUrl: 'https://example.com/image.jpg',
      categoryId: 'cat_1',
      rating: 4.5,
      reviewCount: 10,
      variants: [
        ProductVariantModel(
          id: 'v1',
          stock: 3,
          price: 500.0,
        ),
      ],
    );

    const cartItem = CartItemModel(
      id: 'item_1',
      product: testProduct,
      quantity: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkoutProvider.overrideWith((ref) {
            final notifier = CheckoutNotifier();
            notifier.initFromCart([cartItem]);
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final checkoutState = ref.watch(checkoutProvider);
                final checkoutNotifier = ref.read(checkoutProvider.notifier);
                final currency = ref.watch(currencyProvider);
                final item = checkoutState.items.first;
                final canDecrement = item.quantity > 0;
                final maxStock = item.product.stock;
                final canIncrement = maxStock <= 0 || item.quantity < maxStock;

                return Column(
                  children: [
                    Text('Qty: ${item.quantity}', key: const Key('qty_text')),
                    Text('Total: ${currency.formatPrice(checkoutState.subtotal)}',
                        key: const Key('total_text')),
                    IconButton(
                      key: const Key('minus_btn'),
                      icon: const Icon(Icons.remove),
                      onPressed: canDecrement
                          ? () => checkoutNotifier.decrement(item.id)
                          : null,
                    ),
                    IconButton(
                      key: const Key('plus_btn'),
                      icon: const Icon(Icons.add),
                      onPressed: canIncrement
                          ? () => checkoutNotifier.increment(item.id)
                          : null,
                    ),
                    ElevatedButton(
                      key: const Key('order_btn'),
                      onPressed: () {
                        if (checkoutState.totalQuantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please select at least 1 quantity.'),
                            ),
                          );
                          return;
                        }
                      },
                      child: const Text('PAY NOW'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial quantity must be 0
    expect(find.text('Qty: 0'), findsOneWidget);
    expect(find.text('Total: ₹0.00'), findsOneWidget);

    // 2. Minus button must be disabled (IconButton with onPressed: null has no tap handling)
    final minusButton = tester.widget<IconButton>(find.byKey(const Key('minus_btn')));
    expect(minusButton.onPressed, isNull, reason: 'Minus must be disabled at quantity 0');

    // 3. Try tapping Pay Now at quantity 0 -> shows snackbar
    await tester.tap(find.byKey(const Key('order_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Please select at least 1 quantity.'), findsOneWidget);

    // 4. Tap plus button -> 0 -> 1
    await tester.tap(find.byKey(const Key('plus_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Qty: 1'), findsOneWidget);
    expect(find.text('Total: ₹500.00'), findsOneWidget);

    // Minus button must now be enabled
    final minusButtonEnabled = tester.widget<IconButton>(find.byKey(const Key('minus_btn')));
    expect(minusButtonEnabled.onPressed, isNotNull, reason: 'Minus must be enabled at quantity 1');

    // 5. Tap minus button -> 1 -> 0
    await tester.tap(find.byKey(const Key('minus_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Qty: 0'), findsOneWidget);
    expect(find.text('Total: ₹0.00'), findsOneWidget);

    final minusButtonDisabledAgain =
        tester.widget<IconButton>(find.byKey(const Key('minus_btn')));
    expect(minusButtonDisabledAgain.onPressed, isNull,
        reason: 'Minus must be disabled again at quantity 0');
  });
}
