import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopscotch/models/banner_model.dart';

class DistrictHeroHeader extends StatefulWidget {
  final double height;
  final List<BannerModel> banners;
  final Widget topRow;                       // location + avatar (white variant)
  final Widget? searchBar;                   // search bar overlay
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
    _controller = PageController(viewportFraction: 0.80);
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
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
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
    final hasBanners = widget.banners.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. AMBIENT BACKDROP — blurred active banner, crossfades on change
            if (hasBanners)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Image.network(
                  widget.banners[_current].imageUrl,
                  key: ValueKey(_current),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF14141E)),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  ),
                ),
              ),
            // Blur + darken the backdrop so cards pop (District's dark stage)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),

            // 2. SPOTLIGHT CARD CAROUSEL
            Positioned(
              left: 0,
              right: 0,
              top: widget.searchBar != null ? topPadding + 116 : topPadding + 62,
              bottom: 30,
              child: widget.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white54))
                  : !hasBanners
                      ? const Center(
                          child: Text('No Promotions',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 16)),
                        )
                      : Listener(
                          onPointerDown: (_) => _userTouching = true,
                          onPointerUp: (_) => _userTouching = false,
                          onPointerCancel: (_) => _userTouching = false,
                          child: PageView.builder(
                            controller: _controller,
                            onPageChanged: (i) =>
                                setState(() => _current = i),
                            itemCount: widget.banners.length,
                            itemBuilder: (context, index) =>
                                _buildCard(index),
                          ),
                        ),
            ),

            // 3. TOP SCRIM + HEADER ROW
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: widget.searchBar != null ? topPadding + 140 : topPadding + 80,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: topPadding + 8,
              left: 20,
              right: 20,
              child: widget.topRow,
            ),
            if (widget.searchBar != null)
              Positioned(
                top: topPadding + 58,
                left: 20,
                right: 20,
                child: widget.searchBar!,
              ),

            // 4. DOTS — bottom center, inside hero
            if (widget.banners.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.banners.length, (i) {
                    final isActive = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── SPOTLIGHT CARD — scales & fades with page offset (District effect)
  Widget _buildCard(int index) {
    final banner = widget.banners[index];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double page = _current.toDouble();
        if (_controller.hasClients && _controller.position.haveDimensions) {
          page = _controller.page ?? page;
        }
        final delta = (page - index).abs().clamp(0.0, 1.0);
        final scale = 1.0 - (delta * 0.10);   // 1.0 center → 0.90 sides
        final opacity = 1.0 - (delta * 0.35); // slight fade at sides

        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity.clamp(0.55, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTap: () => widget.onExplore(banner),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  banner.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF1A1A2E)),
                ),
                // Bottom scrim for text legibility
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 130,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
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
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.3,
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
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          'Explore',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
