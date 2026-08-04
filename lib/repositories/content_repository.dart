import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/content_post_model.dart';
import 'package:hopscotch/utils/dev_logger.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ContentRepository(apiService);
});

class ContentRepository {
  final ApiService _apiService;

  ContentRepository(this._apiService);

  /// Fetch PLAY vertical video feed
  Future<List<ContentPostModel>> getPlayFeed({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        AppUrls.contentPlay,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List rawList = data is Map ? (data['data'] ?? []) : data;
        return rawList.map((e) => ContentPostModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      DevLogger.logError('Error fetching Play feed: $e', context: 'ContentRepository');
      return [];
    }
  }

  /// Fetch POSTS image/carousel feed
  Future<List<ContentPostModel>> getPostsFeed({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        AppUrls.contentPosts,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List rawList = data is Map ? (data['data'] ?? []) : data;
        return rawList.map((e) => ContentPostModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      DevLogger.logError('Error fetching Posts feed: $e', context: 'ContentRepository');
      return [];
    }
  }

  /// Fetch active non-expired STORIES for top avatar strip
  Future<List<ContentPostModel>> getStories() async {
    try {
      final response = await _apiService.get(AppUrls.contentStories);

      if (response.statusCode == 200) {
        final data = response.data;
        final List rawList = data is Map ? (data['data'] ?? []) : data;
        return rawList.map((e) => ContentPostModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      DevLogger.logError('Error fetching Stories: $e', context: 'ContentRepository');
      return [];
    }
  }

  /// Toggle like status for a content post
  Future<({bool isLiked, int likeCount})?> toggleLike(int contentPostId) async {

    try {
      final response = await _apiService.post(AppUrls.contentLike(contentPostId));

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return (
          isLiked: data['isLiked'] == true,
          likeCount: (data['likeCount'] as num).toInt(),
        );
      }
      return null;
    } catch (e) {
      DevLogger.logError('Error toggling content like: $e', context: 'ContentRepository');
      return null;
    }
  }

  /// Track content item view (throttled)
  Future<void> incrementView(int contentPostId) async {
    try {
      await _apiService.post(AppUrls.contentView(contentPostId));
    } catch (e) {
      DevLogger.logError('Error incrementing view count: $e', context: 'ContentRepository');
    }
  }

  /// Get comments for a content post
  Future<List<ContentPostCommentModel>> getComments(int contentPostId, {int page = 1}) async {
    try {
      final response = await _apiService.get(
        '${AppUrls.contentComments(contentPostId)}?page=$page&limit=20',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List rawList = data is Map ? (data['comments'] ?? []) : [];
        return rawList.map((e) => ContentPostCommentModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      DevLogger.logError('Error fetching comments: $e', context: 'ContentRepository');
      return [];
    }
  }

  /// Add a comment to a content post
  Future<ContentPostCommentModel?> addComment(int contentPostId, String comment) async {
    try {
      final response = await _apiService.post(
        AppUrls.addContentComment(contentPostId),
        data: {'comment': comment},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        return ContentPostCommentModel.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      DevLogger.logError('Error adding comment: $e', context: 'ContentRepository');
      return null;
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await _apiService.delete(AppUrls.deleteContentComment(commentId));
      return response.statusCode == 200;
    } catch (e) {
      DevLogger.logError('Error deleting comment: $e', context: 'ContentRepository');
      return false;
    }
  }
}

