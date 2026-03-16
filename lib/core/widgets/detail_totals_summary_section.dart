import 'package:flutter/material.dart';

/// Reusable totals summary section for detail product cards.
class DetailTotalsSummarySection extends StatelessWidget {
  final String postageText;
  final String totalText;

  const DetailTotalsSummarySection({
    super.key,
    required this.postageText,
    required this.totalText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 14),
        Container(height: 1, color: const Color(0xFFEEEEEE)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ongkos Kirim',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            Text(
              postageText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Tagihan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
            Text(
              totalText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.pink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
