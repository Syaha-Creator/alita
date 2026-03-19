import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout_tokens.dart';

/// Reusable section header for detail cards.
///
/// Function:
/// - Menjaga konsistensi tampilan judul section (icon + title).
/// - Mengurangi duplikasi header section di halaman detail.
class DetailSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  const DetailSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.padding = const EdgeInsets.only(bottom: AppLayoutTokens.space12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppLayoutTokens.space8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
