import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable label for form fields (above input, dropdown, date picker, etc.).
///
/// Ensures consistent typography and spacing across checkout, payment, and
/// other forms. Use above input widgets with `SizedBox(height: 8)`.
class FormFieldLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const FormFieldLabel(
    this.text, {
    super.key,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: style ??
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
