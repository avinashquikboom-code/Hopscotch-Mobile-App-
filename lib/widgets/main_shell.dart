import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';


/// FCI SELLER — Modernized Bottom Navigation Shell.
///
/// Layout:
/// - Position 1: HOME (/home)
/// - Position 2: TRENDS (/posts)
/// - Position 3: SHOP (/categories)
/// - Position 4: FAVOURITES (/wishlist)
/// - Position 5: YOU (/profile)
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _routes = [
    '/home',
    '/posts',
    '/categories',
    '/wishlist',
    '/profile',
  ];

  static const _labels = ['HOME', 'TRENDS', 'SHOP', 'FAVOURITES', 'YOU'];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/' || location.startsWith('/home')) return 0;
    if (location.startsWith('/posts') || location.startsWith('/play')) return 1;
    if (location.startsWith('/categories')) return 2;
    if (location.startsWith('/wishlist')) return 3;
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
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final colorScheme = Theme.of(context).colorScheme;

    final icons = <List<IconData>>[
      [
        isAndroid ? Remix.home_line : Icons.home_outlined,
        isAndroid ? Remix.home_fill : Icons.home_rounded,
      ],
      [
        isAndroid ? Remix.compass_3_line : Icons.explore_outlined,
        isAndroid ? Remix.compass_3_fill : Icons.explore_rounded,
      ],
      [
        isAndroid ? Remix.apps_line : Icons.grid_view_outlined,
        isAndroid ? Remix.apps_fill : Icons.grid_view_rounded,
      ],
      [
        isAndroid ? Remix.heart_line : Icons.favorite_outline_rounded,
        isAndroid ? Remix.heart_fill : Icons.favorite_rounded,
      ],
      [
        isAndroid ? Remix.user_line : Icons.person_outline_rounded,
        isAndroid ? Remix.user_fill : Icons.person_rounded,
      ],
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomAppBar(
        color: colorScheme.surface,
        elevation: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildNavItem(context, 0, selectedIndex, icons, _labels[0], colorScheme)),
              Expanded(child: _buildNavItem(context, 1, selectedIndex, icons, _labels[1], colorScheme)),
              Expanded(child: _buildNavItem(context, 2, selectedIndex, icons, _labels[2], colorScheme)),
              Expanded(child: _buildNavItem(context, 3, selectedIndex, icons, _labels[3], colorScheme)),
              Expanded(child: _buildNavItem(context, 4, selectedIndex, icons, _labels[4], colorScheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    int selectedIndex,
    List<List<IconData>> icons,
    String label,
    ColorScheme colorScheme,
  ) {
    final isSelected = selectedIndex == index;
    final iconData = isSelected ? icons[index][1] : icons[index][0];

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 22,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
