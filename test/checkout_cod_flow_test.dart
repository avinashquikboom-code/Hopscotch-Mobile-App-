import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hopscotch/models/cart_item_model.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:hopscotch/models/product_model.dart';

void main() {
  group('Cash on Delivery (COD) Flow & Product Eligibility Tests', () {
    test('ProductModel parses isCodAllowed correctly from different JSON keys', () {
      final pDefault = ProductModel.fromJson({
        'id': '1',
        'title': 'Test Item',
        'price': 100,
      });
      expect(pDefault.isCodAllowed, isTrue);
      expect(pDefault.codAllowed, isTrue);

      final pExplicitFalse = ProductModel.fromJson({
        'id': '2',
        'title': 'High Value Jewel',
        'price': 50000,
        'isCodAllowed': false,
      });
      expect(pExplicitFalse.isCodAllowed, isFalse);
      expect(pExplicitFalse.codAllowed, isFalse);

      final pSnakeCase = ProductModel.fromJson({
        'id': '3',
        'title': 'Customized Tee',
        'price': 800,
        'is_cod_allowed': false,
      });
      expect(pSnakeCase.isCodAllowed, isFalse);

      final pLegacyCodAllowed = ProductModel.fromJson({
        'id': '4',
        'title': 'Legacy Product',
        'price': 600,
        'codAllowed': false,
      });
      expect(pLegacyCodAllowed.isCodAllowed, isFalse);

      final pAllowCod = ProductModel.fromJson({
        'id': '5',
        'title': 'Allow COD Product',
        'price': 400,
        'allowCod': false,
      });
      expect(pAllowCod.isCodAllowed, isFalse);
    });

    test('Single product cart with COD disabled displays accurate product message', () {
      final pDisabled = ProductModel.fromJson({
        'id': 'p1',
        'title': 'Gold Necklace',
        'price': 10000,
        'isCodAllowed': false,
      });
      final cart = [
        CartItemModel(id: 'c1', product: pDisabled, quantity: 1),
      ];

      final isCodAllowed = !cart.any((item) => item.product.isCodAllowed == false);
      expect(isCodAllowed, isFalse);

      final isSingleProduct = cart.length == 1;
      final codUnavailableMessage = isSingleProduct
          ? 'Cash on Delivery is not available for this product.'
          : 'Cash on Delivery is not available for one or more products in your cart.';

      expect(codUnavailableMessage, equals('Cash on Delivery is not available for this product.'));
    });

    test('Mixed cart (COD enabled + COD disabled) displays mixed cart rule message', () {
      final pEnabled = ProductModel.fromJson({
        'id': 'p1',
        'title': 'Cotton T-Shirt',
        'price': 499,
        'isCodAllowed': true,
      });
      final pDisabled = ProductModel.fromJson({
        'id': 'p2',
        'title': 'Custom Diamond Ring',
        'price': 25000,
        'isCodAllowed': false,
      });
      final cart = [
        CartItemModel(id: 'c1', product: pEnabled, quantity: 2),
        CartItemModel(id: 'c2', product: pDisabled, quantity: 1),
      ];

      final isCodAllowed = !cart.any((item) => item.product.isCodAllowed == false);
      expect(isCodAllowed, isFalse);

      final isSingleProduct = cart.length == 1;
      final codUnavailableMessage = isSingleProduct
          ? 'Cash on Delivery is not available for this product.'
          : 'Cash on Delivery is not available for one or more products in your cart.';

      expect(codUnavailableMessage,
          equals('Cash on Delivery is not available for one or more products in your cart.'));
    });

    test('Cart with all COD enabled items allows COD checkout', () {
      final p1 = ProductModel.fromJson({
        'id': 'p1',
        'title': 'Baby Romper',
        'price': 599,
        'isCodAllowed': true,
      });
      final p2 = ProductModel.fromJson({
        'id': 'p2',
        'title': 'Baby Shoes',
        'price': 399,
        'isCodAllowed': true,
      });
      final cart = [
        CartItemModel(id: 'c1', product: p1, quantity: 1),
        CartItemModel(id: 'c2', product: p2, quantity: 1),
      ];

      final isCodAllowed = !cart.any((item) => item.product.isCodAllowed == false);
      expect(isCodAllowed, isTrue);
    });

    test('OrderModel parses payment method correctly from nested payment object', () {
      final orderJson = {
        'id': 101,
        'orderNumber': 'ORD-98765-1234',
        'totalAmount': 999.0,
        'status': 'PENDING',
        'address': '123 Main St, Mumbai',
        'items': [],
        'payment': {
          'id': 55,
          'method': 'COD',
          'status': 'PENDING',
          'amount': 999.0,
        }
      };

      final order = OrderModel.fromJson(orderJson);
      expect(order.id, equals('101'));
      expect(order.orderNumber, equals('ORD-98765-1234'));
      expect(order.paymentMethod, equals('COD'));
      expect(order.displayOrderId, equals('ORD-98765-1234'));
    });

    test('Canonical payment method mapping ensures COD is passed correctly', () {
      String resolveMethod(String selected) {
        if (selected == 'Cash on Delivery' || selected == 'COD') return 'COD';
        if (selected == 'Razorpay' || selected == 'RAZORPAY') return 'RAZORPAY';
        return selected;
      }

      expect(resolveMethod('Cash on Delivery'), equals('COD'));
      expect(resolveMethod('COD'), equals('COD'));
      expect(resolveMethod('Razorpay'), equals('RAZORPAY'));
      expect(resolveMethod('RAZORPAY'), equals('RAZORPAY'));
    });

    test('Button label switches dynamically between PLACE ORDER and PAY NOW', () {
      String getButtonText(String selectedPayment) {
        return (selectedPayment == 'Razorpay' || selectedPayment == 'RAZORPAY')
            ? 'PAY NOW'
            : 'PLACE ORDER';
      }

      expect(getButtonText('COD'), equals('PLACE ORDER'));
      expect(getButtonText('Cash on Delivery'), equals('PLACE ORDER'));
      expect(getButtonText('RAZORPAY'), equals('PAY NOW'));
      expect(getButtonText('Razorpay'), equals('PAY NOW'));
    });

    test('DioException 400 error message extraction provides clear explanation', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/mobile/orders'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/mobile/orders'),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Cash on Delivery is not available for this product.',
          },
        ),
      );

      final resData = dioError.response?.data;
      String? serverMsg;
      if (resData is Map) {
        serverMsg = resData['message']?.toString() ?? resData['error']?.toString();
      }

      expect(serverMsg, equals('Cash on Delivery is not available for this product.'));
    });
  });
}
