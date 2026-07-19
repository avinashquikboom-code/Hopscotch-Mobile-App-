import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedSearchHint extends StatefulWidget {
  final List<String> hints;
  final String prefix;            // e.g. "Search for " (empty = none)
  final TextStyle style;
  final Duration interval;
  final Duration animDuration;

  const AnimatedSearchHint({
    super.key,
    required this.hints,
    this.prefix = '',
    required this.style,
    this.interval = const Duration(seconds: 3),
    this.animDuration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<AnimatedSearchHint> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    if (widget.hints.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.hints.length);
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedSearchHint old) {
    super.didUpdateWidget(old);
    if (old.hints.length != widget.hints.length) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.hints.isEmpty ? '' : widget.hints[_index];

    return Row(
      children: [
        if (widget.prefix.isNotEmpty)
          Text(widget.prefix, style: widget.style),
        Expanded(
          child: ClipRect( // slide ke dauraan text bar se bahar na jhanke
            child: AnimatedSwitcher(
              duration: widget.animDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                // Naya: neeche(+1) se 0 pe aata hai.
                // Purana: 0 se upar(-1) jata hai (reverse animation se).
                final slide = Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, if (current != null) current],
              ),
              child: Text(
                hint,
                key: ValueKey(hint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.style,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
