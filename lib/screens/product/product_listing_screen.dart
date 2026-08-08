import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/product_repository.dart';
import 'package:hopscotch/widgets/product_card.dart';
import 'package:hopscotch/widgets/skeleton_loaders.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/utils/navigation_utils.dart';
import 'package:hopscotch/widgets/vertical_product_feed.dart';
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

  List<ProductModel> _products = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  int _totalCount = 0;
  String? _error;

  String _sortBy = 'Recommended';
  String? _selectedSize;
  String? _selectedColor;
  bool _isVerticalFeed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  ProductListFilters _buildApiFilters() {
    String? catId;
    if (widget.subCategoryId != null && widget.subCategoryId!.isNotEmpty) {
      catId = widget.subCategoryId;
    } else if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
      catId = widget.categoryId;
    }

    String sort = 'newest';
    switch (_sortBy) {
      case 'LowToHigh':
        sort = 'price_asc';
        break;
      case 'HighToLow':
        sort = 'price_desc';
        break;
      case 'Rating':
        sort = 'rating';
        break;
      case 'Recommended':
      default:
        sort = 'newest';
    }

    final filterVal = widget.filter?.toLowerCase();
    bool? trending;
    bool? newArrival;
    if (filterVal == 'trending' || filterVal == 'trending_products') {
      trending = true;
      if (_sortBy == 'Recommended') sort = 'popular';
    } else if (filterVal == 'new' ||
        filterVal == 'new_arrivals' ||
        filterVal == 'newarrivals') {
      newArrival = true;
    } else if (filterVal == 'top_rated' && _sortBy == 'Recommended') {
      sort = 'rating';
    }

    return ProductListFilters(
      categoryId: catId,
      isTrending: trending,
      isNewArrival: newArrival,
      sort: sort,
    );
  }

  List<ProductModel> _applyLocalFilters(List<ProductModel> items) {
    var result = List<ProductModel>.from(items);

    if (_selectedSize != null) {
      result = result.where((p) => p.sizes.contains(_selectedSize!)).toList();
    }
    if (_selectedColor != null) {
      result = result.where((p) => p.colors.contains(_selectedColor!)).toList();
    }

    if (_sortBy == 'Recommended') {
      result.sort(
        (a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0),
      );
    }

    return result;
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isInitialLoading = true;
      _error = null;
      _products = [];
      _currentPage = 0;
      _hasMore = true;
      _totalCount = 0;
    });

    await _fetchPage(1, reset: true);
  }

  Future<void> _fetchPage(int page, {bool reset = false}) async {
    try {
      final repo = ref.read(productRepositoryProvider);
      final result = await repo.fetchProductPage(
        filters: _buildApiFilters(),
        page: page,
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          _products = result.products;
        } else {
          final existingIds = _products.map((p) => p.id).toSet();
          for (final p in result.products) {
            if (!existingIds.contains(p.id)) {
              _products.add(p);
            }
          }
        }
        _currentPage = page;
        _hasMore = result.hasMore;
        _totalCount = result.total;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        if (reset) _error = e.toString();
      });
    }
  }

  void _loadMoreProducts() {
    if (_isLoadingMore || !_hasMore || _isInitialLoading) return;

    setState(() => _isLoadingMore = true);
    _fetchPage(_currentPage + 1);
  }

  void _showFilterSortSheet() {
    final responsive = context.responsive;
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
                      children: ['XS', 'S', 'M', 'L', 'XL'].map((sz) {
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
                              _loadFirstPage();
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
                              _loadFirstPage();
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
    final displayProducts = _applyLocalFilters(_products);
    final countLabel = _totalCount > 0
        ? '$_totalCount Items'
        : '${displayProducts.length} Items';

    String headerTitle = widget.categoryName.trim();
    if (headerTitle.isEmpty || headerTitle == 'Elite Clothing') {
      if (widget.subcategory != null && widget.subcategory!.trim().isNotEmpty) {
        headerTitle = widget.subcategory!.trim();
      } else if (widget.filter != null && widget.filter!.trim().isNotEmpty) {
        final f = widget.filter!.toLowerCase().trim();
        if (f == 'trending' || f == 'trending_products') headerTitle = 'Trending Products';
        else if (f == 'new' || f == 'new_arrivals' || f == 'newarrivals') headerTitle = 'New Arrivals';
        else if (f == 'popular' || f == 'best_sellers' || f == 'bestsellers') headerTitle = 'Best Sellers';
        else if (f == 'featured' || f == 'featured_products') headerTitle = 'Featured Products';
        else headerTitle = widget.filter!;
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
            onPressed: _showFilterSortSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: _isInitialLoading
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
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          children: [
                            Text('Failed to load products'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadFirstPage,
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
                                  onTap: _showFilterSortSheet,
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
                                    loadingExtra: _isLoadingMore ? 2 : 0,
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
                                        (_isLoadingMore ? 2 : 0),
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
