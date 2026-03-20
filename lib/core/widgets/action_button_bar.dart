import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Reusable action button row for primary/secondary actions.
///
/// Function:
/// - Menyatukan pola tombol aksi (utama + opsional sekunder) agar konsisten.
/// - Bisa dipakai sebagai tombol full-width di bottom section atau modal.
/// - Mendukung ikon/leading custom tanpa mengubah style dasar tiap halaman.
class ActionButtonBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final Widget? primaryLeading;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final Widget? secondaryLeading;
  final bool fullWidth;
  final double height;
  final double borderRadius;
  final TextStyle? primaryLabelStyle;
  final TextStyle? secondaryLabelStyle;
  final Color primaryBackgroundColor;
  final Color primaryForegroundColor;
  final Color secondaryBorderColor;
  final Color secondaryForegroundColor;
  final MainAxisSize mainAxisSize;
  final double gap;

  const ActionButtonBar({
    super.key,
    required this.primaryLabel,
    this.onPrimaryPressed,
    this.primaryLeading,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.secondaryLeading,
    this.fullWidth = true,
    this.height = 50,
    this.borderRadius = 14,
    this.primaryLabelStyle,
    this.secondaryLabelStyle,
    this.primaryBackgroundColor = AppColors.accent,
    this.primaryForegroundColor = AppColors.onPrimary,
    this.secondaryBorderColor = AppColors.accent,
    this.secondaryForegroundColor = AppColors.accent,
    this.mainAxisSize = MainAxisSize.max,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    final primaryButton = SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPrimaryPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPrimaryPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBackgroundColor,
          foregroundColor: primaryForegroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (primaryLeading != null) ...[
              primaryLeading!,
              const SizedBox(width: 8),
            ],
            Text(primaryLabel, style: primaryLabelStyle),
          ],
        ),
      ),
    );

    final secondaryButton = secondaryLabel == null
        ? null
        : SizedBox(
            height: height,
            child: OutlinedButton(
              onPressed: onSecondaryPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: secondaryForegroundColor,
                side: BorderSide(color: secondaryBorderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (secondaryLeading case final leading?) ...[
                    leading,
                    const SizedBox(width: 8),
                  ],
                  Text(secondaryLabel ?? '', style: secondaryLabelStyle),
                ],
              ),
            ),
          );

    if (fullWidth) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (secondaryButton != null) ...[
            Expanded(child: secondaryButton),
            SizedBox(width: gap),
          ],
          Expanded(child: primaryButton),
        ],
      );
    }

    return Row(
      mainAxisSize: mainAxisSize,
      children: [
        if (secondaryButton != null) ...[
          secondaryButton,
          SizedBox(width: gap),
        ],
        primaryButton,
      ],
    );
  }
}
