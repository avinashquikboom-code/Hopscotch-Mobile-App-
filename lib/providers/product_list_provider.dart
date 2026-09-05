import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/repositories/product_repository.dart';

/// Parameters identifying a product listing view (category, subcategory, filter, sort).
class ProductListingParams {
  final String? categoryId;
  final String? subCategoryId;
  final String? subcategory;
  final String? filter;
  final String sort;

  const ProductListingParams({
    this.categoryId,
    this.subCategoryId,
    this.subcategory,
    this.filter,
    this.sort = 'newest',
  });

  /// Priority: subCategoryId -> categoryId
  String? get effectiveCategoryId {
    if (subCategoryId != null && subCategoryId!.trim().isNotEmpty) {
      return subCategoryId!.trim();
    }
    if (categoryId != null && categoryId!.trim().isNotEmpty) {
      return categoryId!.trim();
    }
    return null;
  }

  ProductListFilters toApiFilters() {
    final filterVal = filter?.toLowerCase().trim();
    bool? trending;
    bool? newArrival;
    String effectiveSort = sort;

    if (filterVal == 'trending' || filterVal == 'trending_products') {
      trending = true;
      if (effectiveSort == 'newest') effectiveSort = 'popular';
    } else if (filterVal == 'new' ||
        filterVal == 'new_arrivals' ||
        filterVal == 'newarrivals') {
      newArrival = true;
    } else if (filterVal == 'top_rated' && effectiveSort == 'newest') {
      effectiveSort = 'rating';
    }

    return ProductListFilters(
      categoryId: effectiveCategoryId,
      isTrending: trending,
      isNewArrival: newArrival,
      sort: effectiveSort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductListingParams &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          subCategoryId == other.subCategoryId &&
          subcategory == other.subcategory &&
          filter == other.filter &&
          sort == other.sort;

  @override
  int get hashCode => Object.hash(
        categoryId,
        subCategoryId,
        subcategory,
        filter,
        sort,
      );
}

/// Immutable state for paginated product lists.
class PaginatedProductsState {
  final List<ProductModel> products;
  final int page;
  final int total;
  final int totalPages;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PaginatedProductsState({
    this.products = const [],
    this.page = 1,
    this.total = 0,
    this.totalPages = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get isEmpty => !isLoading && error == null && products.isEmpty;
  bool get hasError => !isLoading && error != null && products.isEmpty;

  PaginatedProductsState copyWith({
    List<ProductModel>? products,
    int? page,
    int? total,
    int? totalPages,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return PaginatedProductsState(
      products: products ?? this.products,
      page: page ?? this.page,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Riverpod StateNotifier managing category product fetching, pagination, and refresh.
class PaginatedProductsNotifier
    extends StateNotifier<PaginatedProductsState> {
  final ProductRepository _repository;
  final ProductListingParams _params;

  PaginatedProductsNotifier(this._repository, this._params)
      : super(const PaginatedProductsState(isLoading: true)) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final filters = _params.toApiFilters();
      final result = await _repository.fetchProductPage(
        filters: filters,
        page: 1,
        limit: ProductRepository.listingPageSize,
      );

      List<ProductModel> items = result.products;
      int total = result.total;
      int totalPages = result.totalPages;
      bool hasMore = result.hasMore;

      // Safe fallback if paginated API returns empty for category ID
      if (items.isEmpty && _params.effectiveCategoryId != null) {
        final fallback =
            await _repository.getProductsByCategory(_params.effectiveCategoryId!);
        if (fallback.isNotEmpty) {
          items = fallback;
          total = fallback.length;
          totalPages = 1;
          hasMore = false;
        }
      }

      state = PaginatedProductsState(
        products: items,
        page: 1,
        total: total,
        totalPages: totalPages,
        hasMore: hasMore,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        products: const [],
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final filters = _params.toApiFilters();
      final result = await _repository.fetchProductPage(
        filters: filters,
        page: nextPage,
        limit: ProductRepository.listingPageSize,
      );

      final existingIds = state.products.map((p) => p.id).toSet();
      final merged = List<ProductModel>.from(state.products);
      for (final p in result.products) {
        if (!existingIds.contains(p.id)) {
          merged.add(p);
        }
      }

      state = state.copyWith(
        products: merged,
        page: nextPage,
        total: result.total > 0 ? result.total : merged.length,
        totalPages: result.totalPages,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await loadFirstPage();
  }
}

/// Auto-disposing Riverpod provider family parameterized by category, filter, and sort.
final paginatedProductsProvider = StateNotifierProvider.autoDispose.family<
    PaginatedProductsNotifier,
    PaginatedProductsState,
    ProductListingParams>((ref, params) {
  final repo = ref.watch(productRepositoryProvider);
  return PaginatedProductsNotifier(repo, params);
});
