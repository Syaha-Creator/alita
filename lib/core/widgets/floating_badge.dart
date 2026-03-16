import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable circular badge for floating icons/buttons.
///
/// Function:
/// - Menampilkan jumlah item kecil di atas widget lain (mis. FAB/icon).
/// - Otomatis membatasi angka besar lewat `maxCount` (contoh: `99+`).
/// - Menjaga gaya badge konsisten di semua fitur.
class FloatingBadge extends StatelessWidget {
  final int count;
  final int maxCount;
  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;
  final Color backgroundColor;
  final TextStyle? textStyle;

  const FloatingBadge({
    super.key,
    required this.count,
    this.maxCount = 99,
    this.padding = const EdgeInsets.all(6),
    this.constraints = const BoxConstraints(minWidth: 20, minHeight: 20),
    this.backgroundColor = AppColors.accent,
    this.textStyle,
  });

  String get _displayText => count > maxCount ? '$maxCount+' : '$count';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      constraints: constraints,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _displayText,
          style:
              textStyle ??
              const TextStyle(
                color: AppColors.surface,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
