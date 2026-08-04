import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/content_post_model.dart';
import 'package:hopscotch/repositories/content_repository.dart';
import 'package:hopscotch/widgets/comments_bottom_sheet.dart';

/// FLIPKART PLAY — Shoppable Short-Video & Community Feed.
///
/// Immersive full-screen vertical swipe reels feed with top category filter chips,
/// shoppable product overlay cards with bright yellow "BUY NOW" CTA buttons,
/// right action rail, and creator follow badges.
class PostsFeedScreen extends ConsumerStatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  ConsumerState<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends ConsumerState<PostsFeedScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _discAnimationController;

  List<ContentPostModel> _posts = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isMuted = false;
  String _selectedCategory = '🔥 Trending';

  final Map<int, VideoPlayerController> _videoControllers = {};
  final Set<int> _followedCreators = {};
  final Set<int> _viewedIds = {};

  final List<String> _categories = [
    '🔥 Trending',
    '⚡ Deals',
    '👗 Fashion',
    '✨ Beauty',
    '📱 Tech',
    '🏠 Home',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    final repo = ref.read(contentRepositoryProvider);
    List<ContentPostModel> playFeed = await repo.getPlayFeed(page: 1, limit: 15);
    List<ContentPostModel> postsFeed = await repo.getPostsFeed(page: 1, limit: 15);

    List<ContentPostModel> combined = [...playFeed, ...postsFeed];

    // If API returns empty, use rich Flipkart Play fallback items
    if (combined.isEmpty) {
      combined = _getFallbackFlipkartPlayItems();
    }

    if (mounted) {
      setState(() {
        _posts = combined;
        _isLoading = false;
      });

      if (_posts.isNotEmpty) {
        _initVideoController(_currentIndex);
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

  void _initVideoController(int index) {
    if (index < 0 || index >= _posts.length) return;
    if (_videoControllers.containsKey(index)) return;

    final post = _posts[index];
    if (post.mediaType != 'VIDEO' || post.mediaUrls.isEmpty) return;

    final rawUrl = post.mediaUrls.first;
    final resolvedUrl = AppUrls.resolveUrl(rawUrl);

    final controller = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
    _videoControllers[index] = controller;

    controller.setLooping(true);
    controller.setVolume(_isMuted ? 0.0 : 1.0);

    controller.initialize().then((_) {
      if (mounted && _currentIndex == index) {
        setState(() {});
        controller.play();
      }
    }).catchError((err) {
      debugPrint('Error initializing Flipkart Play video at index $index: $err');
    });

    _preloadAdjacentVideos(index);
    _disposeFarVideoControllers(index);
  }

  void _preloadAdjacentVideos(int index) {
    final nextIndex = index + 1;
    if (nextIndex < _posts.length && !_videoControllers.containsKey(nextIndex)) {
      final post = _posts[nextIndex];
      if (post.mediaType == 'VIDEO' && post.mediaUrls.isNotEmpty) {
        final rawUrl = post.mediaUrls.first;
        final resolvedUrl = AppUrls.resolveUrl(rawUrl);
        final c = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
        _videoControllers[nextIndex] = c;
        c.setLooping(true);
        c.setVolume(_isMuted ? 0.0 : 1.0);
        c.initialize().then((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  void _disposeFarVideoControllers(int currentIndex) {
    final keys = List<int>.from(_videoControllers.keys);
    for (final k in keys) {
      if ((k - currentIndex).abs() > 1) {
        _videoControllers[k]?.pause();
        _videoControllers[k]?.dispose();
        _videoControllers.remove(k);
      }
    }
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });

    _videoControllers.forEach((idx, ctrl) {
      if (idx == index) {
        ctrl.setVolume(_isMuted ? 0.0 : 1.0);
        ctrl.play();
      } else {
        ctrl.pause();
      }
    });

    _initVideoController(index);
    _markViewed(index);
  }

  void _toggleMute() {
    HapticFeedback.lightImpact();
    setState(() {
      _isMuted = !_isMuted;
      _videoControllers.forEach((_, ctrl) {
        ctrl.setVolume(_isMuted ? 0.0 : 1.0);
      });
    });
  }

  Future<void> _toggleLike(int index) async {
    HapticFeedback.mediumImpact();
    final post = _posts[index];
    final repo = ref.read(contentRepositoryProvider);

    final newIsLiked = !post.isLiked;
    final newLikeCount =
        newIsLiked ? post.likeCount + 1 : (post.likeCount - 1).clamp(0, 999999);

    setState(() {
      _posts[index] =
          post.copyWith(isLiked: newIsLiked, likeCount: newLikeCount);
    });

    final res = await repo.toggleLike(post.id);
    if (res != null && mounted) {
      setState(() {
        _posts[index] =
            post.copyWith(isLiked: res.isLiked, likeCount: res.likeCount);
      });
    }
  }

  void _toggleFollow(int postId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_followedCreators.contains(postId)) {
        _followedCreators.remove(postId);
      } else {
        _followedCreators.add(postId);
      }
    });
  }

  void _sharePost(ContentPostModel post) {
    HapticFeedback.lightImpact();
    final text =
        '🔥 Check out this on Flipkart Play!\n${post.title ?? post.caption ?? ""}\nShop now on FCI Seller!';
    Share.share(text);
  }

  @override
  void dispose() {
    _discAnimationController.dispose();
    _pageController.dispose();
    _videoControllers.forEach((_, ctrl) => ctrl.dispose());
    _videoControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9F00)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full-screen Vertical Swipe Feed
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return _buildFlipkartPlayCard(context, index, _posts[index]);
            },
          ),

          // 2. Flipkart Play Header Overlay (Title & Category Chips)
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      // Flipkart Play Logo Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2874F0), Color(0xFF00D2FF)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2874F0).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'PLAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Pulsing Live Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 6),
                            SizedBox(width: 4),
                            Text(
                              'TRENDING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Mute / Unmute Button
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        onPressed: _toggleMute,
                      ),
                      const SizedBox(width: 10),

                      // Search Button
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.push('/search');
                        },
                      ),
                    ],
                  ),
                ),

                // Top Category Filter Chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF9F00)
                                : Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF9F00)
                                  : Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipkartPlayCard(
      BuildContext context, int index, ContentPostModel post) {
    final controller = _videoControllers[index];
    final isVideo = post.mediaType == 'VIDEO';
    final isInitialized =
        isVideo && controller != null && controller.value.isInitialized;
    final isFollowing = _followedCreators.contains(post.id);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Media (Video / Image)
        GestureDetector(
          onTap: () {
            if (isInitialized) {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
              setState(() {});
            }
          },
          onDoubleTap: () => _toggleLike(index),
          child: isVideo
              ? (isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : _buildImageFallback(post.thumbnailUrl ?? (post.mediaUrls.isNotEmpty ? post.mediaUrls.first : '')))
              : _buildImageFallback(post.mediaUrls.isNotEmpty ? post.mediaUrls.first : ''),
        ),

        // Pause Overlay Icon
        if (isInitialized && !controller.value.isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 48),
            ),
          ),

        // Dark Gradients for Content Legibility
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.90),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Right Action Rail (Flipkart Play Style)
        Positioned(
          right: 14,
          bottom: 110,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Creator Avatar with + Follow Button
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF2874F0), Color(0xFFFF9F00)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade900,
                      backgroundImage: CachedNetworkImageProvider(
                        AppUrls.resolveUrl(post.uploadedBy),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    child: GestureDetector(
                      onTap: () => _toggleFollow(post.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? Colors.green.shade600
                              : const Color(0xFFFF9F00),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          isFollowing ? Icons.check : Icons.add,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Like Button
              GestureDetector(
                onTap: () => _toggleLike(index),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: post.isLiked
                            ? const Color(0xFFFF4757)
                            : Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${post.likeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${post.commentCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Share Button
              GestureDetector(
                onTap: () => _sharePost(post),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Spinning Vinyl Music Disc
              RotationTransition(
                turns: _discAnimationController,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87,
                    border: Border.all(color: Colors.amber, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Left Creator Info & Flipkart Shoppable Product Card
        Positioned(
          left: 14,
          right: 74,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Creator Handle & Verified Badge
              Row(
                children: [
                  Text(
                    '@${post.uploadedBy.isNotEmpty ? post.uploadedBy : "fci_seller"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Color(0xFF2874F0), size: 15),
                ],
              ),
              const SizedBox(height: 4),

              // Title / Caption
              if (post.caption != null && post.caption!.isNotEmpty)
                Text(
                  post.caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              const SizedBox(height: 8),

              // Hashtags
              const Text(
                '#FlipkartPlay #TrendingFashion #FCIDeals',
                style: TextStyle(
                  color: Color(0xFF00D2FF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Signature Flipkart Play Shoppable Product Card
              if (post.taggedProducts.isNotEmpty)
                _buildFlipkartProductCard(context, post.taggedProducts.first)
              else
                _buildDefaultFlipkartProductCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageFallback(String url) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white38, size: 64),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: AppUrls.resolveUrl(url),
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9F00)),
        ),
      ),
      errorWidget: (context, url, err) => Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white38, size: 50),
        ),
      ),
    );
  }

  /// Flipkart Play Shoppable Product Card (Bottom Banner)
  Widget _buildFlipkartProductCard(
      BuildContext context, TaggedProductModel product) {
    final discountPercent = product.basePrice > product.price
        ? (((product.basePrice - product.price) / product.basePrice) * 100)
            .round()
        : 50;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9F00), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: AppUrls.resolveUrl(product.thumbnailUrl),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (context, url, err) => Container(
                color: Colors.grey.shade800,
                child: const Icon(Icons.shopping_bag,
                    size: 22, color: Colors.amber),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Details Column
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
                    fontSize: 12.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Color(0xFFFF9F00),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₹${product.basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white54,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Bright Yellow Flipkart BUY NOW Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9F00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              _videoControllers[_currentIndex]?.pause();
              context.push('/product/${product.id}');
            },
            icon: const Icon(Icons.flash_on_rounded,
                size: 14, color: Colors.black),
            label: const Text(
              'BUY NOW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Default Shoppable Product Card fallback
  Widget _buildDefaultFlipkartProductCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9F00), width: 1.2),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=200',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FCI Designer Wear Edition',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '₹499',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Color(0xFFFF9F00),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '₹1,499',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white54,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '66% OFF',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9F00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              context.push('/categories');
            },
            icon: const Icon(Icons.flash_on_rounded,
                size: 14, color: Colors.black),
            label: const Text(
              'BUY NOW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fallback items for rich Flipkart Play experience if API feed is offline
  List<ContentPostModel> _getFallbackFlipkartPlayItems() {
    return [
      ContentPostModel(
        id: 101,
        type: 'PLAY',
        title: 'Trending Outfit of the Day 🔥',
        caption: 'Get 65% off on summer collection! Double tap if you love this style.',
        mediaUrls: [
          'https://assets.mixkit.co/videos/preview/mixkit-fashion-model-in-a-pink-suit-41443-large.mp4'
        ],
        mediaType: 'VIDEO',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800',
        uploadedBy: 'fci_stylehub',
        isActive: true,
        viewCount: 15400,
        likeCount: 2840,
        commentCount: 420,
        sortOrder: 1,
        createdAt: DateTime.now(),
        isLiked: false,
        taggedProducts: const [
          TaggedProductModel(
            id: 1,
            name: 'Designer Pink Suit Set',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            basePrice: 2499.0,
            price: 899.0,
          ),
        ],
      ),
      ContentPostModel(
        id: 102,
        type: 'PLAY',
        title: 'Unboxing Latest Footwear 👟',
        caption: 'Super comfortable sneakers for everyday wear! Limited stock available.',
        mediaUrls: [
          'https://assets.mixkit.co/videos/preview/mixkit-model-holding-a-pair-of-yellow-shoes-41441-large.mp4'
        ],
        mediaType: 'VIDEO',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
        uploadedBy: 'trend_sneakers',
        isActive: true,
        viewCount: 24100,
        likeCount: 5120,
        commentCount: 890,
        sortOrder: 2,
        createdAt: DateTime.now(),
        isLiked: true,
        taggedProducts: const [
          TaggedProductModel(
            id: 2,
            name: 'Vibrant Yellow Sports Shoes',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
            basePrice: 3999.0,
            price: 1299.0,
          ),
        ],
      ),
      ContentPostModel(
        id: 103,
        type: 'PLAY',
        title: 'Shopping Haul & Try-On ✨',
        caption: 'Best Flipkart deals for this season! Click Buy Now to claim discounts.',
        mediaUrls: [
          'https://assets.mixkit.co/videos/preview/mixkit-young-woman-with-shopping-bags-41551-large.mp4'
        ],
        mediaType: 'VIDEO',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800',
        uploadedBy: 'fci_glam',
        isActive: true,
        viewCount: 32000,
        likeCount: 8400,
        commentCount: 1250,
        sortOrder: 3,
        createdAt: DateTime.now(),
        isLiked: false,
        taggedProducts: const [
          TaggedProductModel(
            id: 3,
            name: 'Elegant Party Wear Outfit',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400',
            basePrice: 1999.0,
            price: 699.0,
          ),
        ],
      ),
    ];
  }
}
