import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable index badge for numbered detail rows.
class DetailItemIndexBadge extends StatelessWidget {
  final int index;

  const DetailItemIndexBadge({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
