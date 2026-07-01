import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:remixicon/remixicon.dart';

/// Bottom sheet for selecting image source (Camera or Gallery)
class VisualSearchBottomSheet extends StatelessWidget {
  final ImagePicker picker;

  const VisualSearchBottomSheet({
    super.key,
    required this.picker,
  });

  static Future<XFile?> show(BuildContext context) {
    return showModalBottomSheet<XFile>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => VisualSearchBottomSheet(picker: ImagePicker()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Remix.camera_line,
                  color: Color(0xFF00897B),
                  size: 24,
                ),
              ),
              title: const Text(
                'Take a photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Use camera to capture product'),
              onTap: () async {
                final image = await picker.pickImage(source: ImageSource.camera);
                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Remix.image_line,
                  color: Color(0xFF00897B),
                  size: 24,
                ),
              ),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Select image from photos'),
              onTap: () async {
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF00897B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
