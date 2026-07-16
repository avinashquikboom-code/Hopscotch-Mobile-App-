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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: colorScheme.surface,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
          items: List.generate(5, (i) {
            final count = badges[i];
            Widget iconWidget = Icon(
              selectedIndex == i ? icons[i][1] : icons[i][0],
              size: 22,
            );

            if (count > 0) {
              iconWidget = Badge(
                label: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: AppTheme.accentColor,
                textColor: Colors.white,
                child: iconWidget,
              );
            }

            return BottomNavigationBarItem(
              icon: iconWidget,
              label: _labels[i],
            );
          }),
        ),
      ),
    );
  }
}
