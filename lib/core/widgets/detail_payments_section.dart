import 'package:flutter/material.dart';

/// Reusable payment section wrapper for detail pages.
class DetailPaymentsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final Widget? header;

  const DetailPaymentsSection({
    super.key,
    this.title = 'Informasi Pembayaran',
    required this.items,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header ??
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
        const SizedBox(height: 14),
        ...items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast) ...[
                const SizedBox(height: 12),
                Container(height: 1, color: const Color(0xFFF3F4F6)),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
      ],
    );
  }
}
