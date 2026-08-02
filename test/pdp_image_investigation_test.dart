import 'package:flutter_test/flutter_test.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/repositories/product_repository.dart';
import 'package:hopscotch/constants/app_urls.dart';

void main() {
  group('PDP Image Investigation Tests', () {
    test('Parse Product 349 (Suit 3 peace N58H) from raw backend JSON', () {
      final rawJson = {
        "id": 349,
        "name": "Suit 3 peace N58H",
        "slug": "suit-3-peace-n58h",
        "description": "High quality suit",
        "status": "PUBLISHED",
        "basePrice": "2500.00",
        "discountValue": "10.00",
        "images": [
          {
            "id": 967,
            "productId": 349,
            "url": "/api/uploads/images/1785665039550-85851986-22328.jpg",
            "altText": "",
            "sortOrder": 0
          }
        ],
        "variants": []
      };

      // 1. Test mapBackendToMobileProduct
      final productMapped = mapBackendToMobileProduct(rawJson);
      expect(productMapped.id, '349');
      expect(productMapped.imageUrl, 'https://api.fciseller.com/api/uploads/images/1785665039550-85851986-22328.jpg');

      // 2. Test ProductModel.fromJson
      final productModel = ProductModel.fromJson(rawJson);
      expect(productModel.id, '349');
      expect(productModel.imageUrl, 'https://api.fciseller.com/api/uploads/images/1785665039550-85851986-22328.jpg');
      expect(productModel.additionalImages, contains('https://api.fciseller.com/api/uploads/images/1785665039550-85851986-22328.jpg'));
    });

    test('Parse product with S3 image URLs', () {
      final rawJson = {
        "id": 100,
        "name": "S3 Suit Luxury",
        "basePrice": 4999.00,
        "images": [
          {
            "id": 1,
            "productId": 100,
            "url": "https://hopscotch-bt.s3.ap-south-1.amazonaws.com/products/sample_suit.jpg",
            "altText": "Front view",
            "sortOrder": 0
          },
          {
            "id": 2,
            "productId": 100,
            "url": "https://hopscotch-bt.s3.ap-south-1.amazonaws.com/products/sample_suit_back.jpg",
            "altText": "Back view",
            "sortOrder": 1
          }
        ]
      };

      final productModel = ProductModel.fromJson(rawJson);
      expect(productModel.imageUrl, 'https://hopscotch-bt.s3.ap-south-1.amazonaws.com/products/sample_suit.jpg');
      expect(productModel.additionalImages.length, 2);
      expect(productModel.additionalImages, contains('https://hopscotch-bt.s3.ap-south-1.amazonaws.com/products/sample_suit_back.jpg'));
    });

    test('Verify image list resolving logic used in ProductDetailScreen', () {
      final product = ProductModel.fromJson({
        "id": 349,
        "name": "Suit 3 peace N58H",
        "basePrice": 2500,
        "images": [
          {
            "id": 967,
            "url": "/api/uploads/images/1785665039550-85851986-22328.jpg"
          }
        ]
      });

      final rawImageList = <String>[
        if (product.imageUrl.trim().isNotEmpty) AppUrls.resolveUrl(product.imageUrl),
        ...product.additionalImages.map(AppUrls.resolveUrl),
        if (product.variants.isNotEmpty)
          ...product.variants
              .map((v) => AppUrls.resolveUrl(v.imageUrl))
              .where((url) => url.isNotEmpty),
      ];

      final imageList = rawImageList.where((url) => url.trim().isNotEmpty && url != 'https://api.fciseller.com/' && url != 'https://api.fciseller.com').toSet().toList();

      expect(imageList.length, 1);
      expect(imageList.first, 'https://api.fciseller.com/api/uploads/images/1785665039550-85851986-22328.jpg');
    });
  });
}
