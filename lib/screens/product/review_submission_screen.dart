import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/repositories/product_repository.dart';

/// Shown when user taps "Rate this product" from a delivered order.
///
/// Route args (passed via GoRouter extra):
///   {'productId': String, 'orderId': String, 'productName': String, 'productImageUrl': String?}
class ReviewSubmissionScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? orderId;
  final String productName;
  final String? productImageUrl;

  const ReviewSubmissionScreen({
    super.key,
    required this.productId,
    this.orderId,
    required this.productName,
    this.productImageUrl,
  });

  @override
  ConsumerState<ReviewSubmissionScreen> createState() =>
      _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState
    extends ConsumerState<ReviewSubmissionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedRating = 0;
  int _hoveredRating = 0;
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnim;

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  String _getRatingLabel(int r) {
    switch (r) {
      case 1:
        return 'Terrible 😣';
      case 2:
        return 'Poor 😕';
      case 3:
        return 'Okay 🙂';
      case 4:
        return 'Good 😊';
      case 5:
        return 'Excellent! 🌟';
      default:
        return 'Tap a star to rate';
    }
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a star rating'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final api = ref.read(apiServiceProvider);
      await api.post(
        '/api/v1/mobile/products/${widget.productId}/reviews',
        data: {
          'rating': _selectedRating,
          if (_titleController.text.trim().isNotEmpty)
            'title': _titleController.text.trim(),
          if (_commentController.text.trim().isNotEmpty)
            'comment': _commentController.text.trim(),
          if (widget.orderId != null && widget.orderId!.isNotEmpty)
            'orderId': int.tryParse(widget.orderId!),
        },
      );

      ref.invalidate(productReviewsProvider(widget.productId));
      ref.invalidate(productDetailProvider(widget.productId));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
        _successAnimController.forward();
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final msg = e.toString().contains('403')
            ? 'You must have purchased and received this product to review it.'
            : e.toString().contains('409')
                ? 'You have already reviewed this product for this order.'
                : 'Failed to submit review. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final responsive = ResponsiveText(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _submitted ? 'Review Submitted!' : 'Write a Review',
          style: TextStyle(
            fontSize: responsive.fontSize(17),
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _submitted ? _buildSuccessState(colorScheme, responsive) : _buildForm(colorScheme, responsive, isDark),
    );
  }

  Widget _buildSuccessState(ColorScheme colorScheme, ResponsiveText responsive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _successScaleAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 64),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Thank you for your review!',
              style: TextStyle(fontSize: responsive.fontSize(22), fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your feedback helps other shoppers make better choices.',
              style: TextStyle(fontSize: responsive.fontSize14, color: colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                for (int i = 1; i <= 5; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i <= _selectedRating ? const Color(0xFFF59E0B) : colorScheme.outline,
                      size: 30,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme colorScheme, ResponsiveText responsive, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (widget.productImageUrl != null && widget.productImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.productImageUrl!,
                      width: 56, height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_rounded, size: 40),
                    ),
                  )
                else
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 28),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: responsive.fontSize14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '✓ Verified Purchase',
                          style: TextStyle(fontSize: responsive.fontSize11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Star Rating
          Text(
            'Your Rating',
            style: TextStyle(fontSize: responsive.fontSize15, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final filled = starIndex <= (_hoveredRating > 0 ? _hoveredRating : _selectedRating);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRating = starIndex);
                },
                onTapDown: (_) => setState(() => _hoveredRating = starIndex),
                onTapUp: (_) => setState(() => _hoveredRating = 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: filled ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? const Color(0xFFF59E0B) : colorScheme.outline.withValues(alpha: 0.5),
                      size: 44,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _getRatingLabel(_hoveredRating > 0 ? _hoveredRating : _selectedRating),
              key: ValueKey(_hoveredRating > 0 ? _hoveredRating : _selectedRating),
              style: TextStyle(
                fontSize: responsive.fontSize14,
                fontWeight: FontWeight.w600,
                color: _selectedRating > 0 ? const Color(0xFFF59E0B) : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 28),

          // Title field (optional)
          Text(
            'Review Title (Optional)',
            style: TextStyle(fontSize: responsive.fontSize14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            maxLength: 80,
            decoration: InputDecoration(
              hintText: 'Summarize your experience',
              hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: responsive.fontSize14),
              filled: true,
              fillColor: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainer,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 8),

          // Comment field (optional)
          Text(
            'Your Review (Optional)',
            style: TextStyle(fontSize: responsive.fontSize14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Share details about the quality, fit, or delivery...',
              hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: responsive.fontSize14),
              filled: true,
              fillColor: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainer,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Submit Review',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: responsive.fontSize16),
                    ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
