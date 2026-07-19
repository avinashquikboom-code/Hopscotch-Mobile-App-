import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
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
  bool _isAddingToCart = false;
  bool _showCartSuccess = false;

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


  // Custom helper to parse hex colors to Flutter Color objects
  Color _parseColor(String hexCode) {
    try {
      final code = hexCode.replaceAll('#', '');
      return Color(int.parse('FF$code', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
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
                            child: IconButton(
                              icon: Icon(
                                Icons.shopping_cart_outlined,
                                size: responsive.iconSize(20),
                                color: AppTheme.textPrimaryColor,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.push('/cart');
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
                                        currency.formatPrice(product.price),
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
                                            decoration:
                                                TextDecoration.lineThrough,
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
                                Row(
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
                                        margin: EdgeInsets.only(
                                          right: responsive.spacing(
                                            AppTheme.spaceM,
                                          ),
                                        ),
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
                                Text(
                                  l10n.selectColor,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceM),
                                ),
                                Row(
                                  children: product.colors.map((hex) {
                                    final isSelected = _selectedColor == hex;
                                    final colorVal = _parseColor(hex);
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _selectedColor = hex;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: responsive.spacing(45),
                                        height: responsive.spacing(45),
                                        margin: EdgeInsets.only(
                                          right: responsive.spacing(
                                            AppTheme.spaceM,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorVal,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : Colors.white,
                                            width: isSelected ? 4 : 2,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: colorVal.withValues(
                                                      alpha: 0.5,
                                                    ),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
                      context.push('/checkout');
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
