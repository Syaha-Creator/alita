import 'package:flutter/material.dart';

/// Reusable two-column info row used in detail pages.
///
/// Function:
/// - Menampilkan pasangan `label` dan `value` dalam layout 2 kolom.
/// - Menjaga konsistensi style untuk baris informasi ringkas di halaman detail.
class DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final int labelFlex;
  final int valueFlex;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const DetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelFlex = 4,
    this.valueFlex = 6,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: labelFlex,
          child: Text(
            label,
            style:
                labelStyle ??
                const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ),
        Expanded(
          flex: valueFlex,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style:
                valueStyle ??
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
