import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopscotch/constants/seller_constants.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:hopscotch/models/cart_item_model.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/utils/invoice_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Invoice Seller Name & Normalization Tests', () {
    test('SellerConfig defaults must be Fashion City India Ltd', () {
      expect(SellerConfig.name, equals('Fashion City India Ltd'));
      expect(SellerConfig.legalName, equals('Fashion City India Ltd'));
      expect(SellerConfig.gstin, equals('24GUKPS9446A1ZA'));
      expect(SellerConfig.supportEmail, equals('fashioncityinidia18@gmail.com'));
      expect(
        SellerConfig.address,
        equals('F/7 Jethabhai Park, Narayan Nagar Road, Paldi, Ahmedabad, Gujarat - 380007, India'),
      );
    });

    test('SellerConfig.normalizeSellerName handles case variants and trims', () {
      expect(SellerConfig.normalizeSellerName('fci'), equals('Fashion City India Ltd'));
      expect(SellerConfig.normalizeSellerName('FCI'), equals('Fashion City India Ltd'));
      expect(SellerConfig.normalizeSellerName('  fci  '), equals('Fashion City India Ltd'));
      expect(SellerConfig.normalizeSellerName('FCI Seller'), equals('Fashion City India Ltd'));
      expect(SellerConfig.normalizeSellerName('fci seller'), equals('Fashion City India Ltd'));
      expect(SellerConfig.normalizeSellerName('fci-seller'), equals('Fashion City India Ltd'));
      expect(SellerConfig.normalizeSellerName('fciseller'), equals('Fashion City India Ltd'));
      expect(SellerConfig.normalizeSellerName(null), equals('Fashion City India Ltd'));
      expect(SellerConfig.normalizeSellerName(''), equals('Fashion City India Ltd'));
    });

    test('OrderModel normalizes legacy "FCI" seller name snapshot', () {
      final jsonWithFci = {
        'id': '1001',
        'orderNumber': 'ORD-2026-FCI-1001',
        'status': 'confirmed',
        'totalAmount': 4999.0,
        'subtotal': 4999.0,
        'shippingFee': 0.0,
        'sellerNameSnapshot': 'FCI',
        'sellerAddressSnapshot': SellerConfig.address,
        'sellerContactSnapshot': SellerConfig.contactNumber,
        'items': [],
      };

      final order = OrderModel.fromJson(jsonWithFci);
      expect(order.sellerName, equals('Fashion City India Ltd'));
    });

    test('OrderModel normalizes legacy "FCI Seller" seller name snapshot', () {
      final jsonWithFciSeller = {
        'id': '1002',
        'orderNumber': 'ORD-2026-FCI-1002',
        'status': 'confirmed',
        'totalAmount': 2499.0,
        'subtotal': 2499.0,
        'shippingFee': 0.0,
        'sellerNameSnapshot': 'FCI Seller',
        'sellerAddressSnapshot': SellerConfig.address,
        'sellerContactSnapshot': SellerConfig.contactNumber,
        'items': [],
      };

      final order = OrderModel.fromJson(jsonWithFciSeller);
      expect(order.sellerName, equals('Fashion City India Ltd'));
    });

    test('OrderModel preserves custom third-party seller names if applicable', () {
      final jsonWithOther = {
        'id': '1003',
        'orderNumber': 'ORD-2026-FCI-1003',
        'status': 'confirmed',
        'totalAmount': 3499.0,
        'sellerNameSnapshot': 'Boutique Atelier India',
        'items': [],
      };

      final order = OrderModel.fromJson(jsonWithOther);
      expect(order.sellerName, equals('Boutique Atelier India'));
    });

    test('InvoiceGenerator generates a real PDF invoice with Fashion City India Ltd', () async {
      final p1 = ProductModel.fromJson({
        'id': 'p1',
        'title': 'Silk Floral Embroidered Kurti',
        'price': 2999.0,
        'originalPrice': 3999.0,
        'imageUrl': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b',
        'shippingCharge': 0.0,
      });

      final p2 = ProductModel.fromJson({
        'id': 'p2',
        'title': 'Handcrafted Cotton Palazzo',
        'price': 2000.0,
        'originalPrice': 2499.0,
        'imageUrl': 'https://images.unsplash.com/photo-1509631179647-0177331693ae',
        'shippingCharge': 0.0,
      });

      final testOrder = OrderModel(
        id: '1001',
        orderNumber: 'ORD-2026-FCI-1001',
        orderDate: '2026-09-10T08:30:00.000Z',
        status: 'Delivered',
        totalAmount: 4999.0,
        subtotal: 4999.0,
        shippingFee: 0.0,
        shippingAddress: 'Pooja Sharma, Flat 402, Royal Palms, Link Road, Mumbai, Maharashtra - 400053',
        paymentMethod: 'Prepaid (UPI)',
        sellerName: SellerConfig.name,
        sellerAddress: SellerConfig.address,
        sellerContact: SellerConfig.contactNumber,
        items: [
          CartItemModel(
            id: 'item1',
            product: p1,
            quantity: 1,
            selectedSize: 'M',
            selectedColor: 'Emerald Green',
          ),
          CartItemModel(
            id: 'item2',
            product: p2,
            quantity: 1,
            selectedSize: 'Free Size',
            selectedColor: 'Off White',
          ),
        ],
      );

      final pdfBytes = await InvoiceGenerator.buildInvoicePdfBytes(order: testOrder);
      expect(pdfBytes.isNotEmpty, isTrue);

      // Verify PDF magic header bytes '%PDF'
      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, equals('%PDF'));
      expect(pdfBytes.length, greaterThan(2000));

      // Save PDF to artifact directory for visual inspection and verification
      const artifactPdfPath = '/Users/avinashsanjaymagar/.gemini/antigravity-ide/brain/3823807e-4a6b-46a8-9515-afb91d0c1a58/fashion_city_invoice.pdf';
      final pdfFile = File(artifactPdfPath);
      await pdfFile.writeAsBytes(pdfBytes);
      expect(pdfFile.existsSync(), isTrue);
      print('Real Invoice PDF successfully generated: $artifactPdfPath (${pdfBytes.length} bytes)');
    });
  });
}
