import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/theme/app_theme.dart';

/// Hopscotch-style vertical product feed — large portrait cards,
/// full-width vertical scroll with quick Add-to-Bag action.
class VerticalProductFeed extends ConsumerWidget {
  final List<ProductModel> products;
  final ScrollController? scrollController;
  final int loadingExtra;
  final void Function(ProductModel product) onTap;

  const VerticalProductFeed({
    super.key,
    required this.products,
    required this.onTap,
    this.scrollController,
    this.loadingExtra = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: products.length + loadingExtra,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        if (index >= products.length) {
          return Container(
            height: 480,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }
        return _VerticalProductCard(
          product: products[index],
          currency: currency,
          onTap: () => onTap(products[index]),
        );
      },
    );
  }
}

class _VerticalProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final AppCurrency currency;
  final VoidCallback onTap;

  const _VerticalProductCard({
    required this.product,
    required this.currency,
    required this.onTap,
  });

  @override
  ConsumerState<_VerticalProductCard> createState() => _VerticalProductCardState();
}

class _VerticalProductCardState extends ConsumerState<_VerticalProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currency = widget.currency;
    final price = currency.formatPrice(product.price);
    final mrp = currency.formatPrice(product.originalPrice);
    final isFav = ref.watch(
      wishlistProvider.select((list) => list.any((p) => p.id == product.id)),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey, size: 48),
                    ),
                  ),
                ),
                if (product.discountPercentage > 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        '${product.discountPercentage.round()}% OFF',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                if (product.isNewArrival)
                  Positioned(
                    top: product.discountPercentage > 0 ? 48 : 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: ScaleTransition(
                    scale: _heartScale,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _heartController.forward(from: 0);
                        ref.read(wishlistProvider.notifier).toggleWishlist(product);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.red : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.white.withValues(alpha: 0.9), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.subcategory.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5, color: AppTheme.primaryColor, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, height: 1.3, color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(price, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                      if (product.originalPrice > product.price) ...[
                        const SizedBox(width: 8),
                        Text(mrp, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                      ],
                      const Spacer(),
                      if (product.rating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF388E3C), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 3),
                              Text(product.rating.toStringAsFixed(1),
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(cartProvider.notifier).addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Added to bag!'),
                          backgroundColor: AppTheme.primaryColor,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ));
                      },
                      child: const Text('ADD TO BAG',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
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
}
