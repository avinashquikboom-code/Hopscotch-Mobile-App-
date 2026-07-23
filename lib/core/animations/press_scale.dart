import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_durations.dart';
import 'app_curves.dart';

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final bool enableHaptics;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.enableHaptics = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: AppDurations.scalePress,
        curve: AppCurves.scalePress,
        child: widget.child,
      ),
    );
  }
}
