import 'package:flutter/material.dart';

/// Reusable note card for detail pages.
class DetailNoteCard extends StatelessWidget {
  final String title;
  final String note;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color titleColor;
  final TextStyle? titleStyle;
  final TextStyle? noteStyle;

  const DetailNoteCard({
    super.key,
    this.title = 'Catatan Pesanan',
    required this.note,
    this.borderRadius = 12,
    this.backgroundColor = const Color(0xFFFFFBEB),
    this.borderColor = const Color(0xFFFFE082),
    this.iconColor = const Color(0xFFFF8F00),
    this.titleColor = const Color(0xFFFF8F00),
    this.titleStyle,
    this.noteStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      titleStyle ??
                      TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style:
                      noteStyle ??
                      const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5D4037),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
