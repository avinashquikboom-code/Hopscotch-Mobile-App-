import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/content_post_model.dart';
import 'package:hopscotch/repositories/content_repository.dart';
import 'package:hopscotch/screens/content/play_screen.dart';
import 'package:hopscotch/screens/content/story_viewer_screen.dart';
import 'package:hopscotch/theme/app_theme.dart';

class StoriesStrip extends ConsumerStatefulWidget {
  const StoriesStrip({super.key});

  @override
  ConsumerState<StoriesStrip> createState() => _StoriesStripState();
}

class _StoriesStripState extends ConsumerState<StoriesStrip> {
  List<ContentPostModel> _stories = [];
  bool _isLoading = true;
  final Set<int> _viewedStoryIds = {};

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    final repo = ref.read(contentRepositoryProvider);
    final items = await repo.getStories();
    if (mounted) {
      setState(() {
        _stories = items;
        _isLoading = false;
      });
    }
  }

  void _openStoryViewer(int initialIndex) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          stories: _stories,
          initialIndex: initialIndex,
          onStoryViewed: (id) {
            setState(() {
              _viewedStoryIds.add(id);
            });
          },
        ),
      ),
    );
  }

  void _openPlayScreen() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlayScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 5,
          itemBuilder: (context, index) {
            if (index == 0) return _buildPlayAvatarButton();
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 1 + _stories.length, // 1 for PLAY badge + stories
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildPlayAvatarButton();
          }


          final storyIndex = index - 1;
          final story = _stories[storyIndex];
          final isViewed = _viewedStoryIds.contains(story.id);

          return _buildStoryAvatar(story, storyIndex, isViewed);
        },
      ),
    );
  }

  Widget _buildPlayAvatarButton() {
    return GestureDetector(
      onTap: _openPlayScreen,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.accentColor, Colors.purple.shade400, Colors.pinkAccent],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.black87,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Play',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryAvatar(ContentPostModel story, int index, bool isViewed) {
    final avatarUrl = story.thumbnailUrl ?? (story.mediaUrls.isNotEmpty ? story.mediaUrls.first : '');

    return GestureDetector(
      onTap: () => _openStoryViewer(index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed
                    ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade300])
                    : const LinearGradient(
                        colors: [AppTheme.accentColor, Colors.orangeAccent, Colors.pinkAccent],
                      ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(AppUrls.resolveUrl(avatarUrl))
                      : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.style_rounded, color: AppTheme.accentColor, size: 20)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                story.title ?? 'Story',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isViewed ? FontWeight.normal : FontWeight.w600,
                  color: isViewed ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
