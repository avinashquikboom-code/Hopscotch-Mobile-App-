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
  List<ProductModel> _filteredProducts = [];
  bool _isLoadingMore = false;
  int _displayLimit = 100;

  // Sorting state
  String _sortBy = 'Recommended'; // Recommended, LowToHigh, HighToLow, Rating

  // Filter state
  String? _selectedSize;
  String? _selectedColor;

  // View mode: grid (false) or vertical feed (true)
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

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    if (_isLoadingMore || _displayLimit >= _filteredProducts.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate database cursor fetch delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _displayLimit += 4;
          _isLoadingMore = false;
        });
      }
    });
  }

  List<ProductModel> _applyFiltersAndSort(List<ProductModel> allProducts) {
    List<ProductModel> result = List.from(allProducts);

    final subCatId = widget.subCategoryId;
    final catId = widget.categoryId;
    final subName = widget.subcategory?.trim().toLowerCase();

    // 1. If explicit subCategoryId is provided, filter by subcategory ID or name
    if (subCatId != null && subCatId.isNotEmpty) {
      final targetSubId = subCatId.toLowerCase();
      final targetSubName = subName ?? '';
      result = result.where((p) =>
        (p.subCategoryId != null && p.subCategoryId!.toLowerCase() == targetSubId) ||
        p.categoryId.toLowerCase() == targetSubId ||
        (targetSubName.isNotEmpty && (
          p.subcategory.toLowerCase() == targetSubName ||
          (p.subCategoryName != null && p.subCategoryName!.toLowerCase() == targetSubName)
        ))
      ).toList();
    }
    // 2. Else if categoryId is provided (top-level category view)
    else if (catId != null && catId.isNotEmpty) {
      final targetCatId = catId.toLowerCase();
      final catNameLower = widget.categoryName.trim().toLowerCase();

      result = result.where((p) =>
        p.categoryId.toLowerCase() == targetCatId ||
        (p.parentCategoryId != null && p.parentCategoryId!.toLowerCase() == targetCatId) ||
        (p.subCategoryId != null && p.subCategoryId!.toLowerCase() == targetCatId) ||
        p.subcategory.toLowerCase() == catNameLower
      ).toList();
    }

    // 3. Additional strict subcategory name filter if provided without subCategoryId
    if ((subCatId == null || subCatId.isEmpty) && subName != null && subName.isNotEmpty) {
      final subMatches = result.where((p) =>
        p.subcategory.toLowerCase() == subName ||
        (p.subCategoryName != null && p.subCategoryName!.toLowerCase() == subName)
      ).toList();
      result = subMatches;
    }

    // Filter by standard filters (trending / new)
    final filterVal = widget.filter?.toLowerCase();
    if (filterVal == 'trending' || filterVal == 'trending_products') {
      final matches = result.where((p) => p.isTrending).toList();
      result = matches.isNotEmpty ? matches : result.take(20).toList();
    } else if (filterVal == 'new' || filterVal == 'new_arrivals' || filterVal == 'newarrivals') {
      final matches = result.where((p) => p.isNewArrival).toList();
      result = matches.isNotEmpty ? matches : result.take(20).toList();
    }

    // Size filter
    if (_selectedSize != null) {
      result = result.where((p) => p.sizes.contains(_selectedSize!)).toList();
    }

    // Color filter
    if (_selectedColor != null) {
      result = result.where((p) => p.colors.contains(_selectedColor!)).toList();
    }

    // Apply Sorting
    switch (_sortBy) {
      case 'LowToHigh':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'HighToLow':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Recommended':
      default:
        // Default sort (e.g. isFeatured first)
        result.sort(
          (a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0),
        );
        break;
    }

    return result;
  }

  void _showFilterSortSheet() {
    final responsive = context.responsive;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8FAFC), // Premium light ivory backdrop
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
                    // Delicate Champagne Gold Handle Indicator
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

                    // Serif Luxury Title
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

                    // Sorting options
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

                    // Sizing filters
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
                            onPressed: () => context.pop(),
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
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName.toUpperCase(),
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      body: productsAsync.when(
        data: (allProducts) {
          final displayProducts = _applyFiltersAndSort(allProducts);
          _filteredProducts = displayProducts;

          if (displayProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: responsive.iconSize(64),
                    color: AppTheme.textLightColor,
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                  Text(
                    'No garments found',
                    style: TextStyle(
                      fontSize: responsive.fontSize20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                  Text(
                    'Try modifying your filters or sort choices.',
                    style: TextStyle(
                      fontSize: responsive.fontSize14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final paginatedList = displayProducts.take(_displayLimit).toList();

          return Column(
            children: [
              // Dynamic stats bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(AppTheme.spaceXL),
                  vertical: responsive.spacing(AppTheme.spaceS),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${displayProducts.length} Items Available',
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
                                : 'Filtered',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: responsive.fontSize13,
                            ),
                          ),
                          SizedBox(width: responsive.spacing(4)),
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
              // Show correct view based on mode
              Expanded(
                child: _isVerticalFeed
                    ? VerticalProductFeed(
                        products: paginatedList,
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
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width < 600
                              ? 2
                              : (MediaQuery.of(context).size.width < 900 ? 3 : 5),
                          mainAxisSpacing: AppTheme.spaceL,
                          crossAxisSpacing: AppTheme.spaceL,
                          childAspectRatio: 0.58,
                        ),
                        itemCount: paginatedList.length + (_isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= paginatedList.length) {
                            return const ProductCardSkeleton();
                          }
                          final product = paginatedList[index];
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
          );
        },
        loading: () => GridView.builder(
          padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width < 600
                ? 2
                : (MediaQuery.of(context).size.width < 900 ? 3 : 5),
            mainAxisSpacing: AppTheme.spaceL,
            crossAxisSpacing: AppTheme.spaceL,
            childAspectRatio: 0.58,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const ProductCardSkeleton(),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(fontSize: responsive.fontSize14),
          ),
        ),
      ),
    );
  }
}
