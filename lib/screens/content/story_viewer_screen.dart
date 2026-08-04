import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/content_post_model.dart';
import 'package:hopscotch/repositories/content_repository.dart';
import 'package:hopscotch/theme/app_theme.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<ContentPostModel> stories;
  final int initialIndex;
  final Function(int storyId)? onStoryViewed;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.onStoryViewed,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(vsync: this);

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _loadCurrentStory();
  }

  void _loadCurrentStory() {
    _progressController.stop();
    _progressController.reset();

    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }

    if (_currentIndex < 0 || _currentIndex >= widget.stories.length) {
      context.pop();
      return;
    }

    final story = widget.stories[_currentIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onStoryViewed?.call(story.id);
      }
    });
    ref.read(contentRepositoryProvider).incrementView(story.id);

    if (story.mediaType == 'VIDEO' && story.mediaUrls.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isVideoLoading = true;
        });
      } else {
        _isVideoLoading = true;
      }

      final url = AppUrls.resolveUrl(story.mediaUrls.first);
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;

      controller.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
          });
          controller.play();
          final duration = controller.value.duration;
          _progressController.duration = duration.inMilliseconds > 0 ? duration : const Duration(seconds: 5);
          _progressController.forward();
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
          });
          _startImageTimer();
        }
      });
    } else {
      _startImageTimer();
    }
  }

  void _startImageTimer() {
    _progressController.duration = const Duration(seconds: 5);
    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex++;
      });
      _loadCurrentStory();
    } else {
      context.pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex--;
      });
      _loadCurrentStory();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty || _currentIndex >= widget.stories.length) {
      return const SizedBox.shrink();
    }

    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            context.pop();
          }
        },
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _progressController.stop(),
        onLongPressEnd: (_) => _progressController.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Media (Image or Video)
            if (story.mediaType == 'VIDEO' && _videoController != null && _videoController!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else if (story.mediaUrls.isNotEmpty)
              CachedNetworkImage(
                imageUrl: AppUrls.resolveUrl(story.mediaUrls.first),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentColor),
                ),
                errorWidget: (context, url, err) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              ),

            if (_isVideoLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              ),

            // Gradient Top & Bottom Overlays
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),

            // Top Header: Segmented Auto-Progress Bars + Close Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Segmented Progress Bar
                    Row(
                      children: List.generate(widget.stories.length, (idx) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white30,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: idx < _currentIndex
                                ? Container(color: Colors.white)
                                : (idx == _currentIndex
                                    ? AnimatedBuilder(
                                        animation: _progressController,
                                        builder: (context, child) {
                                          return FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: _progressController.value,
                                            child: Container(color: Colors.white),
                                          );
                                        },
                                      )
                                    : const SizedBox.shrink()),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 12),

                    // User Info Header
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.accentColor,
                          child: Icon(Icons.star_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.title ?? 'Exclusive Story',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '24h Expiry Content',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tagged Product Sticker at Bottom
            if (story.taggedProducts.isNotEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: 40,
                child: _buildStoryProductSticker(context, story.taggedProducts.first),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryProductSticker(BuildContext context, TaggedProductModel product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: AppUrls.resolveUrl(product.thumbnailUrl),
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorWidget: (context, url, err) => Container(
                color: Colors.grey.shade800,
                child: const Icon(Icons.shopping_bag, size: 18, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            onPressed: () {
              _progressController.stop();
              _videoController?.pause();
              context.push('/product/${product.id}');
            },
            icon: const Icon(Icons.shopping_cart_outlined, size: 14),
            label: const Text(
              'Shop Now',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
