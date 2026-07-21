import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

DateTime? _lastNavTime;

/// Safely navigates to a new route, preventing rapid double-tap route collisions
void safeNavigate(BuildContext context, String path, {Object? extra}) {
  final now = DateTime.now();
  if (_lastNavTime != null && now.difference(_lastNavTime!).inMilliseconds < 400) {
    return;
  }
  _lastNavTime = now;
  try {
    context.push(path, extra: extra);
  } catch (_) {
    context.go(path, extra: extra);
  }
}

extension SafeNavigationExtension on BuildContext {
  void safePush(String path, {Object? extra}) {
    safeNavigate(this, path, extra: extra);
  }
}
