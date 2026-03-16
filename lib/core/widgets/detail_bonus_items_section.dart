import 'package:flutter/material.dart';

/// Reusable bonus/accessory section for detail pages.
class DetailBonusItemsSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const DetailBonusItemsSection({
    super.key,
    this.title = 'Bonus & Aksesoris',
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(height: 1, color: const Color(0xFFF3F4F6)),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 13,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Colors.grey.shade500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
  }
}
