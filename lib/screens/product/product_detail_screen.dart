import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/constants/app_colors.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/product_repository.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/widgets/product_card.dart';
import 'package:hopscotch/widgets/skeleton_loaders.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:remixicon/remixicon.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/widgets/share_earn_bottom_sheet.dart';
import 'package:hopscotch/widgets/fullscreen_image_viewer.dart';
import 'package:hopscotch/utils/navigation_utils.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? heroTagPrefix;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.heroTagPrefix,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _activeImageIndex = 0;
  String? _selectedSize;
  String? _selectedColor;
  double? _selectedVariantPrice;
  bool _isAddingToCart = false;
  bool _showCartSuccess = false;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _triggerAddToCart(product) async {
    if (_isAddingToCart || _showCartSuccess) return;
    HapticFeedback.mediumImpact();
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
    ref
        .read(cartProvider.notifier)
        .addToCart(product, size: _selectedSize, color: _selectedColor);

    HapticFeedback.lightImpact();

    // Dynamic success timeout
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _showCartSuccess = false;
      });
    }
  }


  // Custom helper to parse hex codes or color names to Flutter Color objects
  Color _parseColor(String colorStr) {
    if (colorStr.trim().isEmpty) return Colors.grey;
    final str = colorStr.trim().toLowerCase();
    const colorMap = <String, Color>{
      'black': Colors.black,
      'white': Colors.white,
      'red': Color(0xFFE53935),
      'blue': Color(0xFF1E88E5),
      'navy': Color(0xFF000080),
      'navy blue': Color(0xFF000080),
      'green': Color(0xFF43A047),
      'yellow': Color(0xFFFDD835),
      'orange': Color(0xFFFB8C00),
      'purple': Color(0xFF8E24AA),
      'pink': Color(0xFFD81B60),
      'grey': Color(0xFF757575),
      'gray': Color(0xFF757575),
      'brown': Color(0xFF6D4C41),
      'teal': Color(0xFF00897B),
      'cyan': Color(0xFF00ACC1),
      'gold': Color(0xFFFFD700),
      'silver': Color(0xFFC0C0C0),
      'maroon': Color(0xFF800000),
      'beige': Color(0xFFF5F5DC),
      'olive': Color(0xFF808000),
      'coral': Color(0xFFFF7F50),
      'indigo': Color(0xFF3F51B5),
      'khaki': Color(0xFFC3B091),
      'magenta': Color(0xFFE91E63),
    };

    if (colorMap.containsKey(str)) {
      return colorMap[str]!;
    }

    try {
      String hex = colorStr.replaceAll('#', '').replaceAll('0x', '').trim();
      if (hex.length == 3) {
        hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
      }
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    } catch (_) {}

    return Colors.teal;
  }

  void _selectColor(String colorName, dynamic product, List<String> imageList) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedColor = colorName;

      // Match variant details
      ProductVariantModel? matchingVariant;
      if (product is ProductModel && product.variants.isNotEmpty) {
        for (final v in product.variants) {
          if (v.color?.toLowerCase() == colorName.toLowerCase()) {
            if (_selectedSize != null && v.size?.toLowerCase() == _selectedSize?.toLowerCase()) {
              matchingVariant = v;
              break;
            }
            matchingVariant ??= v;
          }
        }
      }

      if (matchingVariant != null && matchingVariant.price > 0) {
        _selectedVariantPrice = matchingVariant.price;
      }

      // Sync image carousel
      int targetIndex = -1;
      if (matchingVariant != null && matchingVariant.imageUrl != null && matchingVariant.imageUrl!.isNotEmpty) {
        targetIndex = imageList.indexOf(matchingVariant.imageUrl!);
      }

      if (targetIndex == -1) {
        final colorLower = colorName.toLowerCase();
        targetIndex = imageList.indexWhere((url) => url.toLowerCase().contains(colorLower));
      }

      if (targetIndex == -1) {
        final colorIdx = (product.colors as List).indexOf(colorName);
        if (colorIdx >= 0 && colorIdx < imageList.length) {
          targetIndex = colorIdx;
        }
      }

      if (targetIndex >= 0 && targetIndex < imageList.length) {
        _activeImageIndex = targetIndex;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _openShareEarnBottomSheet(ProductModel product) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareEarnBottomSheet(product: product),
    );
  }

  Widget _buildFloatingCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final responsive = context.responsive;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: color ?? AppTheme.textPrimaryColor,
          size: responsive.iconSize(20),
        ),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final wishlist = ref.watch(wishlistProvider);
    final currency = ref.watch(currencyProvider);
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return Center(
              child: Text(
                l10n.productNotFound,
                style: TextStyle(fontSize: responsive.fontSize16),
              ),
            );
          }

          final isFav = wishlist.any((p) => p.id == product.id);
          final similarProductsAsync = ref.watch(
            categoryProductsProvider(product.categoryId),
          );

          // Set default size and color selections once loaded
          if (_selectedSize == null && product.sizes.isNotEmpty) {
            _selectedSize = product.sizes.first;
          }
          if (_selectedColor == null && product.colors.isNotEmpty) {
            _selectedColor = product.colors.first;
          }

          final imageList = [product.imageUrl, ...product.additionalImages];

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: MediaQuery.of(context).size.width * 1.1,
                        pinned: true,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        backgroundColor: AppTheme.backgroundColor,
                        leadingWidth: responsive.spacing(64),
                        leading: Container(
                          margin: EdgeInsets.all(responsive.spacing(8)),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              size: responsive.iconSize(20),
                              color: AppTheme.textPrimaryColor,
                            ),
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
                            margin: EdgeInsets.all(responsive.spacing(8)),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Consumer(
                              builder: (context, ref, _) {
                                final cartCount = ref.watch(cartProvider).fold<int>(0, (sum, item) => sum + item.quantity);
                                return Badge(
                                  isLabelVisible: cartCount > 0,
                                  label: Text(
                                    cartCount > 9 ? '9+' : cartCount.toString(),
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: AppTheme.accentColor,
                                  textColor: Colors.white,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.shopping_cart_outlined,
                                      size: responsive.iconSize(20),
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      context.go('/cart');
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: _pageController,
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

                                  final heroTags = List.generate(imageList.length, (i) {
                                    return i == 0
                                        ? (widget.heroTagPrefix != null
                                            ? '${widget.heroTagPrefix}_product_image_${product.id}'
                                            : 'product_image_${product.id}')
                                        : 'gallery_${product.id}_$i';
                                  });

                                  return GestureDetector(
                                    onTap: () => FullscreenImageViewer.open(
                                      context,
                                      imageUrls: imageList,
                                      initialIndex: index,
                                      heroTags: heroTags,
                                    ),
                                    child: Hero(
                                      tag: currentHeroTag,
                                      child: Image.network(
                                        imageList[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: AppTheme.borderColor.withValues(alpha: 0.2),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.04),
                                          child: Center(
                                            child: Icon(
                                              Icons.checkroom_rounded,
                                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                              size: responsive.iconSize(80),
                                            ),
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
                                  bottom: responsive.spacing(AppTheme.spaceXL),
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      imageList.length,
                                      (index) => Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: responsive.spacing(4),
                                        ),
                                        width: _activeImageIndex == index
                                            ? responsive.spacing(18)
                                            : responsive.spacing(8),
                                        height: responsive.spacing(8),
                                        decoration: BoxDecoration(
                                          color: _activeImageIndex == index
                                              ? AppTheme.primaryColor
                                              : Colors.white.withValues(
                                                  alpha: 0.5,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Floating Actions (Heart, Share, WhatsApp) Column on the right
                              Positioned(
                                right: responsive.spacing(16),
                                bottom: responsive.spacing(imageList.length > 1 ? 48 : 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildFloatingCircleButton(
                                      icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: isFav ? Colors.red : AppTheme.textPrimaryColor,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        ref.read(wishlistProvider.notifier).toggleWishlist(product);
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isFav
                                                  ? 'Removed from wishlist'
                                                  : 'Added to wishlist',
                                            ),
                                            duration: const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppTheme.primaryColor,
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: responsive.spacing(12)),
                                    _buildFloatingCircleButton(
                                      icon: Remix.share_forward_line,
                                      onTap: () {
                                        _openShareEarnBottomSheet(product);
                                      },
                                    ),
                                    SizedBox(height: responsive.spacing(12)),
                                    _buildFloatingCircleButton(
                                      icon: Remix.whatsapp_line,
                                      color: const Color(0xFF25D366),
                                      onTap: () {
                                        _openShareEarnBottomSheet(product);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: responsive.spacing(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Information Section
                        Padding(
                          padding: EdgeInsets.all(
                            responsive.spacing(AppTheme.spaceXL),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tag & Title
                              Text(
                                product.subcategory.toUpperCase(),
                                style: TextStyle(
                                  fontSize: responsive.fontSize11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceS),
                              ),
                              Text(
                                product.title,
                                style: TextStyle(
                                  fontSize: responsive.fontSize20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceM),
                              ),

                              // Ratings & Price Wrap
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: responsive.spacing(AppTheme.spaceM),
                                spacing: responsive.spacing(AppTheme.spaceM),
                                children: [
                                  // Prices
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        currency.formatPrice(_selectedVariantPrice ?? product.price),
                                        style: TextStyle(
                                          fontSize: responsive.fontSize20,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (product.originalPrice >
                                          product.price) ...[
                                        SizedBox(
                                          width: responsive.spacing(
                                            AppTheme.spaceM,
                                          ),
                                        ),
                                        Text(
                                          currency.formatPrice(product.originalPrice),
                                          style: TextStyle(
                                            fontSize: responsive.fontSize14,
                                            color: AppTheme.textLightColor,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                      if (product.taxPercent > 0 || product.taxType.isNotEmpty) ...[
                                        SizedBox(width: responsive.spacing(8)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: responsive.spacing(8),
                                            vertical: responsive.spacing(3),
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBg,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: AppColors.primaryBorder,
                                            ),
                                          ),
                                          child: Text(
                                            product.taxPercent > 0
                                                ? 'GST @ ${product.taxPercent.toStringAsFixed(0)}% (${product.taxType.toUpperCase() == 'INCLUSIVE' ? 'Inclusive' : '+ GST extra'})'
                                                : 'GST (${product.taxType})',
                                            style: TextStyle(
                                              fontSize: responsive.fontSize11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Rating summary
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsive.spacing(12),
                                      vertical: responsive.spacing(6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusM,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: AppTheme.accentColor,
                                          size: responsive.iconSize(18),
                                        ),
                                        SizedBox(width: responsive.spacing(4)),
                                        Text(
                                          product.rating.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryColor,
                                            fontSize: responsive.fontSize14,
                                          ),
                                        ),
                                        SizedBox(width: responsive.spacing(4)),
                                        Text(
                                          '(${product.reviewCount} ${l10n.reviews})',
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: responsive.fontSize11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceXL),
                              ),



                              // Description
                              Text(
                                l10n.description,
                                style: TextStyle(
                                  fontSize: responsive.fontSize16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceS),
                              ),
                              Text(
                                product.description,
                                style: responsive.bodyMedium.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                  height: 1.6,
                                ),
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceXL),
                              ),

                              // Size Selection
                              if (product.sizes.isNotEmpty) ...[
                                Text(
                                  l10n.selectSize,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceM),
                                ),
                                Wrap(
                                  spacing: responsive.spacing(AppTheme.spaceS),
                                  runSpacing: responsive.spacing(AppTheme.spaceS),
                                  children: product.sizes.map((sz) {
                                    final isSelected = _selectedSize == sz;
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _selectedSize = sz;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: responsive.spacing(45),
                                        height: responsive.spacing(45),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusM,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : AppTheme.borderColor,
                                            width: isSelected ? 2 : 1.5,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : AppTheme.softShadow,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          sz,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppTheme.textPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: responsive.fontSize14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceXL),
                                ),
                              ],

                              // Color Selection
                              if (product.colors.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.selectColor,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    if (_selectedColor != null)
                                      Text(
                                        _selectedColor!,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceM),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: product.colors.map((colorName) {
                                      final isSelected = _selectedColor == colorName;
                                      final colorVal = _parseColor(colorName);
                                      final isLightColor = colorVal.computeLuminance() > 0.6;
                                      return GestureDetector(
                                        onTap: () => _selectColor(colorName, product, imageList),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          margin: EdgeInsets.only(right: responsive.spacing(AppTheme.spaceS)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(
                                              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: colorVal,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isLightColor ? Colors.grey.shade400 : Colors.transparent,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: isSelected
                                                    ? Icon(
                                                        Icons.check,
                                                        size: 11,
                                                        color: isLightColor ? Colors.black : Colors.white,
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                colorName,
                                                style: TextStyle(
                                                  fontSize: responsive.fontSize13,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceXL),
                                ),
                              ],

                              // Reviews list
                              if (product.reviews.isNotEmpty) ...[
                                const Divider(),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceXL),
                                ),
                                Text(
                                  '${l10n.customerReviews} (${product.reviews.length})',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceL),
                                ),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: product.reviews.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                        height: responsive.spacing(
                                          AppTheme.spaceL,
                                        ),
                                      ),
                                  itemBuilder: (context, index) {
                                    final rev = product.reviews[index];
                                    return Container(
                                      padding: EdgeInsets.all(
                                        responsive.spacing(AppTheme.spaceL),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusM,
                                        ),
                                        border: Border.all(
                                          color: AppTheme.borderColor,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: responsive.iconSize(
                                                      18,
                                                    ),
                                                    backgroundImage:
                                                        rev.userAvatarUrl !=
                                                            null
                                                        ? NetworkImage(
                                                            rev.userAvatarUrl!,
                                                          )
                                                        : null,
                                                    onBackgroundImageError:
                                                        rev.userAvatarUrl != null
                                                            ? (exception,
                                                                    stackTrace) {}
                                                            : null,
                                                    child: Icon(
                                                      Icons.person,
                                                      size: responsive
                                                          .iconSize(18),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: responsive.spacing(
                                                      AppTheme.spaceM,
                                                    ),
                                                  ),
                                                  Text(
                                                    rev.userName,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          responsive.fontSize14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                rev.date,
                                                style: TextStyle(
                                                  color:
                                                      AppTheme.textLightColor,
                                                  fontSize:
                                                      responsive.fontSize11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: responsive.spacing(
                                              AppTheme.spaceS,
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                Icons.star_rounded,
                                                color: i < rev.rating.toInt()
                                                    ? AppTheme.accentColor
                                                    : AppTheme.borderColor,
                                                size: responsive.iconSize(16),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: responsive.spacing(
                                              AppTheme.spaceS,
                                            ),
                                          ),
                                          Text(
                                            rev.comment,
                                            style: TextStyle(
                                              color:
                                                  AppTheme.textSecondaryColor,
                                              height: 1.4,
                                              fontSize: responsive.fontSize14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceXL),
                                ),
                              ],

                              // Similar Products
                              const Divider(),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceXL),
                              ),
                              Text(
                                l10n.youMayAlsoLike,
                                style: TextStyle(
                                  fontSize: responsive.fontSize16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceL),
                              ),
                              SizedBox(
                                height: responsive.spacing(290),
                                child: similarProductsAsync.when(
                                  data: (products) {
                                    final filtered = products
                                        .where((p) => p.id != product.id)
                                        .toList();
                                    if (filtered.isEmpty) {
                                      return Center(
                                        child: Text(
                                          l10n.noRecommendations,
                                          style: TextStyle(
                                            fontSize: responsive.fontSize14,
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final p = filtered[index];
                                        return Container(
                                          width: responsive.spacing(175),
                                          margin: EdgeInsets.only(
                                            right: responsive.spacing(
                                              AppTheme.spaceL,
                                            ),
                                          ),
                                          child: ProductCard(
                                            product: p,
                                            heroTagPrefix: 'similar',
                                            onTap: () {
                                              context.pushReplacement(
                                                '/product/${p.id}?heroTagPrefix=similar',
                                              );
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
                                      width: responsive.spacing(175),
                                      margin: EdgeInsets.only(
                                        right: responsive.spacing(
                                          AppTheme.spaceL,
                                        ),
                                      ),
                                      child: const ProductCardSkeleton(),
                                    ),
                                  ),
                                  error: (err, stack) => Center(
                                    child: Text(
                                      '${l10n.error}: $err',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            '${l10n.error}: $err',
            style: TextStyle(fontSize: responsive.fontSize14),
          ),
        ),
      ),
      bottomNavigationBar: productAsync.when(
        data: (product) {
          if (product == null) return const SizedBox.shrink();
          return Container(
            padding: EdgeInsets.only(
              left: responsive.spacing(AppTheme.spaceXL),
              right: responsive.spacing(AppTheme.spaceXL),
              top: responsive.spacing(AppTheme.spaceL),
              bottom: responsive.spacing(AppTheme.spaceL) + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: const Border(
                top: BorderSide(color: AppTheme.borderColor),
              ),
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
                      side: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusM,
                        ),
                      ),
                    ),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      child: _isAddingToCart
                          ? SizedBox(
                              width: responsive.spacing(20),
                              height: responsive.spacing(20),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor,
                                    ),
                              ),
                            )
                          : (_showCartSuccess
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        size: responsive.iconSize(18),
                                        color: AppTheme.primaryColor,
                                      ),
                                      SizedBox(
                                        width: responsive.spacing(6),
                                      ),
                                      Text(
                                        l10n.added,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                          fontSize:
                                              responsive.fontSize14,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    l10n.addToCart,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: responsive.fontSize14,
                                    ),
                                  )),
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(AppTheme.spaceL)),
                // Buy Now (Solid)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      ref
                          .read(cartProvider.notifier)
                          .addToCart(
                            product,
                            size: _selectedSize,
                            color: _selectedColor,
                          );
                      // Go straight to checkout screen!
                      safeNavigate(context, '/checkout');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusM,
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.buyNow,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.fontSize14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Container(
          padding: EdgeInsets.only(
            left: responsive.spacing(AppTheme.spaceXL),
            right: responsive.spacing(AppTheme.spaceXL),
            top: responsive.spacing(AppTheme.spaceL),
            bottom: responsive.spacing(AppTheme.spaceL) + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
              ),
              SizedBox(width: responsive.spacing(AppTheme.spaceL)),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
              ),
            ],
          ),
        ),
        error: (err, stack) => Container(
          padding: EdgeInsets.only(
            left: responsive.spacing(AppTheme.spaceXL),
            right: responsive.spacing(AppTheme.spaceXL),
            top: responsive.spacing(AppTheme.spaceL),
            bottom: responsive.spacing(AppTheme.spaceL) + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(productDetailProvider(widget.productId)),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
