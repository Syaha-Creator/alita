import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_layout_tokens.dart';

/// Satu baris info kontak (ikon lembut di kiri + teks) — dipakai email & alamat
/// di kartu pelanggan dan pengiriman agar DRY.
class DetailContactInfoLine extends StatelessWidget {
  const DetailContactInfoLine({
    super.key,
    required this.icon,
    required this.text,
    this.maxLines = 8,
    this.iconSize = 14,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final IconData icon;
  final String text;
  final int maxLines;
  final double iconSize;
  final CrossAxisAlignment crossAxisAlignment;

  static const Color _iconColor = AppColors.textTertiary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: _iconColor,
        ),
        const SizedBox(width: AppLayoutTokens.space6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
