import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget untuk menampilkan baris informasi detail dengan label dan value.
class DetailInfoRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isStrikethrough;
  final bool isBoldValue;
  final Color? valueColor;
  final double titleWidth;

  const DetailInfoRow({
    super.key,
    required this.title,
    required this.value,
    this.isStrikethrough = false,
    this.isBoldValue = false,
    this.valueColor,
    this.titleWidth = 130.0,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: titleWidth,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontSize: 14,
              ),
            ),
          ),
          const Text(
            ": ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                fontFamily: GoogleFonts.montserrat().fontFamily,
                color: valueColor,
                decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
