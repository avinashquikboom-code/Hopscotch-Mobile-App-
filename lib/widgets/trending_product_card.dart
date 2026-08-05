import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_colors.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';

class TrendingProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final String? heroTagPrefix;

  const TrendingProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final currency = ref.watch(currencyProvider);

    final heroTag = heroTagPrefix != null
        ? '${heroTagPrefix}_product_image_${product.id}'
        : 'product_image_${product.id}';

    final resolvedImageUrl = AppUrls.resolveUrl(product.imageUrl);

    // Formatted price (e.g. "Under ₹499" or "From ₹399")
    final priceOverlayText = product.price > 0
        ? 'Under ${currency.formatPrice(product.price)}'
        : (product.discountPercentage > 0
            ? 'Up To ${product.discountPercentage.toInt()}% Off'
            : 'Special Offer');

    // Sub-tagline overlay (e.g., "Up To 80% Off" or "Crested In Luxury")
    final taglineText = product.discountPercentage > 0
        ? 'Up To ${product.discountPercentage.toInt()}% Off'
        : (product.subcategory.isNotEmpty
            ? product.subcategory
            : 'Crested In Luxury');

    // Brand Name for the bottom footer bar
    final brandName = product.title.isNotEmpty
        ? product.title.toUpperCase()
        : 'POWERLOOK';

    final cardBgColor = isDark ? colorScheme.surface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final footerTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Top Image Area with Gradient & White Text Overlay ────────
            Expanded(
              child: Stack(
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

                  // Dark Bottom Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.35, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Overlay Price & Tagline Text at Bottom of Image
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          priceOverlayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.0,
                            letterSpacing: -0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          taglineText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontWeight: FontWeight.w500,
                            fontSize: 11.0,
                            letterSpacing: 0.1,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Brand Logo / Typography Footer Bar ────────────────
            Container(
              height: 42,
              width: double.infinity,
              color: cardBgColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Icon logo box
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      border: Border.all(color: footerTextColor, width: 1.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'P',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: footerTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      brandName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: footerTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.0,
                        letterSpacing: 1.0,
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
  }

  Widget _buildPlaceholder(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          color: primary,
          size: 44,
        ),
      ),
    );
  }
}
