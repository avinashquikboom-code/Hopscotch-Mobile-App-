import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;
  final List<String>? heroTags;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix = 'product_image',
    this.heroTags,
  });

  /// Kahin se bhi kholne ke liye:
  /// FullscreenImageViewer.open(context, imageUrls: urls, initialIndex: i);
  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String heroTagPrefix = 'product_image',
    List<String>? heroTags,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => FullscreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          heroTagPrefix: heroTagPrefix,
          heroTags: heroTags,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dismissProgress = (_dragOffset.abs() / 300).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 1 - dismissProgress * 0.5),
      body: GestureDetector(
        // Swipe-down to dismiss
        onVerticalDragUpdate: (d) =>
            setState(() => _dragOffset += d.delta.dy),
        onVerticalDragEnd: (d) {
          if (_dragOffset.abs() > 120 ||
              (d.primaryVelocity ?? 0).abs() > 700) {
            Navigator.of(context).pop();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Stack(
            children: [
              PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                builder: (context, index) => PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(widget.imageUrls[index]),
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: widget.heroTags != null && widget.heroTags!.length > index
                        ? widget.heroTags![index]
                        : '${widget.heroTagPrefix}_$index',
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white38, size: 48),
                  ),
                ),
                loadingBuilder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              ),

              // Close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),

              // Counter: 2 / 5
              if (widget.imageUrls.length > 1)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.imageUrls.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
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
