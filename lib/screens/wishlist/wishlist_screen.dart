import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/constants/app_colors.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/widgets/product_card.dart';
import 'package:hopscotch/utils/navigation_utils.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        centerTitle: false,
        title: Text(
          l10n.myWishlist,
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (wishlist.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => WishlistBody._moveAllToBag(context, ref),
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  size: responsive.iconSize(18),
                  color: AppTheme.primaryColor,
                ),
                label: Text(
                  l10n.addToCart,
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: const WishlistBody(embedded: false),
    );
  }
}

class WishlistBody extends ConsumerWidget {
  const WishlistBody({super.key, this.embedded = false});

  final bool embedded;

  static void _moveAllToBag(BuildContext context, WidgetRef ref) {
    final wishlist = ref.read(wishlistProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    final cartNotifier = ref.read(cartProvider.notifier);

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
            Text('All saved items moved to your bag'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (wishlist.isEmpty) {
      return _buildEmptyState(
        context,
        responsive: responsive,
        l10n: l10n,
        colorScheme: colorScheme,
        isDark: isDark,
      );
    }

    final bottomPad = embedded ? 120.0 : 24.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (!embedded)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.spacing(AppTheme.spaceXL),
                responsive.spacing(AppTheme.spaceM),
                responsive.spacing(AppTheme.spaceXL),
                responsive.spacing(AppTheme.spaceL),
              ),
              child: _WishlistHeroStrip(
                count: wishlist.length,
                isDark: isDark,
              ),
            ),
          ),
        if (embedded)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.spacing(AppTheme.spaceXL),
                responsive.spacing(AppTheme.spaceM),
                responsive.spacing(AppTheme.spaceXL),
                responsive.spacing(AppTheme.spaceM),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${wishlist.length} saved item${wishlist.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: responsive.fontSize13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _moveAllToBag(context, ref),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: Text(
                      l10n.addToCart,
                      style: TextStyle(
                        fontSize: responsive.fontSize12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            responsive.spacing(AppTheme.spaceXL),
            0,
            responsive.spacing(AppTheme.spaceXL),
            bottomPad,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 600
                  ? 2
                  : (MediaQuery.of(context).size.width < 900 ? 3 : 4),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.58,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = wishlist[index];
                return ProductCard(
                  product: product,
                  heroTagPrefix: embedded ? 'profile-wishlist' : 'wishlist',
                  onTap: () => safeNavigate(
                    context,
                    '/product/${product.id}?heroTagPrefix=${embedded ? 'profile-wishlist' : 'wishlist'}',
                  ),
                );
              },
              childCount: wishlist.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required ResponsiveText responsive,
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXXL)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(
                  alpha: isDark ? 0.15 : 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 52,
                color: AppTheme.primaryColor.withValues(alpha: 0.75),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            Text(
              l10n.wishlistEmpty,
              style: TextStyle(
                fontSize: responsive.fontSize18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            Text(
              l10n.wishlistEmptyDesc,
              style: TextStyle(
                fontSize: responsive.fontSize13,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
            SizedBox(
              width: double.infinity,
              height: responsive.spacing(48),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/categories');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                child: Text(
                  l10n.shopCouture,
                  style: TextStyle(
                    fontSize: responsive.fontSize14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistHeroStrip extends StatelessWidget {
  const _WishlistHeroStrip({
    required this.count,
    required this.isDark,
  });

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkPrimaryBg, AppColors.darkSurface]
              : [AppColors.primary, AppColors.primaryHover],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(responsive.spacing(12)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: responsive.iconSize(26),
            ),
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count saved item${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: responsive.fontSize16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pieces you love, ready when you are',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: responsive.fontSize11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
