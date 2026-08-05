import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/content_post_model.dart';
import 'package:hopscotch/repositories/content_repository.dart';
import 'package:hopscotch/screens/content/play_screen.dart';

/// FLIPKART PLAY — 2-Column Discovery Grid Screen.
///
/// Immersive dark-themed video discovery hub featuring:
/// - Top LIVE stream horizontal carousel
/// - "Videos for you" section header
/// - 2-Column video card discovery grid with Indian number formatting (3.5L, 43.3K)
/// - Tap video card -> opens full-screen vertical swipe viewer (PlayScreen) starting at tapped video index
class PostsFeedScreen extends ConsumerStatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  ConsumerState<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends ConsumerState<PostsFeedScreen> {
  List<ContentPostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    final repo = ref.read(contentRepositoryProvider);
    final playItems = await repo.getPlayFeed(page: 1, limit: 20);
    final postItems = await repo.getPostsFeed(page: 1, limit: 20);

    List<ContentPostModel> combined = [...playItems, ...postItems];

    if (combined.isEmpty) {
      combined = _getFallbackGridItems();
    }

    if (mounted) {
      setState(() {
        _posts = combined;
        _isLoading = false;
      });
    }
  }

  /// Format view and like counts using Indian Lakh (L) / Thousand (K) notation
  String _formatIndianNumber(int count) {
    if (count >= 100000) {
      final lakh = count / 100000;
      return '${lakh.toStringAsFixed(lakh % 1 == 0 ? 0 : 1)}L';
    } else if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }

  void _openFullScreenViewer(int index) {
    HapticFeedback.lightImpact();
    if (index >= 0 && index < _posts.length) {
      final post = _posts[index];
      // Increment real-time view counter via API & state update
      ref.read(contentRepositoryProvider).incrementView(post.id);
      setState(() {
        _posts[index] = post.copyWith(viewCount: post.viewCount + 1);
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayScreen(
          initialFeed: _posts,
          initialIndex: index,
        ),
      ),
    );
  }

  void _toggleLike(int index) async {
    HapticFeedback.lightImpact();
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0F172A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Row(
            children: [
              Icon(Icons.explore_rounded, color: Color(0xFFFF9F00), size: 24),
              SizedBox(width: 8),
              Text(
                'Trends',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

        ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9F00)),
            )
          : RefreshIndicator(
              onRefresh: _fetchFeed,
              color: const Color(0xFFFF9F00),
              child: CustomScrollView(
                slivers: [
                  // 1. LIVE Stream Horizontal Section
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4757),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle,
                                        color: Colors.white, size: 6),
                                    SizedBox(width: 4),
                                    Text(
                                      'LIVE NOW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Watch live shopping & deals',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 155,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _getLiveStreams().length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final live = _getLiveStreams()[index];
                              return _buildLiveCard(context, live, index);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // 2. Section Header: "Videos for you"
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Videos for you',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  // 3. 2-Column Discovery Video Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildGridVideoCard(
                              context, index, _posts[index]);
                        },
                        childCount: _posts.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  /// Live Stream Horizontal Card
  Widget _buildLiveCard(
      BuildContext context, Map<String, String> live, int index) {
    return GestureDetector(
      onTap: () => _openFullScreenViewer(index % _posts.length),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFF4757), width: 2),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(live['image']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '● LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '👥 ${live['viewers']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              live['title']!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m3u8');
  }

  Widget _buildThumbnailFallback(String displayTitle) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.movie_filter_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF9F00).withValues(alpha: 0.2),
                  border: Border.all(
                    color: const Color(0xFFFF9F00).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFFFF9F00),
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  displayTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2-Column Discovery Video Card
  Widget _buildGridVideoCard(
      BuildContext context, int index, ContentPostModel post) {
    final String displayTitle = post.title?.isNotEmpty == true
        ? post.title!
        : (post.caption?.isNotEmpty == true
            ? post.caption!
            : 'Trending FCI Style');

    final rawThumbnail = post.thumbnailUrl;
    final bool hasValidThumbnail = rawThumbnail != null &&
        rawThumbnail.trim().isNotEmpty &&
        !_isVideoUrl(rawThumbnail);

    final resolvedMediaUrl = hasValidThumbnail
        ? AppUrls.resolveUrl(rawThumbnail)
        : '';

    return GestureDetector(
      onTap: () => _openFullScreenViewer(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portrait Card Thumbnail
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade900,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail Image or Fallback Gradient Widget
                    hasValidThumbnail && resolvedMediaUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: resolvedMediaUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade900,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFFF9F00)),
                              ),
                            ),
                            errorWidget: (context, url, err) =>
                                _buildThumbnailFallback(displayTitle),
                          )
                        : _buildThumbnailFallback(displayTitle),

                    // Top-Left View Count Overlay (e.g. ▷ 43.3K / 3.5L)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              _formatIndianNumber(post.viewCount > 0
                                  ? post.viewCount
                                  : (43300 + index * 12500)),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Dark Gradient Overlay at Bottom of Thumbnail
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Overlay Title/Caption inside Thumbnail
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Text(
                        displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Creator & Like Info Below Card
          Row(
            children: [
              // Store / Creator Avatar
              CircleAvatar(
                radius: 9,
                backgroundColor: const Color(0xFF2874F0),
                child: Text(
                  post.uploadedBy.isNotEmpty
                      ? post.uploadedBy[0].toUpperCase()
                      : 'F',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // Creator / Store Handle
              Expanded(
                child: Text(
                  post.uploadedBy.isNotEmpty ? post.uploadedBy : 'FCI Official',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Heart Icon & Like Count
              GestureDetector(
                onTap: () => _toggleLike(index),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      post.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                      color: post.isLiked
                          ? const Color(0xFFFF4757)
                          : Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatIndianNumber(post.likeCount),
                      style: TextStyle(
                        color: post.isLiked
                            ? const Color(0xFFFF4757)
                            : Colors.white54,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Live Stream Sample Data
  List<Map<String, String>> _getLiveStreams() {
    return [
      {
        'title': 'Glow Up Skin Routine',
        'image':
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
        'viewers': '1.4K',
      },
      {
        'title': 'Summer Style Steals 60% OFF',
        'image':
            'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400',
        'viewers': '3.2K',
      },
      {
        'title': 'Sneaker Unboxing & Review',
        'image':
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
        'viewers': '890',
      },
      {
        'title': 'Crystal Glasses & Home Finds',
        'image':
            'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=400',
        'viewers': '2.1K',
      },
    ];
  }

  /// Fallback grid items for Play Discovery Feed
  List<ContentPostModel> _getFallbackGridItems() {
    return [
      ContentPostModel(
        id: 201,
        type: 'PLAY',
        title: 'Crystal Glasses & More Finds',
        caption: 'Get 65% off on summer collection! Double tap if you love this style.',
        mediaUrls: [
          'https://assets.mixkit.co/videos/preview/mixkit-fashion-model-in-a-pink-suit-41443-large.mp4'
        ],
        mediaType: 'VIDEO',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800',
        uploadedBy: 'FCI Official',
        isActive: true,
        viewCount: 43300,
        likeCount: 2400,
        commentCount: 420,
        sortOrder: 1,
        createdAt: DateTime.now(),
        isLiked: false,
        taggedProducts: const [],
      ),
      ContentPostModel(
        id: 202,
        type: 'PLAY',
        title: 'Vibrant Sneakers & Streetwear',
        caption: 'Super comfortable sneakers for everyday wear! Limited stock available.',
        mediaUrls: [
          'https://assets.mixkit.co/videos/preview/mixkit-model-holding-a-pair-of-yellow-shoes-41441-large.mp4'
        ],
        mediaType: 'VIDEO',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
        uploadedBy: 'FCI Style',
        isActive: true,
        viewCount: 350000,
        likeCount: 18200,
        commentCount: 890,
        sortOrder: 2,
        createdAt: DateTime.now(),
        isLiked: true,
        taggedProducts: const [],
      ),
      ContentPostModel(
        id: 203,
        type: 'PLAY',
        title: 'Glam Party Outfit Try-On',
        caption: 'Best Flipkart deals for this season! Click Buy Now to claim discounts.',
        mediaUrls: [
          'https://assets.mixkit.co/videos/preview/mixkit-young-woman-with-shopping-bags-41551-large.mp4'
        ],
        mediaType: 'VIDEO',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800',
        uploadedBy: 'Glam Store',
        isActive: true,
        viewCount: 125000,
        likeCount: 8400,
        commentCount: 1250,
        sortOrder: 3,
        createdAt: DateTime.now(),
        isLiked: false,
        taggedProducts: const [],
      ),
      ContentPostModel(
        id: 204,
        type: 'PLAY',
        title: 'Trending Aesthetic Home Décor',
        caption: 'Modern minimalism for your living room.',
        mediaUrls: [
          'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=800'
        ],
        mediaType: 'IMAGE',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=800',
        uploadedBy: 'FCI Home',
        isActive: true,
        viewCount: 87500,
        likeCount: 6100,
        commentCount: 340,
        sortOrder: 4,
        createdAt: DateTime.now(),
        isLiked: false,
        taggedProducts: const [],
      ),
    ];
  }
}
