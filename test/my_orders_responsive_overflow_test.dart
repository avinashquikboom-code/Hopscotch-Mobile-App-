import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/orders_api.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:hopscotch/repositories/order_repository.dart';
import 'package:hopscotch/screens/profile/my_orders_screen.dart';
import 'package:hopscotch/api/api_service.dart';

class FakeOrderNotifier extends OrderNotifier {
  final List<OrderModel> _orders;
  FakeOrderNotifier(this._orders) : super(OrdersApi(ApiService())) {
    state = AsyncValue.data(_orders);
  }

  @override
  Future<void> fetchOrders({String? status, String? fromDate, String? toDate}) async {
    state = AsyncValue.data(_orders);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testOrders = [
    OrderModel.fromJson({
      'id': 1001,
      'orderNumber': 'ORD-1789027274842-79805629103847291048',
      'totalAmount': 12499.50,
      'status': 'PROCESSING',
      'createdAt': '2026-09-10T12:00:00Z',
      'items': [
        {
          'id': 'it1',
          'product': {
            'id': 'p1',
            'title': 'Handcrafted Luxury Designer Silk Kurta Set With Royal Embroidered Dupatta',
            'price': 12499.50,
            'imageUrl': '',
          },
          'quantity': 2,
          'size': 'XL',
          'color': 'Navy Blue',
        }
      ],
    }),
    OrderModel.fromJson({
      'id': 1002,
      'orderNumber': 'ORD-999988887777666655554444333322221111',
      'totalAmount': 9999999.00,
      'status': 'OUT_FOR_DELIVERY',
      'createdAt': '2026-09-10T12:00:00Z',
      'items': [
        {
          'id': 'it2',
          'product': {
            'id': 'p2',
            'title': 'Premium Cotton Dress',
            'price': 9999999.00,
            'imageUrl': '',
          },
          'quantity': 1,
        }
      ],
    }),
    OrderModel.fromJson({
      'id': 1003,
      'orderNumber': 'ORD-SHORT-12',
      'totalAmount': 350.00,
      'status': 'DELIVERED',
      'createdAt': '2026-09-10T12:00:00Z',
      'items': [],
    }),
    OrderModel.fromJson({
      'id': 1004,
      'orderNumber': 'ORD-1789027274842-7980',
      'totalAmount': 1499.00,
      'status': 'CANCELLED',
      'createdAt': '2026-09-10T12:00:00Z',
      'items': [],
    }),
  ];

  final screenSizes = <String, Size>{
    // Mobile Portrait
    '320 x 568 (Small Phone)': const Size(320, 568),
    '360 x 800 (Standard Android)': const Size(360, 800),
    '375 x 812 (iPhone SE/Mini)': const Size(375, 812),
    '390 x 844 (iPhone 12/13/14)': const Size(390, 844),
    '414 x 896 (iPhone XR/Plus)': const Size(414, 896),
    '430 x 932 (iPhone Pro Max)': const Size(430, 932),

    // Tablet
    '768 x 1024 (iPad Mini)': const Size(768, 1024),
    '820 x 1180 (iPad Air)': const Size(820, 1180),
    '1024 x 1366 (iPad Pro)': const Size(1024, 1366),

    // Landscape
    '568 x 320 (Landscape Small)': const Size(568, 320),
    '800 x 360 (Landscape Android)': const Size(800, 360),
    '844 x 390 (Landscape iPhone)': const Size(844, 390),
    '1024 x 768 (Landscape Tablet)': const Size(1024, 768),
  };

  group('MyOrdersScreen Comprehensive Responsive Overflow Tests', () {
    for (final entry in screenSizes.entries) {
      testWidgets('Screen size ${entry.key} renders with ZERO RenderFlex overflow', (tester) async {
        final size = entry.value;

        // Set physical size and device pixel ratio
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Set up error handler to capture any RenderFlex overflow
        FlutterErrorDetails? capturedError;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed') || details.toString().contains('RenderFlex')) {
            capturedError = details;
          }
          originalOnError?.call(details);
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              orderProvider.overrideWith((ref) => FakeOrderNotifier(testOrders)),
            ],
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                padding: const EdgeInsets.only(top: 24, bottom: 16),
              ),
              child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: Locale('en'),
                home: MyOrdersScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Restore error handler
        FlutterError.onError = originalOnError;

        // Verify that NO overflow error was captured
        expect(capturedError, isNull, reason: 'RenderFlex overflow detected on size ${entry.key}: ${capturedError?.exception}');

        // Verify order items exist
        expect(find.text('TOTAL ORDERS: 4'), findsOneWidget);
        expect(find.textContaining('ORD-1789027274842-79805629103847291048'), findsOneWidget);
        expect(find.text('PROCESSING'), findsOneWidget);

        // Verify that tester took no uncaught exceptions
        final exception = tester.takeException();
        expect(exception, isNull, reason: 'Exception on size ${entry.key}: $exception');
      });
    }
  });
}
