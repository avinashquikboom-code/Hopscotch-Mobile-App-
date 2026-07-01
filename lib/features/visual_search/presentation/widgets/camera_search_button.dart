import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

/// Camera search button widget
/// Small icon button to be inserted into the existing search bar
class CameraSearchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CameraSearchButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Remix.camera_lens_line,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      onPressed: onPressed,
      tooltip: 'Visual Search',
    );
  }
}
