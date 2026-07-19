import 'package:flutter/material.dart';
import 'package:hopscotch/widgets/animated_search_hint.dart';

// ─────────────────────────────────────────────────────────────
// 1. TEAL SEARCH BAR (pinned) — Flipkart jaisa colored header
// ─────────────────────────────────────────────────────────────

class BrandSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final double horizontalPadding;
  final VoidCallback onSearchTap;
  final VoidCallback onCameraTap;
  final List<String> searchHints;
  final String placeholderText;

  BrandSearchBarDelegate({
    required this.topPadding,
    required this.horizontalPadding,
    required this.onSearchTap,
    required this.onCameraTap,
    required this.searchHints,
    required this.placeholderText,
  });

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: primary, // TEAL header — Flipkart ke blue ki jagah
      padding: EdgeInsets.fromLTRB(horizontalPadding, 6, horizontalPadding, 8),
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onSearchTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedSearchHint(
                          prefix: 'Search for ',
                          hints: searchHints,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              padding: const EdgeInsets.only(right: 12),
              constraints: const BoxConstraints(),
              onPressed: onCameraTap,
              icon: Icon(Icons.camera_alt_outlined, color: primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant BrandSearchBarDelegate old) =>
      old.topPadding != topPadding ||
      old.horizontalPadding != horizontalPadding ||
      old.searchHints != searchHints ||
      old.placeholderText != placeholderText;
}

// ─────────────────────────────────────────────────────────────
// 2. COLLAPSING CATEGORY STRIP — teal bg, white text, video-style
// ─────────────────────────────────────────────────────────────

class CollapsingCategoryStripDelegate extends SliverPersistentHeaderDelegate {
  final List<dynamic> categories; // needs .name + .iconUrl
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double horizontalPadding;

  CollapsingCategoryStripDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onChanged,
    this.horizontalPadding = 16,
  });

  static const double _expandedHeight = 98;
  static const double _collapsedHeight = 44;

  @override
  double get maxExtent => _expandedHeight;
  @override
  double get minExtent => _collapsedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final primary = Theme.of(context).colorScheme.primary;

    final t = (shrinkOffset / (_expandedHeight - _collapsedHeight))
        .clamp(0.0, 1.0);

    final imageSize = 54.0 * (1 - t);
    final imageOpacity = (1 - t * 1.6).clamp(0.0, 1.0);
    final gap = 5.0 * (1 - t);

    return Container(
      // Same teal as search bar → continuous Flipkart-style header
      decoration: BoxDecoration(
        color: primary,
        boxShadow: t > 0.9
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: 14 + 10 * t),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          final String label = i == 0 ? 'All' : categories[i - 1].name;
          final String? iconUrl = i == 0 ? null : categories[i - 1].iconUrl;

          return GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // CATEGORY IMAGE — Flipkart jaise seedha image, no circle box
                if (imageSize > 1)
                  Opacity(
                    opacity: imageOpacity,
                    child: SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(imageSize * 0.24),
                        child: iconUrl != null && iconUrl.isNotEmpty
                            ? Image.network(
                                iconUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.category_outlined,
                                  size: imageSize * 0.5,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                i == 0
                                    ? Icons.grid_view_rounded
                                    : Icons.category_outlined,
                                size: imageSize * 0.5,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                SizedBox(height: gap),

                // LABEL — white, hamesha visible
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12 + 1.5 * t,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),

                // WHITE UNDERLINE — active tab, collapsed state (video jaisa)
                SizedBox(height: 3 * t),
                Opacity(
                  opacity: t,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 2.5,
                    width: selected ? 24 : 0,
                    decoration: BoxDecoration(
                      color: Colors.white,
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

  @override
  bool shouldRebuild(covariant CollapsingCategoryStripDelegate old) =>
      old.selectedIndex != selectedIndex ||
      old.categories != categories ||
      old.horizontalPadding != horizontalPadding;
}
