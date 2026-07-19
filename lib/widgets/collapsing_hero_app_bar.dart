import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CollapsingHeroAppBar extends StatelessWidget {
  final double expandedHeight;
  final Widget heroContent;
  final Widget topRow;
  final double toolbarHeight;

  const CollapsingHeroAppBar({
    super.key,
    required this.expandedHeight,
    required this.heroContent,
    required this.topRow,
    this.toolbarHeight = 56,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final primary = Theme.of(context).colorScheme.primary;
    final minHeight = topPadding + toolbarHeight;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      toolbarHeight: toolbarHeight,
      collapsedHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final currentHeight = constraints.maxHeight;

          // t: 0.0 = expanded → 1.0 = collapsed
          final t = (1 -
                  (currentHeight - minHeight) /
                      (expandedHeight - minHeight))
              .clamp(0.0, 1.0);

          // Overscroll (stretch) pe scale > 1 — zoom effect
          final scale = currentHeight / expandedHeight;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: t > 0.5
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24 * (1 - t)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. HERO — SCALE ke saath ADJUST hota hai (clip nahi)
                  //    Top-center anchored: neeche se sikudta hai,
                  //    top row ke saath alignment maintained rehta hai.
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: currentHeight,
                      width: constraints.maxWidth,
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 0,
                        maxHeight: expandedHeight,
                        child: Transform.scale(
                          scale: scale.clamp(0.0, 1.15), // 1.15 = stretch cap
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: expandedHeight,
                            width: constraints.maxWidth,
                            child: Opacity(
                              // Aakhri 45% collapse mein fade → teal
                              opacity: ((1 - t) / 0.55).clamp(0.0, 1.0),
                              child: heroContent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. TOP SCRIM — expanded mein icons readable
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topPadding + 72,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 1 - t,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.40),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. SOLID TEAL BAR — hero fade ke saath cross-fade in
                  IgnorePointer(
                    child: Opacity(
                      opacity: (t / 0.9).clamp(0.0, 1.0),
                      child: Container(color: primary),
                    ),
                  ),

                  // 4. TOP ROW — dono states mein pinned, same jagah
                  Positioned(
                    top: topPadding + (toolbarHeight - 40) / 2,
                    left: 16,
                    right: 16,
                    height: 40,
                    child: topRow,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
