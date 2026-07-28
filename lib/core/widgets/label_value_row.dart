import 'package:flutter/material.dart';

/// Reusable single-line row to show label on left and value on right.
///
/// Common pattern for summary/footer rows (e.g. total, subtotal).
class LabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final MainAxisAlignment mainAxisAlignment;

  const LabelValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          Text(label, style: labelStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
