import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/repositories/product_repository.dart';
import 'package:hopscotch/screens/product/product_detail_screen.dart';

void main() {
  testWidgets('PDP image gallery renders Image.network for valid product', (tester) async {
    final testProduct = ProductModel.fromJson({
      "id": 349,
      "name": "Suit 3 peace N58H",
      "basePrice": 949.0,
      "description": "Test description",
      "images": [
        {
          "id": 967,
          "productId": 349,
          "url": "https://api.fciseller.com/api/uploads/images/1785665039550-85851986-22328.jpg",
          "altText": "",
          "sortOrder": 0
        },
        {
          "id": 968,
          "productId": 349,
          "url": "https://api.fciseller.com/api/uploads/images/1785665039644-176421256-22332.jpg",
          "altText": "",
          "sortOrder": 1
        }
      ],
      "variants": []
    });

    final container = ProviderContainer(
      overrides: [
        productDetailProvider('349').overrideWith((ref) async => testProduct),
        categoryProductsProvider(testProduct.categoryId).overrideWith((ref) async => []),
      ],
    );

    // Build the widget tree with ProviderScope and MaterialApp
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductDetailScreen(productId: '349'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    print('Rendered Text Widgets: ${textWidgets.map((t) => t.data).toList()}');

    // Verify PageView exists
    expect(find.byType(PageView), findsOneWidget);


    // Verify Image.network is built for the images
    final imageWidgets = tester.widgetList<Image>(find.byType(Image));
    expect(imageWidgets.isNotEmpty, isTrue);

    final firstImage = imageWidgets.first;
    expect(firstImage.image, isA<NetworkImage>());
    final networkImage = firstImage.image as NetworkImage;
    expect(networkImage.url, 'https://api.fciseller.com/api/uploads/images/1785665039550-85851986-22328.jpg');
  });

  testWidgets('PDP image gallery uses errorBuilder when image fails to load', (tester) async {
    final testProduct = ProductModel.fromJson({
      "id": 999,
      "name": "Broken Image Product",
      "basePrice": 949.0,
      "images": [
        {
          "id": 9999,
          "productId": 999,
          "url": "https://api.fciseller.com/api/uploads/images/definitely_broken_image_9999.jpg",
          "altText": "",
          "sortOrder": 0
        }
      ],
      "variants": []
    });

    final container = ProviderContainer(
      overrides: [
        productDetailProvider('999').overrideWith((ref) async => testProduct),
        categoryProductsProvider(testProduct.categoryId).overrideWith((ref) async => []),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductDetailScreen(productId: '999'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final imageWidget = tester.widget<Image>(find.byType(Image).first);
    expect(imageWidget.errorBuilder, isNotNull);
  });
}



