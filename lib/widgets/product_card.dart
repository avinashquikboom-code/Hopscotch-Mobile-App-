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
                              placeholder: (_, __) => _buildPlaceholder(context),
                              errorWidget: (_, __, ___) => _buildPlaceholder(context),
                            )
                          : _buildPlaceholder(context),
                    ),
                  ),

                  // Floating Wishlist / Heart Button (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
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
                        size: 16,
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
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.primaryColor,
                            size: 13,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating > 0
                                ? product.rating.toStringAsFixed(2)
                                : '5.00',
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '|',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.reviewCount > 0 ? product.reviewCount : 3}',
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Product Details (Title & Price Row) ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price & Discount Row
                  Row(
                    children: [
                      // Sale Price in Teal Accent
                      Text(
                        currency.formatPrice(product.price),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (product.originalPrice > product.price) ...[
                        const SizedBox(width: 5),
                        Text(
                          currency.formatPrice(product.originalPrice),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.40),
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                      if (product.discountPercentage > 0) ...[
                        const SizedBox(width: 5),
                        Text(
                          '${product.discountPercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: AppTheme.primaryColor.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
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

