import 'dart:io';
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
import 'package:hopscotch/screens/content/play_screen.dart';
import 'package:hopscotch/widgets/stories_strip.dart';
import 'package:hopscotch/widgets/comments_bottom_sheet.dart';
import 'package:hopscotch/theme/app_theme.dart';


class PostsFeedScreen extends ConsumerStatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  ConsumerState<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends ConsumerState<PostsFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ContentPostModel> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    final repo = ref.read(contentRepositoryProvider);
    final items = await repo.getPostsFeed(page: _currentPage, limit: 10);

    if (mounted) {
      setState(() {
        if (refresh) {
          _posts = items;
        } else {
          _posts.addAll(items);
        }
        _isLoading = false;
        _isLoadingMore = false;
        if (items.length < 10) {
          _hasMore = false;
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore) {
        setState(() {
          _isLoadingMore = true;
          _currentPage++;
        });
        _fetchPosts();
      }
    }
  }

  Future<void> _toggleLike(int index) async {
    HapticFeedback.mediumImpact();
    final post = _posts[index];
    final repo = ref.read(contentRepositoryProvider);

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
    final text =
        'Check out this post on FCI Seller!\n${post.caption ?? ""}\n${AppUrls.resolveUrl(post.mediaUrls.firstOrNull)}';
    Share.share(text);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'COMMUNITY FEED',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 16,
          ),
        ),
        centerTitle: Platform.isIOS ? true : false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchPosts(refresh: true),
              color: AppTheme.accentColor,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: 1 + (_posts.isEmpty ? 1 : _posts.length + (_isLoadingMore ? 1 : 0)),
                itemBuilder: (context, index) {
                  // Item 0: Stories & Play Avatar Strip at top of Community Feed
                  if (index == 0) {
                    return Container(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: const StoriesStrip(),
                    );
                  }

                  if (_posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No posts found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for inspiration & style posts',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final postIndex = index - 1;
                  if (postIndex == _posts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.accentColor),
                      ),
                    );
                  }
                  return _buildPostCard(context, postIndex, _posts[postIndex]);
                },
              ),
            ),
    );
  }

  Widget _buildPostCard(BuildContext context, int index, ContentPostModel post) {
    final isPlayType = post.type == 'PLAY';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isPlayType ? Colors.purple.shade600 : AppTheme.accentColor,
                  child: Icon(
                    isPlayType ? Icons.play_arrow_rounded : Icons.verified_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title ?? (isPlayType ? 'PLAY Video Edit' : 'FCI Style Edit'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        isPlayType ? 'Vertical Video Feed' : 'Official Admin Upload',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (isPlayType)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PlayScreen(
                            initialFeed: [post],
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade600, AppTheme.accentColor],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 2),
                          Text(
                            'FULLSCREEN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SHOPPABLE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Image Carousel or Video Player
          if (post.mediaUrls.isNotEmpty)
            _PostCarousel(
              mediaUrls: post.mediaUrls,
              mediaType: post.mediaType,
              post: post,
            ),

          // Action Rail (Like, Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: post.isLiked ? Colors.redAccent : Colors.black87,
                    size: 26,
                  ),
                  onPressed: () => _toggleLike(index),
                ),
                Text(
                  '${post.likeCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 14),

                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black87, size: 23),
                  onPressed: () {
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
                ),
                Text(
                  '${post.commentCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 14),

                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.black87, size: 24),
                  onPressed: () => _sharePost(post),
                ),

              ],
            ),
          ),

          // Caption
          if (post.caption != null && post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                post.caption!,
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),
            ),

          // Tagged Products Strip
          if (post.taggedProducts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'TAGGED PRODUCTS (${post.taggedProducts.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: post.taggedProducts.length,
                itemBuilder: (context, pIdx) {
                  final p = post.taggedProducts[pIdx];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/product/${p.id}');
                    },
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: AppUrls.resolveUrl(p.thumbnailUrl),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, err) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.shopping_bag, size: 20, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${p.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PostCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final String mediaType;
  final ContentPostModel post;

  const _PostCarousel({
    required this.mediaUrls,
    required this.mediaType,
    required this.post,
  });

  @override
  State<_PostCarousel> createState() => _PostCarouselState();
}

class _PostCarouselState extends State<_PostCarousel> {
  int _current = 0;

  bool _isVideo(String url) {
    if (widget.mediaType == 'VIDEO') return true;
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.contains('/video') ||
        lower.contains('content/play');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 380,
          child: PageView.builder(
            itemCount: widget.mediaUrls.length,
            onPageChanged: (index) {
              setState(() {
                _current = index;
              });
            },
            itemBuilder: (context, index) {
              final mediaUrl = widget.mediaUrls[index];
              if (_isVideo(mediaUrl)) {
                return _FeedVideoPlayer(
                  url: mediaUrl,
                  onOpenFullscreen: widget.post.type == 'PLAY'
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PlayScreen(
                                initialFeed: [widget.post],
                                initialIndex: 0,
                              ),
                            ),
                          );
                        }
                      : null,
                );
              }

              return CachedNetworkImage(
                imageUrl: AppUrls.resolveUrl(mediaUrl),
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, err) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),

        // Carousel Dot Indicators
        if (widget.mediaUrls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.mediaUrls.length, (idx) {
              return Container(
                width: _current == idx ? 8 : 6,
                height: _current == idx ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == idx ? AppTheme.accentColor : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _FeedVideoPlayer extends StatefulWidget {
  final String url;
  final VoidCallback? onOpenFullscreen;

  const _FeedVideoPlayer({
    required this.url,
    this.onOpenFullscreen,
  });

  @override
  State<_FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<_FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final resolvedUrl = AppUrls.resolveUrl(widget.url);
    _controller = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));

    _controller.setLooping(true);
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }).catchError((err) {
      debugPrint('Error initializing feed video: $err');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 380,
        color: Colors.black87,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_camera_back_outlined, size: 48, color: Colors.white54),
              SizedBox(height: 8),
              Text(
                'Video Preview Unavailable',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 380,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: Container(
        height: 380,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
            if (!_controller.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
              ),

            if (widget.onOpenFullscreen != null)
              Positioned(
                right: 12,
                top: 12,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: widget.onOpenFullscreen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
