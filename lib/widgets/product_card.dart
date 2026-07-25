import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/widgets/animated_heart_button.dart';

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 135;
        final floatOffset = isCompact ? 5.0 : 8.0;
        final heartPadding = isCompact ? 4.5 : 6.0;
        final heartIconSize = isCompact ? 13.0 : 16.0;

        final ratingPadHorizontal = isCompact ? 4.0 : 6.0;
        final ratingPadVertical = isCompact ? 2.0 : 3.0;
        final ratingStarSize = isCompact ? 10.0 : 13.0;
        final ratingFontSize = isCompact ? 9.5 : 11.0;

        final detailPadding = isCompact
            ? const EdgeInsets.fromLTRB(6, 6, 6, 8)
            : const EdgeInsets.fromLTRB(10, 8, 10, 10);
        final titleFontSize = isCompact ? 12.0 : 14.0;
        final priceFontSize = isCompact ? 13.0 : 15.0;
        final origPriceFontSize = isCompact ? 10.0 : 11.5;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Section ───────────────────────────────────────────
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag: heroTag,
                          child: resolvedImageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: resolvedImageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  memCacheWidth: 400,
                                  placeholder: (_, __) => _buildPlaceholder(context),
                                  errorWidget: (_, __, ___) => _buildPlaceholder(context),
                                )
                              : _buildPlaceholder(context),
                        ),
                      ),

                      // Floating Wishlist / Heart Button (Top Right)
                      Positioned(
                        top: floatOffset,
                        right: floatOffset,
                        child: Container(
                          padding: EdgeInsets.all(heartPadding),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: AnimatedHeartButton(
                            isFav: isFav,
                            size: heartIconSize,
                            baseColor: AppTheme.primaryColor,
                            onTap: () {
                              ref.read(wishlistProvider.notifier).toggleWishlist(product);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFav ? 'Removed from wishlist' : 'Added to wishlist',
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

                      // Floating Rating Badge (Bottom Right of Image)
                      Positioned(
                        bottom: floatOffset,
                        right: floatOffset,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ratingPadHorizontal,
                            vertical: ratingPadVertical,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: AppTheme.primaryColor,
                                size: ratingStarSize,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating > 0
                                    ? product.rating.toStringAsFixed(1)
                                    : '5.0',
                                style: TextStyle(
                                  color: const Color(0xFF1F2937),
                                  fontWeight: FontWeight.w700,
                                  fontSize: ratingFontSize,
                                ),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(width: 3),
                                Text(
                                  '|',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: ratingFontSize - 1,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${product.reviewCount > 0 ? product.reviewCount : 3}',
                                  style: TextStyle(
                                    color: const Color(0xFF1F2937),
                                    fontWeight: FontWeight.w600,
                                    fontSize: ratingFontSize,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Product Details (Title & Price Row) ───────────────────
                Padding(
                  padding: detailPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Title — Single line, clean dark font
                      Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: titleFontSize,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Price & Discount Row
                      Row(
                        children: [
                          // Sale Price in Teal Accent
                          Text(
                            currency.formatPrice(product.price),
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: priceFontSize,
                            ),
                          ),
                          if (product.originalPrice > product.price) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                currency.formatPrice(product.originalPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.40),
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: origPriceFontSize,
                                ),
                              ),
                            ),
                          ],
                          if (product.discountPercentage > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${product.discountPercentage.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w700,
                                fontSize: origPriceFontSize,
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
      },
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

