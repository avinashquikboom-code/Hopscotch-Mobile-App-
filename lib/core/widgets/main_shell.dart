import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';
import 'package:hopscotch/features/cart_wishlist/repositories/cart_wishlist_repository.dart';
import '../theme/app_theme.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/') return 0;
    if (location.startsWith('/categories')) return 1;
    if (location.startsWith('/wishlist')) return 2;
    if (location.startsWith('/cart')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/categories');
        break;
      case 2:
        context.go('/wishlist');
        break;
      case 3:
        context.go('/cart');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final cart = ref.watch(cartProvider);
    final wishlist = ref.watch(wishlistProvider);

    final cartCount = cart.fold(0, (sum, item) => sum + item.quantity);
    final wishlistCount = wishlist.length;

    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true, // Content flows beautifully behind translucent navigation bar!
      body: child,
      bottomNavigationBar: Container(
        height: 60 + bottomPadding, // Standard, native platform height incorporating home indicators
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          border: const Border(
            top: BorderSide(
              color: AppTheme.borderColor,
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimaryColor.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Stack(
                children: [
                  // 1. Fluid Sliding Active Background Pill
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.fastOutSlowIn,
                    alignment: Alignment(
                      -1.0 + (selectedIndex * 0.5), // Maps 0..4 seamlessly to -1.0..1.0
                      0.0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.2, // exactly 1/5th navigation cell width
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08), // Soft luxury Teal tint
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Nav Items Icons Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          context: context,
                          icon: isAndroid ? Remix.home_line : Icons.home_outlined,
                          activeIcon: isAndroid ? Remix.home_fill : Icons.home_rounded,
                          isSelected: selectedIndex == 0,
                          onTap: () => _onItemTapped(0, context),
                        ),
                        _buildNavItem(
                          context: context,
                          icon: isAndroid ? Remix.apps_line : Icons.grid_view_outlined,
                          activeIcon: isAndroid ? Remix.apps_fill : Icons.grid_view_rounded,
                          isSelected: selectedIndex == 1,
                          onTap: () => _onItemTapped(1, context),
                        ),
                        _buildNavItem(
                          context: context,
                          icon: isAndroid ? Remix.heart_line : Icons.favorite_border_rounded,
                          activeIcon: isAndroid ? Remix.heart_fill : Icons.favorite_rounded,
                          isSelected: selectedIndex == 2,
                          badgeCount: wishlistCount,
                          onTap: () => _onItemTapped(2, context),
                        ),
                        _buildNavItem(
                          context: context,
                          icon: isAndroid ? Remix.shopping_bag_line : Icons.shopping_bag_outlined,
                          activeIcon: isAndroid ? Remix.shopping_bag_fill : Icons.shopping_bag_rounded,
                          isSelected: selectedIndex == 3,
                          badgeCount: cartCount,
                          onTap: () => _onItemTapped(3, context),
                        ),
                        _buildNavItem(
                          context: context,
                          icon: isAndroid ? Remix.user_line : Icons.person_outline_rounded,
                          activeIcon: isAndroid ? Remix.user_fill : Icons.person_rounded,
                          isSelected: selectedIndex == 4,
                          onTap: () => _onItemTapped(4, context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 60, // Matches standard row height
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Individual container pad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: Colors.transparent, // Solid click targeting
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                  size: 22,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 0,
                  right: 4,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(badgeCount),
                    duration: const Duration(milliseconds: 500),
                    tween: Tween<double>(begin: 0.3, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
