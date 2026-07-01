import 'package:flutter/material.dart';

class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  final double staggerDelay;
  final Duration duration;
  final Axis scrollDirection;
  final EdgeInsets? padding;
  final Widget? separator;

  const StaggeredListView({
    super.key,
    required this.children,
    this.staggerDelay = 0.1,
    this.duration = const Duration(milliseconds: 400),
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.separator,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: scrollDirection,
      padding: padding,
      separatorBuilder: separator != null
          ? (context, index) => separator!
          : (context, index) => const SizedBox.shrink(),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          key: ValueKey(index),
          duration: duration,
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: children[index],
        );
      },
    );
  }
}

class StaggeredGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double staggerDelay;
  final Duration duration;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;

  const StaggeredGridView({
    super.key,
    required this.children,
    required this.crossAxisCount,
    this.staggerDelay = 0.05,
    this.duration = const Duration(milliseconds: 350),
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 1.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          key: ValueKey('grid_$index'),
          duration: duration,
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: children[index],
        );
      },
    );
  }
}
