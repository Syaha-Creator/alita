import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Label-left / pill-value-right row for detail header cards.
///
/// Unifies rows like "Tanggal Pesanan", "Permintaan Kirim", and
/// "Lokasi / Toko" under one pill shape instead of mixing plain text
/// (`DetailInfoRow`) with ad-hoc `Container` pills.
class DetailInfoPillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;

  const DetailInfoPillRow({
    super.key,
    required this.label,
    required this.value,
    this.backgroundColor = AppColors.surfaceLight,
    this.foregroundColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
