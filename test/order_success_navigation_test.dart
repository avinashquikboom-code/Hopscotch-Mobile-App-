import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/screens/checkout/order_success_screen.dart';
import 'package:hopscotch/widgets/custom_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Order Success Navigation & PopScope Tests', () {
    testWidgets(
      'OrderSuccessScreen wraps content with PopScope(canPop: false)',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: OrderSuccessScreen(orderId: 'ORD-TEST-12345'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify PopScope exists and has canPop set to false
        final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
        expect(popScopeFinder, findsOneWidget);

        final popScopeWidget = tester.widget<PopScope<Object?>>(popScopeFinder);
        expect(popScopeWidget.canPop, isFalse);
      },
    );

    testWidgets(
      'OrderSuccessScreen PopScope onPopInvokedWithResult routes to /my-orders',
      (tester) async {
        String? navigatedLocation;

        final router = GoRouter(
          initialLocation: '/order-success',
          routes: [
            GoRoute(
              path: '/order-success',
              builder: (context, state) =>
                  const OrderSuccessScreen(orderId: 'ORD-TEST-99999'),
            ),
            GoRoute(
              path: '/my-orders',
              builder: (context, state) {
                navigatedLocation = '/my-orders';
                return const Scaffold(body: Text('MY ORDERS SCREEN'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OrderSuccessScreen), findsOneWidget);

        // Simulate back navigation trigger on PopScope
        final popScopeWidget = tester.widget<PopScope<Object?>>(
          find.byWidgetPredicate((w) => w is PopScope),
        );
        expect(popScopeWidget.canPop, isFalse);

        // Invoke the pop callback
        popScopeWidget.onPopInvokedWithResult?.call(false, null);
        await tester.pumpAndSettle();

        expect(navigatedLocation, equals('/my-orders'));
        expect(find.text('MY ORDERS SCREEN'), findsOneWidget);
      },
    );

    testWidgets(
      'Continue Shopping button navigates to /home without showing Checkout',
      (tester) async {
        String? navigatedLocation;

        final router = GoRouter(
          initialLocation: '/order-success',
          routes: [
            GoRoute(
              path: '/order-success',
              builder: (context, state) =>
                  const OrderSuccessScreen(orderId: 'ORD-TEST-11111'),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) {
                navigatedLocation = '/home';
                return const Scaffold(body: Text('HOME SCREEN'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final continueBtn = find.widgetWithText(CustomButton, 'CONTINUE SHOPPING');
        expect(continueBtn, findsOneWidget);

        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        expect(navigatedLocation, equals('/home'));
        expect(find.text('HOME SCREEN'), findsOneWidget);
      },
    );

    testWidgets(
      'View Order Details button navigates to /order-detail with correct ID',
      (tester) async {
        String? navigatedLocation;

        final router = GoRouter(
          initialLocation: '/order-success',
          routes: [
            GoRoute(
              path: '/order-success',
              builder: (context, state) =>
                  const OrderSuccessScreen(orderId: 'ORD-TEST-55555'),
            ),
            GoRoute(
              path: '/order-detail',
              builder: (context, state) {
                navigatedLocation = state.uri.toString();
                return const Scaffold(body: Text('ORDER DETAIL SCREEN'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final viewOrderBtn = find.widgetWithText(CustomButton, 'VIEW ORDER DETAILS');
        expect(viewOrderBtn, findsOneWidget);

        await tester.ensureVisible(viewOrderBtn);
        await tester.tap(viewOrderBtn);
        await tester.pumpAndSettle();

        expect(navigatedLocation, contains('/order-detail?id=ORD-TEST-55555'));
        expect(find.text('ORDER DETAIL SCREEN'), findsOneWidget);
      },
    );

    testWidgets(
      'Track My Order button navigates to /track-order with correct ID',
      (tester) async {
        String? navigatedLocation;

        final router = GoRouter(
          initialLocation: '/order-success',
          routes: [
            GoRoute(
              path: '/order-success',
              builder: (context, state) =>
                  const OrderSuccessScreen(orderId: 'ORD-TEST-77777'),
            ),
            GoRoute(
              path: '/track-order/:orderId',
              builder: (context, state) {
                navigatedLocation = state.uri.toString();
                return const Scaffold(body: Text('TRACK ORDER SCREEN'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final trackBtn = find.widgetWithText(CustomButton, 'TRACK MY ORDER');
        expect(trackBtn, findsOneWidget);

        await tester.ensureVisible(trackBtn);
        await tester.tap(trackBtn);
        await tester.pumpAndSettle();

        expect(navigatedLocation, equals('/track-order/ORD-TEST-77777'));
        expect(find.text('TRACK ORDER SCREEN'), findsOneWidget);
      },
    );
  });
}
