import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/visual_search_result.dart';
import '../../domain/entities/product.dart';
import 'package:hopscotch/core/providers/currency_provider.dart';

/// Interactive Visual Search Results Screen
/// Shows Exact Match, Variants, Similar, More from Brand, Recommended, Frequently Bought, Recently Viewed.
class VisualSearchResultsScreen extends ConsumerStatefulWidget {
  final VisualSearchResult result;

  const VisualSearchResultsScreen({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<VisualSearchResultsScreen> createState() => _VisualSearchResultsScreenState();
}

class _VisualSearchResultsScreenState extends ConsumerState<VisualSearchResultsScreen> {
  List<Product> _allProducts = [];
  bool _isLoading = true;
  String? _selectedSize;
  String? _selectedColor;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    try {
      final jsonString = await DefaultAssetBundle.of(context).loadString('assets/data/products.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      final products = jsonData.map((item) {
        final map = item as Map<String, dynamic>;
        return Product(
          id: map['id'] as String,
          name: map['name'] as String,
          brand: map['brand'] as String,
          category: map['category'] as String,
          subcategory: map['subcategory'] as String? ?? 'Casual',
          familyId: map['familyId'] as String?,
          variantId: map['variantId'] as String?,
          price: (map['price'] as num).toDouble(),
          description: map['description'] as String?,
          rating: (map['rating'] as num?)?.toDouble() ?? 4.0,
          ratingCount: map['rating_count'] as int? ?? 100,
          stock: map['stock'] as int? ?? 10,
          discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
          colors: List<String>.from(map['colors'] as List? ?? []),
          sizes: List<String>.from(map['sizes'] as List? ?? []),
          keywords: List<String>.from(map['keywords'] as List? ?? []),
          tags: List<String>.from(map['tags'] as List? ?? []),
          thumbnail: map['thumbnail'] as String?,
          multipleImages: List<String>.from(map['multipleImages'] as List? ?? []),
          relatedProducts: List<String>.from(map['relatedProducts'] as List? ?? []),
          similarProducts: List<String>.from(map['similarProducts'] as List? ?? []),
          recommendedProducts: List<String>.from(map['recommendedProducts'] as List? ?? []),
          createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
          primaryImagePath: map['images'] != null && (map['images'] as List).isNotEmpty
              ? (map['images'] as List)[0]['asset_path'] as String?
              : null,
        );
      }).toList();

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Product? get _exactProduct {
    final res = widget.result;
    if (res is ExactMatch) {
      return res.product;
    } else if (res is SimilarMatches && res.matches.isNotEmpty) {
      return res.matches.first.product;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Searching Catalog...', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0D9488)),
        ),
      );
    }

    final product = _exactProduct;
    if (product == null) {
      return _buildEmptyState();
    }

    // Set defaults
    _selectedColor ??= product.colors.isNotEmpty ? product.colors.first : null;
    _selectedSize ??= product.sizes.isNotEmpty ? product.sizes.first : null;

    final similarList = _allProducts.where((p) => p.category == product.category && p.id != product.id).toList();
    similarList.sort((a, b) {
      if (a.brand == product.brand && b.brand != product.brand) return -1;
      if (a.brand != product.brand && b.brand == product.brand) return 1;
      return 0;
    });
    final sameBrandList = _allProducts.where((p) => p.brand == product.brand && p.id != product.id).toList();
    final recommendedList = _allProducts.where((p) => p.id != product.id).toList()..shuffle();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Search Results', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Uploaded Image Summary Banner
            _buildUploadedImageHeader(),

            // 2. Exact Match Card
            _buildExactMatchSection(product, currency),

            // 3. More Variants
            if (product.colors.length > 1 || product.sizes.length > 1)
              _buildVariantsSection(product),

            // 4. Frequently Bought Together
            _buildFrequentlyBoughtSection(product, currency),

            // 5. Similar Products (Grid Layout)
            if (similarList.isNotEmpty)
              _buildSimilarProductsGrid(similarList, currency),

            // 6. More From Same Brand
            if (sameBrandList.isNotEmpty)
              _buildHorizontalProductsSection('More from ${product.brand}', sameBrandList, currency),

            // 7. Recommended Products
            if (recommendedList.isNotEmpty)
              _buildHorizontalProductsSection('Recommended Products', recommendedList.take(6).toList(), currency),

            // 8. Recently Viewed
            _buildHorizontalProductsSection('Recently Viewed', _allProducts.take(4).toList(), currency),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedImageHeader() {
    final queryImage = widget.result.queryImage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 50,
              child: queryImage != null
                  ? Image.file(queryImage, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF0D9488).withOpacity(0.1),
                      child: const Icon(Icons.image, color: Color(0xFF0D9488)),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual Search Query',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Showing matches for your uploaded photo',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0D9488)),
            onPressed: () => context.pop(),
            tooltip: 'Try another photo',
          ),
        ],
      ),
    );
  }

  Widget _buildExactMatchSection(Product product, AppCurrency currency) {
    final hasDiscount = product.discount > 0;
    final discountedPrice = product.price * (1 - (product.discount / 100));

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXACT MATCH',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D9488), letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 150,
                  child: widget.result.queryImage != null
                      ? Image.file(widget.result.queryImage!, fit: BoxFit.cover)
                      : _buildProductImage(product.primaryImagePath),
                ),
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.brand,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            _isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: _isWishlisted ? Colors.red : const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(() {
                              _isWishlisted = !_isWishlisted;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isWishlisted ? 'Added to Wishlist!' : 'Removed from Wishlist'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.ratingCount})',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Price
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            currency.formatPrice(hasDiscount ? discountedPrice : product.price),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF0D9488)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              currency.formatPrice(product.price),
                              style: const TextStyle(decoration: TextDecoration.lineThrough, color: Color(0xFF94A3B8), fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${product.discount.toStringAsFixed(0)}% OFF',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product added to Cart!'), duration: Duration(seconds: 1)),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add To Cart', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/checkout');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsSection(Product product) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MORE VARIANTS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D9488), letterSpacing: 1.2),
          ),
          if (product.colors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Available Colors', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: product.colors.map((color) {
                final isSelected = _selectedColor == color;
                return ChoiceChip(
                  label: Text(color),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                  checkmarkColor: const Color(0xFF0D9488),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF0F172A),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedColor = color;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
          if (product.sizes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Available Sizes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: product.sizes.map((size) {
                final isSelected = _selectedSize == size;
                return ChoiceChip(
                  label: Text(size),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                  checkmarkColor: const Color(0xFF0D9488),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF0F172A),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSize = size;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequentlyBoughtSection(Product product, AppCurrency currency) {
    final bundleProduct = _allProducts.firstWhere((p) => p.id != product.id, orElse: () => product);
    final totalPrice = product.price + bundleProduct.price;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FREQUENTLY BOUGHT TOGETHER',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D9488), letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Product 1
              _buildBundleItemThumb(product),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              ),
              // Product 2
              _buildBundleItemThumb(bundleProduct),
              const SizedBox(width: 16),
              // Price and add button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Combo Offer Price', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text(currency.formatPrice(totalPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added combo to Cart!'), duration: Duration(seconds: 1)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Add Combo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBundleItemThumb(Product product) {
    return Container(
      width: 70,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: _buildProductImage(product.primaryImagePath),
      ),
    );
  }

  Widget _buildSimilarProductsGrid(List<Product> products, AppCurrency currency) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SIMILAR PRODUCTS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D9488), letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: products.length.clamp(0, 4),
            itemBuilder: (context, index) {
              final p = products[index];
              return _buildProductCard(p, currency);
            },
          )
        ],
      ),
    );
  }

  Widget _buildHorizontalProductsSection(String title, List<Product> products, AppCurrency currency) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D9488), letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 140,
                    child: _buildProductCard(p, currency),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductCard(Product p, AppCurrency currency) {
    return GestureDetector(
      onTap: () {
        context.push('/product/${p.id}?heroTagPrefix=visual_search_results');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                child: _buildProductImage(p.primaryImagePath),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.brand, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(currency.formatPrice(p.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('No matches found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Could not find matches in the offline catalog.', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
        ),
      );
    }
    if (path.startsWith('http') || path.startsWith('https')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[100],
          child: const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        ),
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[100],
        child: const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      ),
    );
  }
}
