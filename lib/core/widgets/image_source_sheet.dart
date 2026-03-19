import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/platform_utils.dart';

/// A beautifully styled bottom sheet for choosing between camera and gallery.
///
/// Usage:
/// ```dart
/// ImageSourceSheet.show(
///   context: context,
///   title: 'Upload Bukti Pembayaran',
///   onCamera: () { ... },
///   onGallery: () { ... },
/// );
/// ```
class ImageSourceSheet extends StatelessWidget {
  final String title;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const ImageSourceSheet({
    super.key,
    this.title = 'Pilih Sumber Gambar',
    required this.onCamera,
    required this.onGallery,
  });

  static Future<void> show({
    required BuildContext context,
    String title = 'Pilih Sumber Gambar',
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    if (isIOS) {
      return showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text(title),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                onCamera();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.camera, size: 20),
                  SizedBox(width: 8),
                  Text('Kamera'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                onGallery();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.photo, size: 20),
                  SizedBox(width: 8),
                  Text('Galeri'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ImageSourceSheet(
        title: title,
        onCamera: () {
          Navigator.pop(context);
          onCamera();
        },
        onGallery: () {
          Navigator.pop(context);
          onGallery();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: onCamera,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onTap: onGallery,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accent, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
