import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:hopscotch/features/product/repositories/product_repository.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import 'package:hopscotch/features/product/models/product_model.dart';

class ProductListingScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? subcategory;
  final String? filter;
  final String categoryName;

  const ProductListingScreen({
    super.key,
    this.categoryId,
    this.subcategory,
    this.filter,
    required this.categoryName,
  });

  @override
  ConsumerState<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ProductModel> _filteredProducts = [];
  bool _isLoadingMore = false;
  int _displayLimit = 6;

  // Sorting state
  String _sortBy = 'Recommended'; // Recommended, LowToHigh, HighToLow, Rating

  // Filter state
  String? _selectedSize;
  String? _selectedColor;

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
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

    // Filter by category
    if (widget.categoryId != null) {
      result = result.where((p) => p.categoryId == widget.categoryId).toList();
    }

    // Filter by subcategory
    if (widget.subcategory != null) {
      result = result.where((p) => p.subcategory == widget.subcategory).toList();
    }

    // Filter by standard filters (trending / new)
    if (widget.filter == 'trending') {
      result = result.where((p) => p.isTrending).toList();
    } else if (widget.filter == 'new') {
      result = result.where((p) => p.isNewArrival).toList();
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
        result.sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
        break;
    }

    return result;
  }

  void _showFilterSortSheet() {
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
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL, vertical: AppTheme.spaceL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delicate Champagne Gold Handle Indicator
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC59F3E).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Serif Luxury Title
                    const Text(
                      'FILTER & SORT',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Sorting options
                    const Text(
                      'SORT BY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(
                          label: 'Recommended',
                          isSelected: _sortBy == 'Recommended',
                          onTap: () => setSheetState(() => setState(() => _sortBy = 'Recommended')),
                        ),
                        _buildChip(
                          label: 'Price: Low to High',
                          isSelected: _sortBy == 'LowToHigh',
                          onTap: () => setSheetState(() => setState(() => _sortBy = 'LowToHigh')),
                        ),
                        _buildChip(
                          label: 'Price: High to Low',
                          isSelected: _sortBy == 'HighToLow',
                          onTap: () => setSheetState(() => setState(() => _sortBy = 'HighToLow')),
                        ),
                        _buildChip(
                          label: 'Top Rated',
                          isSelected: _sortBy == 'Rating',
                          onTap: () => setSheetState(() => setState(() => _sortBy = 'Rating')),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceXL),

                    // Sizing filters
                    const Text(
                      'SIZE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                    const SizedBox(height: AppTheme.spaceXXL),

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
                            child: const Text('Reset All'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceM),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName.toUpperCase()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
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
            icon: const Icon(Icons.tune_rounded),
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
                  const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textLightColor),
                  const SizedBox(height: AppTheme.spaceL),
                  Text(
                    'No garments found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  Text(
                    'Try modifying your filters or sort choices.',
                    style: Theme.of(context).textTheme.bodyMedium,
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
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL, vertical: AppTheme.spaceS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${displayProducts.length} Items Available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: _showFilterSortSheet,
                      child: Row(
                        children: [
                          Text(
                            _sortBy == 'Recommended' ? 'Recommended' : 'Filtered',
                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppTheme.spaceXL).copyWith(bottom: 40),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : (MediaQuery.of(context).size.width < 900 ? 3 : 5),
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
                      onTap: () => context.push('/product/${product.id}?heroTagPrefix=listing'),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceXL),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : (MediaQuery.of(context).size.width < 900 ? 3 : 5),
            mainAxisSpacing: AppTheme.spaceL,
            crossAxisSpacing: AppTheme.spaceL,
            childAspectRatio: 0.58,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const ProductCardSkeleton(),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
