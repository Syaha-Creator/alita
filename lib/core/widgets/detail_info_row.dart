import 'package:flutter/material.dart';

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const Text(
            ": ",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isBoldValue ? FontWeight.bold : FontWeight.normal,
                    color: valueColor,
                    decoration:
                        isStrikethrough ? TextDecoration.lineThrough : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
