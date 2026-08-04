import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/content_post_model.dart';
import 'package:hopscotch/repositories/content_repository.dart';
import 'package:hopscotch/theme/app_theme.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final int contentPostId;
  final Function(int newCount)? onCommentAdded;

  const CommentsBottomSheet({
    super.key,
    required this.contentPostId,
    this.onCommentAdded,
  });

  static void show(
    BuildContext context, {
    required int contentPostId,
    Function(int newCount)? onCommentAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CommentsBottomSheet(
          contentPostId: contentPostId,
          onCommentAdded: onCommentAdded,
        ),
      ),
    );
  }

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<ContentPostCommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  ContentPostCommentModel? _replyingToComment;

  // Local like state per comment index
  final Map<int, bool> _likedMap = {};

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final repo = ref.read(contentRepositoryProvider);
    final items = await repo.getComments(widget.contentPostId);
    if (mounted) {
      setState(() {
        _comments = items;
        _isLoading = false;
      });
    }
  }

  void _startReply(ContentPostCommentModel comment) {
    HapticFeedback.lightImpact();
    setState(() => _replyingToComment = comment);
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyingToComment = null);
    _commentController.clear();
  }

  void _toggleLikeComment(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _likedMap[index] = !(_likedMap[index] ?? false);
    });
  }

  Future<void> _submitComment() async {
    String text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    if (_replyingToComment != null &&
        !text.startsWith('@${_replyingToComment!.userName}')) {
      text = '@${_replyingToComment!.userName} $text';
    }

    HapticFeedback.lightImpact();
    setState(() => _isSubmitting = true);

    final repo = ref.read(contentRepositoryProvider);
    final newComment = await repo.addComment(widget.contentPostId, text);

    if (mounted) {
      if (newComment != null) {
        _commentController.clear();
        _focusNode.unfocus();
        setState(() {
          _comments.insert(0, newComment);
          _replyingToComment = null;
        });
        widget.onCommentAdded?.call(_comments.length);
        // Scroll to top to show new comment
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to post comment. Please log in first.'),
            ),
          );
        }
      }
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    return '${(diff.inDays / 30).floor()}mo';
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──────────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header: "Comments" centered ──────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Comments',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 0.2,
              ),
            ),
          ),

          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEBEBEB)),

          // ── Comments List ─────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentColor,
                      strokeWidth: 2,
                    ),
                  )
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) =>
                            _buildCommentTile(index),
                      ),
          ),

          // ── Replying Banner ───────────────────────────────────────
          if (_replyingToComment != null) _buildReplyBanner(),

          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEBEBEB)),

          // ── Input Bar ─────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No comments yet.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start the conversation.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(int index) {
    final c = _comments[index];
    final avatarUrl = AppUrls.resolveUrl(c.userAvatar);
    final isLiked = _likedMap[index] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFF0F0F0),
            backgroundImage: avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    c.userName.isNotEmpty
                        ? c.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Comment Body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username + Comment inline (Instagram style)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.black,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: '${c.userName} ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: c.comment,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Time · Like count · Reply
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(c.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isLiked) ...[
                      const SizedBox(width: 14),
                      Text(
                        '1 like',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => _startReply(c),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Heart icon (Instagram style — right side of comment)
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toggleLikeComment(index),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 14,
                color: isLiked ? Colors.red : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF9F9F9),
      child: Row(
        children: [
          Text(
            'Replying to ',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            '@${_replyingToComment!.userName}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cancelReply,
            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Current user avatar placeholder
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFF0F0F0),
              child: Icon(Icons.person, size: 16, color: Colors.grey),
            ),
            const SizedBox(width: 10),

            // Text Field — borderless, Instagram style
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        style: const TextStyle(fontSize: 13.5, color: Colors.black),
                        decoration: InputDecoration(
                          hintText: _replyingToComment != null
                              ? 'Reply to @${_replyingToComment!.userName}...'
                              : 'Add a comment...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey.shade500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Post button — only visible when text is entered
            if (_commentController.text.trim().isNotEmpty) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _submitComment,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentColor,
                        ),
                      )
                    : const Text(
                        'Post',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentColor,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
