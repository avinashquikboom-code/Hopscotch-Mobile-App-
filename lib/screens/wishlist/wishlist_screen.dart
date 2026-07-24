import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/constants/app_colors.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/widgets/product_card.dart';
import 'package:hopscotch/utils/navigation_utils.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    final cartNotifier = ref.read(cartProvider.notifier);
    final responsive = context.responsive;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'WISHLIST',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (wishlist.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  for (final item in wishlist) {
                    cartNotifier.addToCart(item);
                  }
                  wishlistNotifier.clearWishlist();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text('All wishlist items moved to Bag ✨'),
                        ],
                      ),
                      backgroundColor: AppTheme.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                label: const Text(
                  'MOVE ALL TO BAG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
      body: wishlist.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lottie Animated Visual
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Lottie.asset(
                          'assets/lottie/success.json',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.favorite_rounded,
                              size: 72,
                              color: AppTheme.primaryColor.withValues(alpha: 0.7),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'YOUR WISHLIST IS EMPTY',
                      style: TextStyle(
                        fontSize: responsive.fontSize18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap the heart icon on your favorite luxury pieces to save them here for quick access.',
                      style: TextStyle(
                        fontSize: responsive.fontSize13,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Explore button CTA
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.go('/categories');
                      },
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: const Text(
                        'EXPLORE COLLECTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header item count badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_rounded, size: 14, color: Colors.pinkAccent),
                            const SizedBox(width: 6),
                            Text(
                              '${wishlist.length} ${wishlist.length == 1 ? 'SAVED ITEM' : 'SAVED ITEMS'}',
                              style: TextStyle(
                                fontSize: responsive.fontSize10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Grid View of Wishlist items
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width < 600
                          ? 2
                          : (MediaQuery.of(context).size.width < 900 ? 3 : 5),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: wishlist.length,
                    itemBuilder: (context, index) {
                      final product = wishlist[index];
                      return ProductCard(
                        product: product,
                        heroTagPrefix: 'wishlist',
                        onTap: () => safeNavigate(
                          context,
                          '/product/${product.id}?heroTagPrefix=wishlist',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
