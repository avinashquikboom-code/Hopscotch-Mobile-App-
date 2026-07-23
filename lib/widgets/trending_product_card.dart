import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final currency = ref.watch(currencyProvider);
    final heroTag = heroTagPrefix != null
        ? '${heroTagPrefix}_product_image_${product.id}'
        : 'product_image_${product.id}';

    final resolvedImageUrl = AppUrls.resolveUrl(product.imageUrl);
    final displayTitle = product.title.isNotEmpty ? product.title : 'Product';

    final offerText = product.discountPercentage > 0
        ? 'Min. ${product.discountPercentage.toInt()}% Off'
        : 'From ${currency.formatPrice(product.price)}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Image Section with Floating Brand/Title Pill ────────────
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

                  // White Brand/Product Pill at the bottom of the image area
                  Positioned(
                    bottom: 0,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 6,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Brand logo icon
                          const Icon(
                            Icons.adjust_rounded,
                            size: 13,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            displayTitle.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Soft Teal Offer Banner Footer ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFCCFBF1), // Soft teal tint
                    Color(0xFFE0F2FE), // Soft cyan tint
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Text(
                offerText,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
          size: 44,
        ),
      ),
    );
  }
}
