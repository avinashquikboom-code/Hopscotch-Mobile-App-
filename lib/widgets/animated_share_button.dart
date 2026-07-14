import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:hopscotch/theme/app_theme.dart';

class AnimatedShareButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final Color? color;

  const AnimatedShareButton({
    super.key,
    required this.onTap,
    this.size = 20,
    this.color,
  });

  @override
  State<AnimatedShareButton> createState() => _AnimatedShareButtonState();
}

class _AnimatedShareButtonState extends State<AnimatedShareButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.45).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.45, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.reset();
    _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Remix.send_plane_2_line,
            color: widget.color ?? AppTheme.textPrimaryColor,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
