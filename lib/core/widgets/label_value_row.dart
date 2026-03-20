import 'package:flutter/material.dart';

/// Reusable single-line row to show label on left and value on right.
///
/// Function:
/// - Menyatukan pola `label : value` yang sering dipakai di summary/footer.
/// - Menjaga spacing dan alignment konsisten untuk teks total/subtotal.
/// - Mendukung style custom tanpa deklarasi ulang `Row + Text` berulang.
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
