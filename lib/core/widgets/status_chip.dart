import 'package:flutter/material.dart';

/// Reusable compact status badge with optional icon.
///
/// Function:
/// - Menstandarkan tampilan badge status (approved/pending/rejected/take-away).
/// - Mengurangi duplikasi `Container + Row + Text` untuk label status.
/// - Tetap fleksibel lewat warna, border, dan spacing yang bisa dikustom.
class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final TextStyle? textStyle;
  final Border? border;
  final double iconSize;
  final double iconSpacing;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.borderRadius = 20,
    this.textStyle,
    this.border,
    this.iconSize = 12,
    this.iconSpacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: foregroundColor),
            SizedBox(width: iconSpacing),
          ],
          Text(
            label,
            style:
                textStyle ??
                TextStyle(
                  color: foregroundColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
