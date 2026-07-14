import 'package:flutter/material.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails detail) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails detail) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    Widget buttonChild = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLoading) ...[
            SizedBox(
              width: responsive.iconSize(20),
              height: responsive.iconSize(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isOutlined ? AppTheme.primaryColor : Colors.white,
                ),
              ),
            ),
            SizedBox(width: responsive.spacing(AppTheme.spaceM)),
          ] else if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: responsive.iconSize(18),
              color: widget.isOutlined
                  ? (widget.textColor ?? AppTheme.textPrimaryColor)
                  : Colors.white,
            ),
            SizedBox(width: responsive.spacing(AppTheme.spaceS)),
          ],
          Text(
            widget.text.toUpperCase(),
            style: TextStyle(
              color: widget.isOutlined
                  ? (widget.textColor ?? AppTheme.textPrimaryColor)
                  : (widget.textColor ?? Colors.white),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: responsive.fontSize14,
            ),
          ),
        ],
      ),
    );

    Widget buttonBody;

    if (widget.isOutlined) {
      buttonBody = OutlinedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style:
            OutlinedButton.styleFrom(
              side: BorderSide(
                color: widget.backgroundColor ?? AppTheme.borderColor,
                width: 1.5,
              ),
              padding: EdgeInsets.symmetric(
                vertical: responsive.spacing(12),
                horizontal: responsive.spacing(28),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              elevation: 0,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return (widget.backgroundColor ?? AppTheme.primaryColor)
                      .withValues(alpha: 0.1);
                }
                if (states.contains(WidgetState.hovered)) {
                  return (widget.backgroundColor ?? AppTheme.primaryColor)
                      .withValues(alpha: 0.05);
                }
                return null;
              }),
            ),
        child: buttonChild,
      );
    } else {
      buttonBody = ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor ?? AppTheme.primaryColor,
              elevation: 0,
              shadowColor: (widget.backgroundColor ?? AppTheme.primaryColor)
                  .withValues(alpha: 0.3),
              padding: EdgeInsets.symmetric(
                vertical: responsive.spacing(12),
                horizontal: responsive.spacing(28),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withValues(alpha: 0.2);
                }
                if (states.contains(WidgetState.hovered)) {
                  return Colors.white.withValues(alpha: 0.1);
                }
                return null;
              }),
            ),
        child: buttonChild,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: buttonBody,
        ),
      ),
    );
  }
}
