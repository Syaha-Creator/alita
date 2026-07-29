import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable index badge for numbered detail rows.
class DetailItemIndexBadge extends StatelessWidget {
  final int index;

  const DetailItemIndexBadge({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Item nomor $index',
      child: ExcludeSemantics(
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
