import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/theme/app_theme.dart';

/// AURA COUTURE — floating "atelier dock" navigation.
///
/// Design intent:
/// - Detached pill dock floating above the bottom edge (content scrolls
///   behind it via extendBody) — lighter, more premium than an edge-to-edge bar.
/// - The active tab expands into a solid teal capsule with an uppercase,
///   letterspaced label — like a woven garment tag. Only one label is ever
///   visible, so the dock stays quiet and editorial.
/// - Inactive tabs are pure line icons in secondary ink. No tints, no noise.
/// - Selection haptic on every tab change.
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _routes = [
    '/home',
    '/categories',
    '/wishlist',
    '/cart',
    '/profile',
  ];
  static const _labels = ['HOME', 'SHOP', 'SAVED', 'BAG', 'YOU'];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/' || location.startsWith('/home')) return 0;
    if (location.startsWith('/categories')) return 1;
    if (location.startsWith('/wishlist')) return 2;
    if (location.startsWith('/cart')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    context.go(_routes[index]);
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

    final icons = <List<IconData>>[
      [
        isAndroid ? Remix.home_line : Icons.home_outlined,
        isAndroid ? Remix.home_fill : Icons.home_rounded,
      ],
      [
        isAndroid ? Remix.apps_line : Icons.grid_view_outlined,
        isAndroid ? Remix.apps_fill : Icons.grid_view_rounded,
      ],
      [
        isAndroid ? Remix.heart_line : Icons.favorite_border_rounded,
        isAndroid ? Remix.heart_fill : Icons.favorite_rounded,
      ],
      [
        isAndroid ? Remix.shopping_bag_line : Icons.shopping_bag_outlined,
        isAndroid ? Remix.shopping_bag_fill : Icons.shopping_bag_rounded,
      ],
      [
        isAndroid ? Remix.user_line : Icons.person_outline_rounded,
        isAndroid ? Remix.user_fill : Icons.person_rounded,
      ],
    ];

    final badges = <int>[0, 0, wishlistCount, cartCount, 0];

    return Scaffold(
      extendBody: true, // content flows behind the floating dock
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: bottomPadding > 0 ? 6 : 14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.10),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimaryColor.withValues(alpha: 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(5, (i) {
                    return _DockItem(
                      icon: icons[i][0],
                      activeIcon: icons[i][1],
                      label: _labels[i],
                      isSelected: selectedIndex == i,
                      badgeCount: badges[i],
                      onTap: () => _onItemTapped(i, context),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Active tab takes more room; inactive tabs share the rest evenly.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.fastOutSlowIn,
      width: isSelected ? 112 : 52,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.fastOutSlowIn,
                height: 42,
                padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      size: 21,
                    ),
                    // Label appears only inside the active capsule —
                    // uppercase, letterspaced, garment-tag editorial.
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.fastOutSlowIn,
                      child: isSelected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -3,
                  right: isSelected ? null : -2,
                  left: isSelected ? 24 : null,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(badgeCount),
                    duration: const Duration(milliseconds: 500),
                    tween: Tween<double>(begin: 0.3, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
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
