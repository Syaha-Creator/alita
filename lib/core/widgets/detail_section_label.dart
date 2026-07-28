import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable label text for subsection titles in detail pages.
///
/// Menstandarkan gaya label subsection agar konsisten lintas detail screens.
class DetailSectionLabel extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final bool showAccentBar;

  const DetailSectionLabel({
    super.key,
    required this.title,
    this.style,
    this.showAccentBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      title,
      style: style ??
          const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
    );

    if (!showAccentBar) {
      return Semantics(header: true, child: labelText);
    }

    return Semantics(
      header: true,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: labelText),
        ],
      ),
    );
  }
}
