import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/providers/product_list_provider.dart';
import 'package:hopscotch/repositories/product_repository.dart';
import 'package:hopscotch/screens/product/product_listing_screen.dart';
import 'package:hopscotch/api/api_service.dart';

ProductModel makeDummyProduct({
  required String id,
  required String title,
  required String categoryId,
  String? subCategoryId,
  double price = 499.0,
  List<String> sizes = const ['4', '5', '6'],
  List<String> colors = const ['Brown', 'Black'],
  bool isFeatured = false,
}) {
  return ProductModel(
    id: id,
    title: title,
    description: 'Test product description',
    price: price,
    originalPrice: price,
    discountPercentage: 0,
    imageUrl: 'https://example.com/image.jpg',
    additionalImages: const [],
    categoryId: categoryId,
    parentCategoryId: '66',
    subCategoryId: subCategoryId ?? categoryId,
    subCategoryName: 'Ladies footwear',
    subcategory: 'Ladies footwear',
    rating: 4.5,
    reviewCount: 10,
    reviews: const [],
    sizes: sizes,
    colors: colors,
    isAvailable: true,
    isTrending: false,
    isNewArrival: false,
    isFeatured: isFeatured,
  );
}

class FakeApiService extends Fake implements ApiService {}

class FakeProductRepository extends ProductRepository {
  FakeProductRepository() : super(FakeApiService());

  bool shouldFail = false;
  List<ProductModel> mockProducts = [];

  @override
  Future<ProductPageResult> fetchProductPage({
    required ProductListFilters filters,
    required int page,
    int limit = 24,
  }) async {
    if (shouldFail) {
      throw Exception('Connection failed');
    }

    // Filter by category if specified
    var filtered = mockProducts;
    if (filters.categoryId != null && filters.categoryId!.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.categoryId == filters.categoryId ||
              p.subCategoryId == filters.categoryId)
          .toList();
    }

    if (filters.sort == 'price_asc') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (filters.sort == 'price_desc') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    final start = (page - 1) * limit;
    final paged = filtered.skip(start).take(limit).toList();

    return ProductPageResult(
      products: paged,
      page: page,
      total: filtered.length,
      totalPages: (filtered.length / limit).ceil(),
      hasMore: start + limit < filtered.length,
    );
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(
      String categoryIdOrName) async {
    return mockProducts
        .where((p) =>
            p.categoryId == categoryIdOrName ||
            p.subCategoryId == categoryIdOrName)
        .toList();
  }
}

void main() {
  group('ProductListingParams & State Tests', () {
    test('params equality and effectiveCategoryId resolution', () {
      const params1 = ProductListingParams(
        categoryId: '66',
        subCategoryId: '92',
        subcategory: 'Ladies footwear',
      );
      const params2 = ProductListingParams(
        categoryId: '66',
        subCategoryId: '92',
        subcategory: 'Ladies footwear',
      );
      const params3 = ProductListingParams(
        categoryId: '66',
        subCategoryId: '93',
        subcategory: 'Gents footwear',
      );

      expect(params1, equals(params2));
      expect(params1.hashCode, equals(params2.hashCode));
      expect(params1 == params3, isFalse);
      expect(params1.effectiveCategoryId, '92');

      const parentOnlyParams = ProductListingParams(categoryId: '66');
      expect(parentOnlyParams.effectiveCategoryId, '66');
    });

    test('notifier loads products, paginates, and handles error state', () async {
      final fakeRepo = FakeProductRepository();
      fakeRepo.mockProducts = List.generate(
        30,
        (i) => makeDummyProduct(
          id: '$i',
          title: 'Footwear $i',
          categoryId: '92',
          price: (i + 1) * 100.0,
        ),
      );

      const params = ProductListingParams(categoryId: '92');
      final notifier = PaginatedProductsNotifier(fakeRepo, params);

      // Wait for initial load
      await notifier.loadFirstPage();
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.hasError, isFalse);
      expect(notifier.state.products.length, 24);
      expect(notifier.state.total, 30);
      expect(notifier.state.hasMore, isTrue);

      // Load next page
      await notifier.loadMore();
      expect(notifier.state.products.length, 30);
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.page, 2);

      // Error handling
      fakeRepo.shouldFail = true;
      await notifier.loadFirstPage();
      expect(notifier.state.hasError, isTrue);
      expect(notifier.state.error, contains('Connection failed'));
      expect(notifier.state.products, isEmpty);
    });

    test('notifier true empty result when category has no products', () async {
      final fakeRepo = FakeProductRepository();
      fakeRepo.mockProducts = []; // Empty

      const params = ProductListingParams(categoryId: '999');
      final notifier = PaginatedProductsNotifier(fakeRepo, params);
      await notifier.loadFirstPage();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.hasError, isFalse);
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.products, isEmpty);
    });
  });

  group('ProductListingScreen UI Render Tests', () {
    testWidgets('renders products when data loaded', (tester) async {
      final fakeRepo = FakeProductRepository();
      fakeRepo.mockProducts = [
        makeDummyProduct(id: '1', title: 'Ladies Boots S37M', categoryId: '92'),
        makeDummyProduct(id: '2', title: 'Ladies Flats S20M', categoryId: '92'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: ProductListingScreen(
              categoryId: '92',
              categoryName: 'Ladies Footwear',
            ),
          ),
        ),
      );

      // Initial pump triggers loading skeleton
      await tester.pump();
      // Pump until futures finish
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ladies Footwear'), findsOneWidget);
      expect(find.text('Ladies Boots S37M'), findsOneWidget);
      expect(find.text('Ladies Flats S20M'), findsOneWidget);
      expect(find.text('2 Items'), findsOneWidget);
    });

    testWidgets('renders accurate empty state when category has 0 products',
        (tester) async {
      final fakeRepo = FakeProductRepository();
      fakeRepo.mockProducts = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: ProductListingScreen(
              categoryId: '92',
              categoryName: 'Ladies Footwear',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No products found'), findsOneWidget);
      expect(
        find.text('Try modifying your filters or sort choices.'),
        findsOneWidget,
      );
    });

    testWidgets('renders accurate error state with Retry button on API failure',
        (tester) async {
      final fakeRepo = FakeProductRepository();
      fakeRepo.shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: ProductListingScreen(
              categoryId: '92',
              categoryName: 'Ladies Footwear',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Unable to load products'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Now fix failure and tap Retry
      fakeRepo.shouldFail = false;
      fakeRepo.mockProducts = [
        makeDummyProduct(id: '1', title: 'Ladies Boots S37M', categoryId: '92'),
      ];

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ladies Boots S37M'), findsOneWidget);
      expect(find.text('Unable to load products'), findsNothing);
    });
  });
}
