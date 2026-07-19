// lib/widgets/flipkart_category_strip.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single SliverPersistentHeader that morphs from circular category images
/// into pinned text-tabs as the user scrolls — exactly like Flipkart's home.
///
/// Expanded state  → circular images + label below each
/// Collapsed state → text labels + underline indicator, pinned at top
class FlipkartCategoryStripDelegate extends SliverPersistentHeaderDelegate {
  final List<dynamic> categories; // each has .name + .imageUrl
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double horizontalPadding;
  final double topPadding;

  FlipkartCategoryStripDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onChanged,
    required this.horizontalPadding,
    required this.topPadding,
  });

  // Collapsed: 44 text-tab height + status-bar safe area
  double get _collapsed => 44.0 + topPadding;
  // Expanded: 60 image + 6 gap + 16 label + 12 top margin  ≈ 104
  double get _expanded => 104.0 > _collapsed + 12.0 ? 104.0 : _collapsed + 12.0;

  @override
  double get maxExtent => _expanded;
  @override
  double get minExtent => _collapsed;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;

    // t: 0 = fully expanded (images visible)  →  1 = fully collapsed (text tabs)
    final t = (shrinkOffset / (_expanded - _collapsed)).clamp(0.0, 1.0);

    final double imageSize = 60.0 * (1.0 - t);
    final double imageOpacity = (1.0 - t * 1.6).clamp(0.0, 1.0);
    final double gap = 6.0 * (1.0 - t);
    // Safe-area top padding only kicks in when pinned
    final double padTop = topPadding * t;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: t > 0.9 ? colorScheme.outline : Colors.transparent,
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(top: padTop),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: categories.length + 1, // +1 for "All" tab
        separatorBuilder: (_, __) => SizedBox(width: 14.0 + 10.0 * t),
        itemBuilder: (context, i) {
          final bool selected = i == selectedIndex;
          final String label = i == 0 ? 'All' : categories[i - 1].name as String;
          final String? imageUrl = i == 0 ? null : categories[i - 1].imageUrl as String?;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(i);
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── CIRCULAR IMAGE — morphs to nothing when collapsed
                if (imageSize > 1.0)
                  Opacity(
                    opacity: imageOpacity,
                    child: Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.primary.withValues(alpha: 0.15),
                          width: selected ? 2.0 : 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _iconFallback(
                                  icon: Icons.category_outlined,
                                  size: imageSize,
                                  colorScheme: colorScheme,
                                ),
                              )
                            : _iconFallback(
                                icon: Icons.grid_view_rounded,
                                size: imageSize,
                                colorScheme: colorScheme,
                                filled: true,
                              ),
                      ),
                    ),
                  ),

                SizedBox(height: gap),

                // ── LABEL — always visible, font grows when collapsed
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.0 + 2.0 * t, // 12→14 as it collapses
                    letterSpacing: 0.3,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),

                // ── UNDERLINE — only visible in text-tab (collapsed) state
                SizedBox(height: 3.0 * t),
                Opacity(
                  opacity: t,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 2.5,
                    width: selected ? 24.0 : 0.0,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _iconFallback({
    required IconData icon,
    required double size,
    required ColorScheme colorScheme,
    bool filled = false,
  }) {
    return Container(
      color: filled
          ? colorScheme.primary.withValues(alpha: 0.08)
          : colorScheme.primary.withValues(alpha: 0.05),
      child: Icon(
        icon,
        color: colorScheme.primary.withValues(alpha: filled ? 1.0 : 0.5),
        size: size * 0.4,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant FlipkartCategoryStripDelegate old) =>
      old.selectedIndex != selectedIndex ||
      old.categories != categories ||
      old.horizontalPadding != horizontalPadding ||
      old.topPadding != topPadding;
}
