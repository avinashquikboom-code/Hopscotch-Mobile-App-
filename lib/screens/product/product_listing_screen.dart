import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/widgets/product_card.dart';
import 'package:hopscotch/widgets/skeleton_loaders.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/utils/navigation_utils.dart';
import 'package:hopscotch/widgets/vertical_product_feed.dart';
import 'package:hopscotch/providers/product_list_provider.dart';
import 'package:remixicon/remixicon.dart';

class ProductListingScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? subCategoryId;
  final String? subcategory;
  final String? filter;
  final String categoryName;

  const ProductListingScreen({
    super.key,
    this.categoryId,
    this.subCategoryId,
    this.subcategory,
    this.filter,
    required this.categoryName,
  });

  @override
  ConsumerState<ProductListingScreen> createState() =>
      _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  final ScrollController _scrollController = ScrollController();

  String _sortBy = 'Recommended';
  String? _selectedSize;
  String? _selectedColor;
  bool _isVerticalFeed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ProductListingParams _currentParams() {
    String apiSort = 'newest';
    switch (_sortBy) {
      case 'LowToHigh':
        apiSort = 'price_asc';
        break;
      case 'HighToLow':
        apiSort = 'price_desc';
        break;
      case 'Rating':
        apiSort = 'rating';
        break;
      case 'Recommended':
      default:
        apiSort = 'newest';
    }

    return ProductListingParams(
      categoryId: widget.categoryId,
      subCategoryId: widget.subCategoryId,
      subcategory: widget.subcategory,
      filter: widget.filter,
      sort: apiSort,
    );
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final params = _currentParams();
      ref.read(paginatedProductsProvider(params).notifier).loadMore();
    }
  }

  List<ProductModel> _applyLocalFilters(List<ProductModel> items) {
    var result = List<ProductModel>.from(items);

    if (_selectedSize != null) {
      final target = _selectedSize!.trim().toLowerCase();
      result = result
          .where((p) => p.sizes.any((s) => s.trim().toLowerCase() == target))
          .toList();
    }
    if (_selectedColor != null) {
      final target = _selectedColor!.trim().toLowerCase();
      result = result
          .where((p) => p.colors.any((c) => c.trim().toLowerCase() == target))
          .toList();
    }

    if (_sortBy == 'Recommended') {
      result.sort(
        (a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0),
      );
    }

    return result;
  }

  void _showFilterSortSheet(List<ProductModel> rawProducts) {
    final responsive = context.responsive;

    // Dynamically derive sizes from the loaded products for this category
    final loadedSizes = rawProducts
        .expand((p) => p.sizes)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    final sizesToShow = loadedSizes.isNotEmpty
        ? loadedSizes
        : const ['XS', 'S', 'M', 'L', 'XL'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXXL),
          topRight: Radius.circular(AppTheme.radiusXXL),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(AppTheme.spaceXL),
                  vertical: responsive.spacing(AppTheme.spaceL),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: responsive.spacing(36),
                        height: responsive.spacing(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC59F3E).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                    Text(
                      'FILTER & SORT',
                      style: TextStyle(
                        fontSize: responsive.fontSize20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                    Text(
                      'SORT BY',
                      style: TextStyle(
                        fontSize: responsive.fontSize10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                    Wrap(
                      spacing: responsive.spacing(8),
                      runSpacing: responsive.spacing(8),
                      children: [
                        _buildChip(
                          label: 'Recommended',
                          isSelected: _sortBy == 'Recommended',
                          onTap: () => setSheetState(
                            () => setState(() => _sortBy = 'Recommended'),
                          ),
                        ),
                        _buildChip(
                          label: 'Price: Low to High',
                          isSelected: _sortBy == 'LowToHigh',
                          onTap: () => setSheetState(
                            () => setState(() => _sortBy = 'LowToHigh'),
                          ),
                        ),
                        _buildChip(
                          label: 'Price: High to Low',
                          isSelected: _sortBy == 'HighToLow',
                          onTap: () => setSheetState(
                            () => setState(() => _sortBy = 'HighToLow'),
                          ),
                        ),
                        _buildChip(
                          label: 'Top Rated',
                          isSelected: _sortBy == 'Rating',
                          onTap: () => setSheetState(
                            () => setState(() => _sortBy = 'Rating'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                    Text(
                      'SIZE',
                      style: TextStyle(
                        fontSize: responsive.fontSize10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                    Wrap(
                      spacing: responsive.spacing(8),
                      runSpacing: responsive.spacing(8),
                      children: sizesToShow.map((sz) {
                        return _buildChip(
                          label: sz,
                          isSelected: _selectedSize == sz,
                          onTap: () {
                            setSheetState(() {
                              setState(() {
                                _selectedSize = _selectedSize == sz ? null : sz;
                              });
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                setState(() {
                                  _selectedSize = null;
                                  _selectedColor = null;
                                  _sortBy = 'Recommended';
                                });
                              });
                              context.pop();
                            },
                            child: Text(
                              'Reset All',
                              style: TextStyle(fontSize: responsive.fontSize14),
                            ),
                          ),
                        ),
                        SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.pop();
                            },
                            child: Text(
                              'Apply',
                              style: TextStyle(fontSize: responsive.fontSize14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final responsive = context.responsive;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(14),
          vertical: responsive.spacing(10),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final params = _currentParams();
    final listingState = ref.watch(paginatedProductsProvider(params));

    final displayProducts = _applyLocalFilters(listingState.products);
    final countLabel = listingState.total > 0
        ? '${listingState.total} Items'
        : '${displayProducts.length} Items';

    String headerTitle = widget.categoryName.trim();
    if (headerTitle.isEmpty || headerTitle == 'Elite Clothing') {
      if (widget.subcategory != null && widget.subcategory!.trim().isNotEmpty) {
        headerTitle = widget.subcategory!.trim();
      } else if (widget.filter != null && widget.filter!.trim().isNotEmpty) {
        final f = widget.filter!.toLowerCase().trim();
        if (f == 'trending' || f == 'trending_products') {
          headerTitle = 'Trending Products';
        } else if (f == 'new' || f == 'new_arrivals' || f == 'newarrivals') {
          headerTitle = 'New Arrivals';
        } else if (f == 'popular' || f == 'best_sellers' || f == 'bestsellers') {
          headerTitle = 'Best Sellers';
        } else if (f == 'featured' || f == 'featured_products') {
          headerTitle = 'Featured Products';
        } else {
          headerTitle = widget.filter!;
        }
      } else {
        headerTitle = 'Products';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          headerTitle,
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: _isVerticalFeed ? 'Grid View' : 'Vertical Feed',
            icon: Icon(
              _isVerticalFeed ? Remix.grid_fill : Remix.layout_column_line,
              size: responsive.iconSize(22),
              color: _isVerticalFeed ? AppTheme.primaryColor : null,
            ),
            onPressed: () => setState(() => _isVerticalFeed = !_isVerticalFeed),
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded, size: responsive.iconSize(24)),
            onPressed: () => _showFilterSortSheet(listingState.products),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(paginatedProductsProvider(params).notifier).refresh();
        },
        child: listingState.isLoading
            ? GridView.builder(
                padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width < 600
                      ? 2
                      : (MediaQuery.of(context).size.width < 900 ? 3 : 5),
                  mainAxisSpacing: AppTheme.spaceL,
                  crossAxisSpacing: AppTheme.spaceL,
                  childAspectRatio: 0.58,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => const ProductCardSkeleton(),
              )
            : listingState.hasError
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: responsive.iconSize(64),
                              color: AppTheme.errorColor,
                            ),
                            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                            Text(
                              'Unable to load products',
                              style: TextStyle(
                                fontSize: responsive.fontSize20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(paginatedProductsProvider(params).notifier)
                                  .refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : displayProducts.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                          ),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: responsive.iconSize(64),
                                  color: AppTheme.textLightColor,
                                ),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceL),
                                ),
                                Text(
                                  'No products found',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceS),
                                ),
                                Text(
                                  'Try modifying your filters or sort choices.',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize14,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                if (_selectedSize != null ||
                                    _selectedColor != null) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedSize = null;
                                        _selectedColor = null;
                                      });
                                    },
                                    child: const Text('Reset Filters'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(AppTheme.spaceXL),
                              vertical: responsive.spacing(AppTheme.spaceS),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  countLabel,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _showFilterSortSheet(listingState.products),
                                  child: Row(
                                    children: [
                                      Text(
                                        _sortBy == 'Recommended'
                                            ? 'Recommended'
                                            : 'Sorted',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: responsive.fontSize13,
                                        ),
                                      ),
                                      SizedBox(
                                        width: responsive.spacing(4),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppTheme.primaryColor,
                                        size: responsive.iconSize(16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _isVerticalFeed
                                ? VerticalProductFeed(
                                    products: displayProducts,
                                    scrollController: _scrollController,
                                    loadingExtra:
                                        listingState.isLoadingMore ? 2 : 0,
                                    onTap: (product) => safeNavigate(
                                      context,
                                      '/product/${product.id}?heroTagPrefix=listing',
                                    ),
                                  )
                                : GridView.builder(
                                    controller: _scrollController,
                                    padding: EdgeInsets.all(
                                      responsive.spacing(AppTheme.spaceXL),
                                    ).copyWith(bottom: 40),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          MediaQuery.of(context).size.width <
                                                  600
                                              ? 2
                                              : (MediaQuery.of(context)
                                                          .size
                                                          .width <
                                                      900
                                                  ? 3
                                                  : 5),
                                      mainAxisSpacing: AppTheme.spaceL,
                                      crossAxisSpacing: AppTheme.spaceL,
                                      childAspectRatio: 0.58,
                                    ),
                                    itemCount: displayProducts.length +
                                        (listingState.isLoadingMore ? 2 : 0),
                                    itemBuilder: (context, index) {
                                      if (index >= displayProducts.length) {
                                        return const ProductCardSkeleton();
                                      }
                                      final product = displayProducts[index];
                                      return ProductCard(
                                        product: product,
                                        heroTagPrefix: 'listing',
                                        onTap: () => safeNavigate(
                                          context,
                                          '/product/${product.id}?heroTagPrefix=listing',
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
