import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'network_image_view.dart';

/// Reusable full-screen image viewer dialog with pinch-to-zoom.
///
/// Every parameter is optional except [context] and [imageUrl],
/// making it easy to call from any page with sensible defaults.
class ImageViewerDialog {
  ImageViewerDialog._();

  static Future<void> show({
    required BuildContext context,
    required String imageUrl,
    EdgeInsets insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
    double borderRadius = 12,
    bool panEnabled = true,
    double minScale = 0.8,
    double maxScale = 2.5,
    Widget? loadingWidget,
    Widget? errorWidget,
    bool closeAsIconButton = false,
    double closeTop = 8,
    double closeRight = 8,
    double closeIconSize = 20,
    IconData closeIcon = Icons.close_rounded,
    Color closeIconColor = AppColors.onPrimary,
    Color closeBackgroundColor = Colors.black54,
    EdgeInsets closePadding = const EdgeInsets.all(6),
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Semantics(
        label: 'Lihat gambar',
        image: true,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: insetPadding,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: panEnabled,
                minScale: minScale,
                maxScale: maxScale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: NetworkImageView(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    memCacheWidth: 800,
                    loadingBuilder: loadingWidget == null
                        ? null
                        : (_, __) => loadingWidget,
                    errorWidget: errorWidget ??
                        const Center(
                          child: Icon(Icons.broken_image,
                              color: AppColors.onPrimary),
                        ),
                  ),
                ),
              ),
              Positioned(
                top: closeTop,
                right: closeRight,
                child: Semantics(
                  label: 'Tutup',
                  button: true,
                  child: closeAsIconButton
                      ? IconButton(
                          icon: Icon(
                            closeIcon,
                            color: closeIconColor,
                            size: closeIconSize,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        )
                      : GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            decoration: BoxDecoration(
                              color: closeBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: closePadding,
                            child: Icon(
                              closeIcon,
                              color: closeIconColor,
                              size: closeIconSize,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible alias for the old class name.
typedef DetailImageViewerDialog = ImageViewerDialog;
