import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hopscotch/models/banner_model.dart';

/// District-app / Google-Play-style hero banner.
///
/// The widget fills its given [height] completely — the caller should make
/// that height include the top status-bar padding so the image bleeds edge
/// to edge behind the status bar.
///
/// Overlay stack (top → bottom):
///   ① Full-bleed image carousel   (viewportFraction = 1.0)
///   ② Top scrim gradient          (darkens behind status bar + header)
///   ③ Location row + avatar       (at the very top, overlaid on image)
///   ④ Search bar                  (below location row, overlaid on image)
///   ⑤ Bottom scrim + title + subtitle + Explore pill
///   ⑥ Animated dot indicators
class DistrictHeroHeader extends StatefulWidget {
  final double height;
  final List<BannerModel> banners;
  final Widget topRow;        // location icon + text + avatar
  final Widget? searchBar;   // search field row
  final void Function(BannerModel) onExplore;
  final bool isLoading;

  const DistrictHeroHeader({
    super.key,
    required this.height,
    required this.banners,
    required this.topRow,
    this.searchBar,
    required this.onExplore,
    this.isLoading = false,
  });

  @override
  State<DistrictHeroHeader> createState() => _DistrictHeroHeaderState();
}

class _DistrictHeroHeaderState extends State<DistrictHeroHeader> {
  late final PageController _controller;
  Timer? _autoPlay;
  int _current = 0;
  bool _userTouching = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(); // viewportFraction: 1.0 — full width
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlay?.cancel();
    if (widget.banners.length < 2) return;
    _autoPlay = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_userTouching || !_controller.hasClients) return;
      final next = (_current + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant DistrictHeroHeader old) {
    super.didUpdateWidget(old);
    if (old.banners.length != widget.banners.length) _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    // Top of the search bar (location row height ≈ 52 px)
    final double searchTop = topPadding + 56;
    // Cards start below search bar with a small gap
    final double headerHeight =
        widget.searchBar != null ? topPadding + 116 : topPadding + 62;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // white status-bar icons over image
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: widget.isLoading
            ? _buildShimmer()
            : widget.banners.isEmpty
                ? const SizedBox.shrink()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // ① Full-bleed image carousel — fills entire height
                      Listener(
                        onPointerDown: (_) => _userTouching = true,
                        onPointerUp: (_) => _userTouching = false,
                        onPointerCancel: (_) => _userTouching = false,
                        child: PageView.builder(
                          controller: _controller,
                          onPageChanged: (i) =>
                              setState(() => _current = i),
                          itemCount: widget.banners.length,
                          itemBuilder: (_, i) =>
                              _buildCard(widget.banners[i], headerHeight),
                        ),
                      ),

                      // ② Top scrim — darkens the area behind status bar & header
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: headerHeight + 20,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.black.withValues(alpha: 0.20),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ③ Location row + avatar (overlaid on image)
                      Positioned(
                        top: topPadding + 8,
                        left: 20,
                        right: 20,
                        child: widget.topRow,
                      ),

                      // ④ Search bar (overlaid on image, below location)
                      if (widget.searchBar != null)
                        Positioned(
                          top: searchTop,
                          left: 20,
                          right: 20,
                          child: widget.searchBar!,
                        ),

                      // ⑥ Dot indicators — bottom center
                      if (widget.banners.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.banners.length,
                              (i) {
                                final active = i == _current;
                                return AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: active ? 22 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.45),
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  // ── Single banner card ────────────────────────────────────────────────────
  Widget _buildCard(BannerModel banner, double headerHeight) {
    return GestureDetector(
      onTap: () => widget.onExplore(banner),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed cached image
          CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => _buildShimmer(),
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFF1A1A2E),
              child: const Icon(Icons.image_not_supported,
                  color: Colors.white38, size: 40),
            ),
          ),

          // ⑤ Bottom scrim + title + subtitle + Explore pill
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: widget.height * 0.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.50),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.50, 1.0],
                ),
              ),
            ),
          ),

          // Content row: title/subtitle + Explore button
          Positioned(
            left: 18,
            right: 18,
            bottom: 28, // above dot indicators
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      if (banner.subtitle != null &&
                          banner.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          banner.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Explore pill (Google Play / District style)
                GestureDetector(
                  onTap: () => widget.onExplore(banner),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.60),
                        width: 1.2,
                      ),
                    ),
                    child: const Text(
                      'Explore',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer skeleton ──────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A3E),
      highlightColor: const Color(0xFF3E3E58),
      child: Container(
        width: double.infinity,
        height: widget.height,
        color: const Color(0xFF2A2A3E),
      ),
    );
  }
}
