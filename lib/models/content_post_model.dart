class TaggedProductModel {
  final int id;
  final String name;
  final String? thumbnailUrl;
  final double basePrice;
  final double price;

  const TaggedProductModel({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    required this.basePrice,
    required this.price,
  });

  factory TaggedProductModel.fromJson(Map<String, dynamic> json) {
    return TaggedProductModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      basePrice: json['basePrice'] is num
          ? (json['basePrice'] as num).toDouble()
          : double.tryParse(json['basePrice']?.toString() ?? '0') ?? 0.0,
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ContentPostCommentModel {
  final int id;
  final int contentPostId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String comment;
  final DateTime createdAt;

  const ContentPostCommentModel({
    required this.id,
    required this.contentPostId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.comment,
    required this.createdAt,
  });

  factory ContentPostCommentModel.fromJson(Map<String, dynamic> json) {
    return ContentPostCommentModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.parse(json['id'].toString()),
      contentPostId: json['contentPostId'] is num ? (json['contentPostId'] as num).toInt() : int.parse(json['contentPostId'].toString()),
      userId: json['userId'] is num ? (json['userId'] as num).toInt() : int.parse(json['userId'].toString()),
      userName: json['userName']?.toString() ?? 'User',
      userAvatar: json['userAvatar']?.toString(),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

class ContentPostModel {
  final int id;
  final String type; // PLAY | POST | STORY
  final String? title;
  final String? caption;
  final List<String> mediaUrls;
  final String mediaType; // IMAGE | VIDEO
  final String? thumbnailUrl;
  final String uploadedBy;
  final bool isActive;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int sortOrder;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final bool isLiked;
  final List<TaggedProductModel> taggedProducts;

  const ContentPostModel({
    required this.id,
    required this.type,
    this.title,
    this.caption,
    required this.mediaUrls,
    required this.mediaType,
    this.thumbnailUrl,
    required this.uploadedBy,
    required this.isActive,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.sortOrder,
    this.expiresAt,
    required this.createdAt,
    required this.isLiked,
    required this.taggedProducts,
  });

  factory ContentPostModel.fromJson(Map<String, dynamic> json) {
    List<String> urls = [];
    if (json['mediaUrls'] is List) {
      urls = (json['mediaUrls'] as List).map((e) => e.toString()).toList();
    }

    List<TaggedProductModel> products = [];
    if (json['taggedProducts'] is List) {
      products = (json['taggedProducts'] as List)
          .map((e) => TaggedProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ContentPostModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.parse(json['id'].toString()),
      type: json['type']?.toString() ?? 'POST',
      title: json['title']?.toString(),
      caption: json['caption']?.toString(),
      mediaUrls: urls,
      mediaType: json['mediaType']?.toString() ?? 'IMAGE',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      uploadedBy: json['uploadedBy']?.toString() ?? 'ADMIN',
      isActive: json['isActive'] == true || json['isActive'] == 'true',
      viewCount: json['viewCount'] is num
          ? (json['viewCount'] as num).toInt()
          : int.tryParse(json['viewCount']?.toString() ?? '0') ?? 0,
      likeCount: json['likeCount'] is num
          ? (json['likeCount'] as num).toInt()
          : int.tryParse(json['likeCount']?.toString() ?? '0') ?? 0,
      commentCount: json['commentCount'] is num
          ? (json['commentCount'] as num).toInt()
          : int.tryParse(json['commentCount']?.toString() ?? '0') ?? 0,
      sortOrder: json['sortOrder'] is num
          ? (json['sortOrder'] as num).toInt()
          : int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()) : DateTime.now(),
      isLiked: json['isLiked'] == true || json['isLiked'] == 'true',
      taggedProducts: products,
    );
  }

  ContentPostModel copyWith({
    bool? isLiked,
    int? likeCount,
    int? viewCount,
    int? commentCount,
  }) {
    return ContentPostModel(
      id: id,
      type: type,
      title: title,
      caption: caption,
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      thumbnailUrl: thumbnailUrl,
      uploadedBy: uploadedBy,
      isActive: isActive,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      sortOrder: sortOrder,
      expiresAt: expiresAt,
      createdAt: createdAt,
      isLiked: isLiked ?? this.isLiked,
      taggedProducts: taggedProducts,
    );
  }

  /// Returns a valid image URL for thumbnail preview, excluding video files (.mp4 etc)
  String? get effectiveThumbnailUrl {
    if (thumbnailUrl != null &&
        thumbnailUrl!.trim().isNotEmpty &&
        !_isVideoUrl(thumbnailUrl!)) {
      return thumbnailUrl;
    }
    for (final product in taggedProducts) {
      if (product.thumbnailUrl != null &&
          product.thumbnailUrl!.trim().isNotEmpty &&
          !_isVideoUrl(product.thumbnailUrl!)) {
        return product.thumbnailUrl;
      }
    }
    for (final url in mediaUrls) {
      if (url.trim().isNotEmpty && !_isVideoUrl(url)) {
        return url;
      }
    }
    return null;
  }

  static bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m3u8');
  }
}
