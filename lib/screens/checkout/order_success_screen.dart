import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/widgets/custom_button.dart';
import 'package:lottie/lottie.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyOrderId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.orderId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Order ID copied to clipboard!',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const primaryColor = AppTheme.primaryColor;
    const Color successColor = Color(0xFF10B981);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(AppTheme.spaceL),
            vertical: responsive.spacing(AppTheme.spaceM),
          ),
          child: Column(
            children: [
              SizedBox(height: responsive.spacing(30)),

              // 1. Celebratory Animated Lottie Hero Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  width: responsive.spacing(160),
                  height: responsive.spacing(160),
                  child: Lottie.asset(
                    'assets/lottie/success.json',
                    fit: BoxFit.contain,
                    repeat: false,
                    errorBuilder: (context, error, stackTrace) {
                      return Lottie.network(
                        'https://assets5.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                        fit: BoxFit.contain,
                        repeat: false,
                        errorBuilder: (context, err, stack) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: responsive.spacing(130),
                                height: responsive.spacing(130),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: successColor.withValues(alpha: 0.06),
                                ),
                              ),
                              Container(
                                width: responsive.spacing(76),
                                height: responsive.spacing(76),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: successColor,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: responsive.iconSize(44),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: responsive.spacing(24)),

              // 2. Animated Header Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Status Badge Tag
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(14),
                          vertical: responsive.spacing(6),
                        ),
                        decoration: BoxDecoration(
                          color: successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: successColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PAYMENT CONFIRMED',
                              style: TextStyle(
                                color: successColor,
                                fontWeight: FontWeight.w700,
                                fontSize: responsive.fontSize11,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: responsive.spacing(12)),

                      // Main Title
                      Text(
                        'ORDER PLACED!',
                        style: TextStyle(
                          fontSize: responsive.fontSize(26),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: textColor,
                        ),
                      ),

                      SizedBox(height: responsive.spacing(8)),

                      // Subtitle
                      Text(
                        'Thank you for your purchase! We have received your order and sent confirmation details to your registered email.',
                        textAlign: TextAlign.center,
                        style: responsive.bodyMedium.copyWith(
                          color: subtextColor,
                          fontSize: responsive.fontSize13,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: responsive.spacing(24)),

                      // 3. Order Reference Card (Order ID + Copy Button)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(responsive.spacing(16)),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ORDER NUMBER',
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: responsive.fontSize10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.orderId.startsWith('#')
                                          ? widget.orderId
                                          : '#${widget.orderId}',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: responsive.fontSize16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),

                                InkWell(
                                  onTap: () => _copyOrderId(context),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsive.spacing(12),
                                      vertical: responsive.spacing(8),
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: primaryColor.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.copy_rounded,
                                          size: responsive.iconSize(14),
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'COPY',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: responsive.fontSize11,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, thickness: 1),
                            ),

                            // Estimated Delivery Banner
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.local_shipping_outlined,
                                    color: primaryColor,
                                    size: responsive.iconSize(20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ESTIMATED DELIVERY',
                                        style: TextStyle(
                                          color: subtextColor,
                                          fontSize: responsive.fontSize10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '3 – 5 Business Days',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: responsive.fontSize13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: responsive.spacing(20)),

                      // 4. Order Journey Progress Stepper Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(responsive.spacing(16)),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.alt_route_rounded,
                                  size: responsive.iconSize(18),
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Order Status',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: responsive.fontSize14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: responsive.spacing(16)),

                            // Stepper Rows
                            _buildStepRow(
                              responsive: responsive,
                              title: 'Order Placed',
                              subtitle: 'Received and verified',
                              isDone: true,
                              isCurrent: false,
                              textColor: textColor,
                              subtextColor: subtextColor,
                              successColor: successColor,
                            ),
                            _buildStepConnector(successColor: successColor),
                            _buildStepRow(
                              responsive: responsive,
                              title: 'Processing',
                              subtitle: 'Preparing items in warehouse',
                              isDone: false,
                              isCurrent: true,
                              textColor: textColor,
                              subtextColor: subtextColor,
                              successColor: successColor,
                            ),
                            _buildStepConnector(successColor: isDark ? Colors.white10 : Colors.black12),
                            _buildStepRow(
                              responsive: responsive,
                              title: 'Dispatched',
                              subtitle: 'Handed to courier partner',
                              isDone: false,
                              isCurrent: false,
                              textColor: textColor,
                              subtextColor: subtextColor,
                              successColor: successColor,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: responsive.spacing(36)),

                      // 5. Action Buttons
                      SizedBox(
                        height: responsive.spacing(54),
                        width: double.infinity,
                        child: CustomButton(
                          text: 'TRACK MY ORDER',
                          onPressed: () {
                            if (widget.orderId.isNotEmpty) {
                              context.go('/track-order/${widget.orderId}');
                            } else {
                              context.go('/my-orders');
                            }
                          },
                        ),
                      ),

                      SizedBox(height: responsive.spacing(12)),

                      SizedBox(
                        height: responsive.spacing(54),
                        width: double.infinity,
                        child: CustomButton(
                          text: 'CONTINUE SHOPPING',
                          onPressed: () => context.go('/'),
                          isOutlined: true,
                        ),
                      ),

                      SizedBox(height: responsive.spacing(20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required dynamic responsive,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required Color textColor,
    required Color subtextColor,
    required Color successColor,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? successColor
                : isCurrent
                    ? AppTheme.primaryColor
                    : Colors.transparent,
            border: Border.all(
              color: isDone
                  ? successColor
                  : isCurrent
                      ? AppTheme.primaryColor
                      : subtextColor.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Icon(
            isDone
                ? Icons.check_rounded
                : isCurrent
                    ? Icons.sync_rounded
                    : Icons.circle_outlined,
            size: 14,
            color: (isDone || isCurrent) ? Colors.white : subtextColor.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: (isDone || isCurrent) ? textColor : subtextColor,
                  fontWeight: (isDone || isCurrent) ? FontWeight.w700 : FontWeight.w500,
                  fontSize: responsive.fontSize13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: responsive.fontSize11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required Color successColor}) {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
      height: 18,
      width: 2,
      color: successColor,
    );
  }
}
