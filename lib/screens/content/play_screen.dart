import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/content_post_model.dart';
import 'package:hopscotch/repositories/content_repository.dart';
import 'package:hopscotch/widgets/comments_bottom_sheet.dart';
import 'package:hopscotch/theme/app_theme.dart';


class PlayScreen extends ConsumerStatefulWidget {
  final List<ContentPostModel>? initialFeed;
  final int initialIndex;

  const PlayScreen({
    super.key,
    this.initialFeed,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  late PageController _pageController;
  List<ContentPostModel> _posts = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isMuted = true;
  final Map<int, VideoPlayerController> _controllers = {};
  final Set<int> _viewedIds = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    if (widget.initialFeed != null && widget.initialFeed!.isNotEmpty) {
      _posts = List.from(widget.initialFeed!);
      _isLoading = false;
      _initControllerForIndex(_currentIndex);
      _markViewed(_currentIndex);
    } else {
      _fetchFeed();
    }
  }

  Future<void> _fetchFeed() async {
    final repo = ref.read(contentRepositoryProvider);
    final items = await repo.getPlayFeed(page: 1, limit: 20);
    if (mounted) {
      setState(() {
        _posts = items;
        _isLoading = false;
      });
      if (_posts.isNotEmpty) {
        _initControllerForIndex(_currentIndex);
        _markViewed(_currentIndex);
      }
    }
  }

  void _markViewed(int index) {
    if (index >= 0 && index < _posts.length) {
      final post = _posts[index];
      if (!_viewedIds.contains(post.id)) {
        _viewedIds.add(post.id);
        ref.read(contentRepositoryProvider).incrementView(post.id);
      }
    }
  }

  void _initControllerForIndex(int index) {
    if (index < 0 || index >= _posts.length) return;
    if (_controllers.containsKey(index)) return;

    final post = _posts[index];
    if (post.mediaUrls.isEmpty) return;

    final rawUrl = post.mediaUrls.first;
    final resolvedUrl = AppUrls.resolveUrl(rawUrl);

    final controller = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
    _controllers[index] = controller;

    controller.setLooping(true);
    controller.setVolume(_isMuted ? 0.0 : 1.0);

    controller.initialize().then((_) {
      if (mounted && _currentIndex == index) {
        setState(() {});
        controller.play();
      }
    }).catchError((err) {
      debugPrint('Error initializing video at index $index: $err');
    });

    // Preload adjacent video controllers (index - 1 & index + 1)
    _preloadAdjacent(index);

    // Dispose far away controllers to keep memory lightweight
    _disposeFarControllers(index);
  }

  void _preloadAdjacent(int index) {
    final nextIndex = index + 1;
    if (nextIndex < _posts.length && !_controllers.containsKey(nextIndex)) {
      final rawUrl = _posts[nextIndex].mediaUrls.first;
      final resolvedUrl = AppUrls.resolveUrl(rawUrl);
      final c = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
      _controllers[nextIndex] = c;
      c.setLooping(true);
      c.setVolume(_isMuted ? 0.0 : 1.0);
      c.initialize().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _disposeFarControllers(int currentIndex) {
    final keys = List<int>.from(_controllers.keys);
    for (final k in keys) {
      if ((k - currentIndex).abs() > 1) {
        _controllers[k]?.pause();
        _controllers[k]?.dispose();
        _controllers.remove(k);
      }
    }
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });

    // Pause previous video
    _controllers.forEach((idx, ctrl) {
      if (idx == index) {
        ctrl.setVolume(_isMuted ? 0.0 : 1.0);
        ctrl.play();
      } else {
        ctrl.pause();
      }
    });

    _initControllerForIndex(index);
    _markViewed(index);
  }

  void _toggleMute() {
    HapticFeedback.lightImpact();
    setState(() {
      _isMuted = !_isMuted;
      _controllers.forEach((_, ctrl) {
        ctrl.setVolume(_isMuted ? 0.0 : 1.0);
      });
    });
  }

  Future<void> _toggleLike(int index) async {
    HapticFeedback.mediumImpact();
    final post = _posts[index];
    final repo = ref.read(contentRepositoryProvider);

    // Optimistic state update
    final newIsLiked = !post.isLiked;
    final newLikeCount = newIsLiked ? post.likeCount + 1 : (post.likeCount - 1).clamp(0, 999999);

    setState(() {
      _posts[index] = post.copyWith(isLiked: newIsLiked, likeCount: newLikeCount);
    });

    final res = await repo.toggleLike(post.id);
    if (res != null && mounted) {
      setState(() {
        _posts[index] = post.copyWith(isLiked: res.isLiked, likeCount: res.likeCount);
      });
    }
  }

  void _sharePost(ContentPostModel post) {
    HapticFeedback.lightImpact();
    final text = 'Check out ${post.title ?? "this video"} on FCI Seller!\n${AppUrls.resolveUrl(post.mediaUrls.firstOrNull)}';
    Share.share(text);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controllers.forEach((_, ctrl) => ctrl.dispose());
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Play', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_outline, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'No videos available yet',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back soon for new shoppable videos',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical snap PageView feed
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return _buildVideoCard(context, index, _posts[index]);
            },
          ),

          // Top Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      _controllers[_currentIndex]?.pause();
                      context.pop();
                    },
                  ),

                  // Header Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accentColor, Colors.purple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'PLAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mute/Unmute Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _toggleMute,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, int index, ContentPostModel post) {
    final controller = _controllers[index];
    final isInitialized = controller != null && controller.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video View / Thumbnail Preview
        GestureDetector(
          onTap: () {
            if (controller != null && controller.value.isInitialized) {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
              setState(() {});
            }
          },
          child: isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                )
              : (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: AppUrls.resolveUrl(post.thumbnailUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: AppTheme.accentColor),
                      ),
                      errorWidget: (context, url, err) => const Center(
                        child: Icon(Icons.movie_rounded, color: Colors.white38, size: 64),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: AppTheme.accentColor),
                    )),
        ),

        // Pause Overlay Icon
        if (isInitialized && !controller.value.isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
            ),
          ),

        // Gradient overlay for text readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Right Vertical Action Rail (Likes, Share)
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Like Button
              GestureDetector(
                onTap: () => _toggleLike(index),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: post.isLiked ? Colors.redAccent : Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${post.likeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Comment Button
              GestureDetector(
                onTap: () {
                  CommentsBottomSheet.show(
                    context,
                    contentPostId: post.id,
                    onCommentAdded: (newCount) {
                      setState(() {
                        _posts[index] = post.copyWith(commentCount: newCount);
                      });
                    },
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${post.commentCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Share Button
              GestureDetector(
                onTap: () => _sharePost(post),

                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom Left Caption & Sliding Product Card
        Positioned(
          left: 16,
          right: 76,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title & Caption
              if (post.title != null && post.title!.isNotEmpty)
                Text(
                  post.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

              if (post.caption != null && post.caption!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _ExpandableCaption(caption: post.caption!),
              ],

              const SizedBox(height: 12),

              // Tagged Shoppable Product Card
              if (post.taggedProducts.isNotEmpty)
                _buildProductCard(context, post.taggedProducts.first),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, TaggedProductModel product) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: AppUrls.resolveUrl(product.thumbnailUrl),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.shopping_bag, size: 20, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name & Price
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
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Shop Now Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _controllers[_currentIndex]?.pause();
              context.push('/product/${product.id}');
            },
            child: const Text(
              'Shop Now',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableCaption extends StatefulWidget {
  final String caption;
  const _ExpandableCaption({required this.caption});

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Text(
        widget.caption,
        maxLines: _isExpanded ? 10 : 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          height: 1.3,
        ),
      ),
    );
  }
}
