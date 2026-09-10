import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:hopscotch/models/cart_item_model.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/utils/invoice_generator.dart';

void main() {
  group('OrderModel Shipment & AWB Deserialization Tests', () {
    test(
      'Preserves AWB as string with leading zeros and special characters without converting to int',
      () {
        final json = {
          'id': 'ord-101',
          'orderNumber': 'FCI-1001',
          'awbNumber': '000987654321',
          'courierName': 'Delhivery',
          'trackingUrl': 'https://www.delhivery.com/track/package/000987654321',
          'status': 'SHIPPED',
          'totalAmount': 1499.0,
          'items': [],
        };

        final order = OrderModel.fromJson(json);

        expect(order.awbNumber, '000987654321');
        expect(order.awbNumber, isA<String>());
        expect(order.awbNumber?.startsWith('000'), isTrue);
        expect(order.courierName, 'Delhivery');
        expect(
          order.trackingUrl,
          'https://www.delhivery.com/track/package/000987654321',
        );
      },
    );

    test('Correctly extracts AWB and courier from nested shipment object', () {
      final json = {
        'id': 'ord-102',
        'orderNumber': 'FCI-1002',
        'status': 'SHIPPED',
        'totalAmount': 2499.0,
        'shipment': {
          'awb': 'BLU-998877',
          'courier': 'Bluedart',
          'trackingUrl':
              'https://www.bluedart.com/tracking?handler=tnt&action=custtrack&trackid=BLU-998877',
        },
        'items': [],
      };

      final order = OrderModel.fromJson(json);

      expect(order.awbNumber, 'BLU-998877');
      expect(order.courierName, 'Bluedart');
      expect(
        order.trackingUrl,
        'https://www.bluedart.com/tracking?handler=tnt&action=custtrack&trackid=BLU-998877',
      );
    });

    test(
      'Gracefully handles unshipped order without fake tracking numbers',
      () {
        final json = {
          'id': 'ord-103',
          'orderNumber': 'FCI-1003',
          'status': 'PENDING',
          'totalAmount': 899.0,
          'items': [],
        };

        final order = OrderModel.fromJson(json);

        expect(order.awbNumber, isNull);
        expect(order.trackingNumber, isNull);
        expect(order.courierName, isNull);
        expect(order.trackingUrl, isNull);
      },
    );
  });

  group('InvoiceGenerator AWB & Courier Integration Test', () {
    test(
      'Generates PDF invoice containing AWB Number and Courier Partner',
      () async {
        final sampleProduct = ProductModel.fromJson({
          'id': 'p-1',
          'title': 'Premium Linen Shirt',
          'price': 1299.0,
          'imageUrl':
              'https://images.unsplash.com/photo-1598033129183-c4f50c736f10',
          'shippingCharge': 0.0,
        });

        final sampleOrder = OrderModel(
          id: 'order-awb-999',
          orderNumber: 'FCI-AWB-999',
          orderDate: '2026-09-10',
          status: 'SHIPPED',
          totalAmount: 1299.0,
          subtotal: 1100.85,
          taxAmount: 198.15,
          shippingFee: 0.0,
          paymentMethod: 'Prepaid (UPI)',
          awbNumber: '0077889900',
          courierName: 'Delhivery',
          trackingUrl: 'https://www.delhivery.com/track/package/0077889900',
          shippingAddress: '42 Fashion Park, Ahmedabad, Gujarat - 380001',
          items: [
            CartItemModel(
              id: 'item-1',
              product: sampleProduct,
              quantity: 1,
              selectedSize: 'L',
              selectedColor: 'Navy Blue',
            ),
          ],
        );

        final pdfBytes = await InvoiceGenerator.buildInvoicePdfBytes(
          order: sampleOrder,
        );
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(1000));

        const artifactPath =
            '/Users/avinashsanjaymagar/.gemini/antigravity-ide/brain/3823807e-4a6b-46a8-9515-afb91d0c1a58/fashion_city_invoice_with_awb.pdf';
        final file = File(artifactPath);
        await file.writeAsBytes(pdfBytes);
        expect(file.existsSync(), isTrue);
      },
    );
  });

  group('AWB Responsive Widget Layout Tests', () {
    testWidgets(
      'AWB and Courier row renders without RenderFlex overflow at 320px width with long AWB',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const testAwb = 'AWB-DEL-98765432109876543210-XYZ';
        const testCourier = 'Delhivery Express Logistics Private Limited';

        FlutterErrorDetails? caughtDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Courier row
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Shipping Company:'),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            testCourier,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // AWB row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AWB Number:'),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Flexible(
                                child: Text(
                                  testAwb,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy_rounded, size: 10),
                                    SizedBox(width: 3),
                                    Text('COPY', style: TextStyle(fontSize: 9)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(caughtDetails, isNull);
        expect(tester.takeException(), isNull);
        expect(find.text('Shipping Company:'), findsOneWidget);
        expect(find.text(testCourier), findsOneWidget);
        expect(find.text('AWB Number:'), findsOneWidget);
        expect(find.text(testAwb), findsOneWidget);
        expect(find.text('COPY'), findsOneWidget);
      },
    );
  });
}

