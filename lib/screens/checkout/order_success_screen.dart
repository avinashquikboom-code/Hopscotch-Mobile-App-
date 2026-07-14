import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/widgets/custom_button.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(AppTheme.spaceXXL),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated check circle
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: EdgeInsets.all(
                    responsive.spacing(AppTheme.spaceXXL),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.successColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successColor,
                    size: responsive.iconSize(72),
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

              // Success Text
              Text(
                'ORDER PLACED!',
                style: TextStyle(
                  fontSize: responsive.fontSize28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceM)),
              Text(
                'Your luxury wardrobe upgrade is locked in. We have sent the invoice and handcraft tracking links to your registered inbox.',
                style: responsive.bodyMedium.copyWith(
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

              // Order Code Box
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.spacing(16),
                  horizontal: responsive.spacing(24),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order ID',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: responsive.fontSize14,
                      ),
                    ),
                    Text(
                      widget.orderId,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.fontSize15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(60)),

              // Buttons
              SizedBox(
                height: responsive.spacing(56),
                child: CustomButton(
                  text: 'CONTINUE SHOPPING',
                  onPressed: () => context.go('/'),
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              SizedBox(
                height: responsive.spacing(56),
                child: CustomButton(
                  text: 'TRACK MY ORDER',
                  onPressed: () => context.go('/my-orders'),
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
