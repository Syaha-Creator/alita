import 'package:flutter/material.dart';
import 'detail_section_label.dart';

/// Reusable payment section wrapper for detail pages.
class DetailPaymentsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final Widget? header;
  final Widget? footer;

  const DetailPaymentsSection({
    super.key,
    this.title = 'Informasi Pembayaran',
    required this.items,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Pembayaran',
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header ?? DetailSectionLabel(title: title),
        const SizedBox(height: 16),
        ...items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: entry.value,
          );
        }),
        if (footer case final f?) ...[
          const SizedBox(height: 14),
          f,
        ],
      ],
    ),
    );
  }
}
