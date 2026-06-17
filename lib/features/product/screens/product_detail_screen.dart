import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:hopscotch/features/product/repositories/product_repository.dart';
import 'package:hopscotch/features/cart_wishlist/repositories/cart_wishlist_repository.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../../../core/widgets/animated_heart_button.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? heroTagPrefix;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.heroTagPrefix,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _activeImageIndex = 0;
  String? _selectedSize;
  String? _selectedColor;
  bool _isAddingToCart = false;
  bool _showCartSuccess = false;

  void _triggerAddToCart(product) async {
    if (_isAddingToCart || _showCartSuccess) return;
    setState(() {
      _isAddingToCart = true;
    });

    // Elegant loading delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isAddingToCart = false;
        _showCartSuccess = true;
      });
    }

    // Add to cart
    ref.read(cartProvider.notifier).addToCart(
          product,
          size: _selectedSize,
          color: _selectedColor,
        );

    // Dynamic success timeout
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _showCartSuccess = false;
      });
    }
  }

  // Custom helper to parse hex colors to Flutter Color objects
  Color _parseColor(String hexCode) {
    try {
      final code = hexCode.replaceAll('#', '');
      return Color(int.parse('FF$code', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Scaffold(
              body: Center(child: Text('Product not found')),
            );
          }

          final isFav = wishlist.any((p) => p.id == product.id);
          final similarProductsAsync = ref.watch(categoryProductsProvider(product.categoryId));

          // Set default size and color selections once loaded
          if (_selectedSize == null && product.sizes.isNotEmpty) {
            _selectedSize = product.sizes.first;
          }
          if (_selectedColor == null && product.colors.isNotEmpty) {
            _selectedColor = product.colors.first;
          }

          final imageList = [product.imageUrl, ...product.additionalImages];

          return Scaffold(
            body: Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: MediaQuery.of(context).size.width * 1.1,
                        pinned: true,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        backgroundColor: AppTheme.backgroundColor,
                        leadingWidth: 64,
                        leading: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.textPrimaryColor),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            },
                          ),
                        ),
                        actions: [
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedHeartButton(
                              isFav: isFav,
                              size: 20,
                              onTap: () {
                                ref.read(wishlistProvider.notifier).toggleWishlist(product);
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceM),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                onPageChanged: (index) {
                                  setState(() {
                                    _activeImageIndex = index;
                                  });
                                },
                                itemCount: imageList.length,
                                itemBuilder: (context, index) {
                                  final currentHeroTag = index == 0
                                      ? (widget.heroTagPrefix != null
                                          ? '${widget.heroTagPrefix}_product_image_${product.id}'
                                          : 'product_image_${product.id}')
                                      : 'gallery_${product.id}_$index';
                                  return Hero(
                                    tag: currentHeroTag,
                                    child: Image.network(
                                      imageList[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: AppTheme.borderColor.withOpacity(0.2),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: AppTheme.primaryColor.withOpacity(0.04),
                                        child: Center(
                                          child: Icon(
                                            Icons.checkroom_rounded,
                                            color: AppTheme.primaryColor.withOpacity(0.15),
                                            size: 80,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Gallery dots
                              if (imageList.length > 1)
                                Positioned(
                                  bottom: AppTheme.spaceXL,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      imageList.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: _activeImageIndex == index ? 18 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _activeImageIndex == index ? AppTheme.primaryColor : Colors.white.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Information Section
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.spaceXL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tag & Title
                              Text(
                                product.subcategory.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceS),
                              Text(
                                product.title,
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceM),

                              // Ratings & Price Wrap
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: AppTheme.spaceM,
                                spacing: AppTheme.spaceM,
                                children: [
                                  // Prices
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '₹${product.price.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (product.originalPrice > product.price) ...[
                                        const SizedBox(width: AppTheme.spaceM),
                                        Text(
                                          '₹${product.originalPrice.toStringAsFixed(2)}',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: AppTheme.textLightColor,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Rating summary
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, color: AppTheme.accentColor, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.rating.toString(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${product.reviewCount} Reviews)',
                                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spaceXL),

                              // Description
                              Text(
                                'Description',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppTheme.spaceS),
                              Text(
                                product.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceXL),

                              // Size Selection
                              if (product.sizes.isNotEmpty) ...[
                                Text(
                                  'Select Size',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppTheme.spaceM),
                                Row(
                                  children: product.sizes.map((sz) {
                                    final isSelected = _selectedSize == sz;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedSize = sz;
                                        });
                                      },
                                      child: Container(
                                        width: 45,
                                        height: 45,
                                        margin: const EdgeInsets.only(right: AppTheme.spaceM),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                          border: Border.all(
                                            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          sz,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: AppTheme.spaceXL),
                              ],

                              // Color Selection
                              if (product.colors.isNotEmpty) ...[
                                Text(
                                  'Select Color',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppTheme.spaceM),
                                Row(
                                  children: product.colors.map((hex) {
                                    final isSelected = _selectedColor == hex;
                                    final colorVal = _parseColor(hex);
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedColor = hex;
                                        });
                                      },
                                      child: Container(
                                        width: 45,
                                        height: 45,
                                        margin: const EdgeInsets.only(right: AppTheme.spaceM),
                                        decoration: BoxDecoration(
                                          color: colorVal,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? AppTheme.primaryColor : Colors.white,
                                            width: isSelected ? 4 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: AppTheme.spaceXL),
                              ],

                              // Reviews list
                              if (product.reviews.isNotEmpty) ...[
                                const Divider(),
                                const SizedBox(height: AppTheme.spaceXL),
                                Text(
                                  'Customer Reviews (${product.reviews.length})',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppTheme.spaceL),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: product.reviews.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spaceL),
                                  itemBuilder: (context, index) {
                                    final rev = product.reviews[index];
                                    return Container(
                                      padding: const EdgeInsets.all(AppTheme.spaceL),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                        border: Border.all(color: AppTheme.borderColor),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 18,
                                                    backgroundImage: rev.userAvatarUrl != null
                                                        ? NetworkImage(rev.userAvatarUrl!)
                                                        : null,
                                                    child: rev.userAvatarUrl == null
                                                        ? const Icon(Icons.person, size: 18)
                                                        : null,
                                                  ),
                                                  const SizedBox(width: AppTheme.spaceM),
                                                  Text(
                                                    rev.userName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                rev.date,
                                                style: const TextStyle(color: AppTheme.textLightColor, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppTheme.spaceS),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                Icons.star_rounded,
                                                color: i < rev.rating.toInt() ? AppTheme.accentColor : AppTheme.borderColor,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: AppTheme.spaceS),
                                          Text(
                                            rev.comment,
                                            style: const TextStyle(color: AppTheme.textSecondaryColor, height: 1.4),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: AppTheme.spaceXL),
                              ],

                              // Similar Products
                              const Divider(),
                              const SizedBox(height: AppTheme.spaceXL),
                              Text(
                                'You May Also Elite',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              SizedBox(
                                height: 290,
                                child: similarProductsAsync.when(
                                  data: (products) {
                                    final filtered = products.where((p) => p.id != product.id).toList();
                                    if (filtered.isEmpty) {
                                      return const Center(child: Text('No recommendations available'));
                                    }
                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final p = filtered[index];
                                        return Container(
                                          width: 175,
                                          margin: const EdgeInsets.only(right: AppTheme.spaceL),
                                          child: ProductCard(
                                            product: p,
                                            heroTagPrefix: 'similar',
                                            onTap: () {
                                              context.pushReplacement('/product/${p.id}?heroTagPrefix=similar');
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  loading: () => ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 3,
                                    itemBuilder: (context, index) => Container(
                                      width: 175,
                                      margin: const EdgeInsets.only(right: AppTheme.spaceL),
                                      child: const ProductCardSkeleton(),
                                    ),
                                  ),
                                  error: (err, stack) => Center(child: Text('Error: $err')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Floating Transparent bottom buttons
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceXL),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      border: const Border(top: BorderSide(color: AppTheme.borderColor)),
                    ),
                    child: Row(
                      children: [
                        // Add to Cart (Outlined with Micro-Animation)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isAddingToCart || _showCartSuccess
                                ? null
                                : () => _triggerAddToCart(product),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                            ),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              child: _isAddingToCart
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                      ),
                                    )
                                  : (_showCartSuccess
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_rounded, size: 18, color: AppTheme.primaryColor),
                                            SizedBox(width: 6),
                                            Text('ADDED', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                          ],
                                        )
                                      : const Text('ADD TO CART', style: TextStyle(fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceL),
                        // Buy Now (Solid)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(cartProvider.notifier).addToCart(
                                    product,
                                    size: _selectedSize,
                                    color: _selectedColor,
                                  );
                              // Go straight to checkout screen!
                              context.push('/checkout');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              ),
                            ),
                            child: const Text('BUY NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
