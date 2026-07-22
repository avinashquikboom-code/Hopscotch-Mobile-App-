import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/widgets/animated_heart_button.dart';
import 'package:hopscotch/widgets/share_earn_bottom_sheet.dart';
import 'package:remixicon/remixicon.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final String? heroTagPrefix;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final currency = ref.watch(currencyProvider);
    final isFav = wishlist.any((p) => p.id == product.id);
    final heroTag = heroTagPrefix != null
        ? '${heroTagPrefix}_product_image_${product.id}'
        : 'product_image_${product.id}';

    // Always resolve the image URL so relative paths load correctly
    final resolvedImageUrl = AppUrls.resolveUrl(product.imageUrl);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Image — Expanded fills available grid cell height ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radiusL),
                        topRight: Radius.circular(AppTheme.radiusL),
                      ),
                      child: Hero(
                        tag: '${heroTag}_image',
                        child: resolvedImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: resolvedImageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (_, __) =>
                                    _buildPlaceholder(context),
                                errorWidget: (_, __, ___) =>
                                    _buildPlaceholder(context),
                              )
                            : _buildPlaceholder(context),
                      ),
                    ),
                  ),

                  // Discount badge
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: AppTheme.spaceM,
                      left: AppTheme.spaceM,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXS),
                        ),
                        child: Text(
                          '${product.discountPercentage.toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                  // New arrival badge
                  if (product.isNewArrival && product.discountPercentage == 0)
                    Positioned(
                      top: AppTheme.spaceM,
                      left: AppTheme.spaceM,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXS),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist button (top-right)
                  Positioned(
                    top: AppTheme.spaceS,
                    right: AppTheme.spaceS,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedHeartButton(
                        isFav: isFav,
                        size: 18,
                        baseColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        onTap: () {
                          ref
                              .read(wishlistProvider.notifier)
                              .toggleWishlist(product);
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
                    ),
                  ),

                  // Share button (bottom-right)
                  Positioned(
                    bottom: AppTheme.spaceS,
                    right: AppTheme.spaceS,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              ShareEarnBottomSheet(product: product),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Remix.share_forward_line,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),  // end Expanded

            // ── Product Info — fixed layout so price is never clipped ──────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subcategory tag
                  Text(
                    product.subcategory.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Product title
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Rating row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.accentColor, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '(${product.reviewCount})',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Price row — always fully visible, never clipped
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          currency.formatPrice(product.price),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.originalPrice > product.price) ...[
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            currency.formatPrice(product.originalPrice),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.38),
                              decoration: TextDecoration.lineThrough,
                              fontSize: 10.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clean placeholder — no "AURA" text, just a subtle hanger icon
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          color: AppTheme.primaryColor.withValues(alpha: 0.22),
          size: 40,
        ),
      ),
    );
  }

}

