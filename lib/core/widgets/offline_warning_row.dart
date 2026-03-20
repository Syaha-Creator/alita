import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable compact row to explain that an action requires internet.
class OfflineWarningRow extends StatelessWidget {
  const OfflineWarningRow({
    super.key,
    this.message = 'Fungsi ini membutuhkan internet',
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  final String message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      liveRegion: true,
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
