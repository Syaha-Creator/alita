import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../data/utils/checkout_address_lines.dart';

/// Alamat line 1 + 2 (wajib) dan line 3 opsional via tombol +.
class CheckoutAddressLineFields extends StatelessWidget {
  const CheckoutAddressLineFields({
    super.key,
    required this.sectionLabel,
    required this.line1Ctrl,
    required this.line2Ctrl,
    required this.line3Ctrl,
    required this.showLine3,
    required this.onShowLine3,
    this.line1Label = 'Alamat Line 1 *',
    this.line2Label = 'Alamat Line 2 *',
    this.line3Label = 'Alamat Line 3',
    this.line1Required = true,
    this.line2Required = true,
  });

  final String sectionLabel;
  final TextEditingController line1Ctrl;
  final TextEditingController line2Ctrl;
  final TextEditingController line3Ctrl;
  final bool showLine3;
  final VoidCallback onShowLine3;
  final String line1Label;
  final String line2Label;
  final String line3Label;
  final bool line1Required;
  final bool line2Required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(sectionLabel),
        const SizedBox(height: AppLayoutTokens.space8),
        _lineField(
          controller: line1Ctrl,
          label: line1Label,
          isRequired: line1Required,
        ),
        const SizedBox(height: AppLayoutTokens.space12),
        _lineField(
          controller: line2Ctrl,
          label: line2Label,
          isRequired: line2Required,
        ),
        if (showLine3) ...[
          const SizedBox(height: AppLayoutTokens.space12),
          _lineField(
            controller: line3Ctrl,
            label: line3Label,
            isRequired: false,
          ),
        ] else ...[
          const SizedBox(height: AppLayoutTokens.space8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onShowLine3,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Alamat Line 3'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayoutTokens.space8,
                  vertical: AppLayoutTokens.space4,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _lineField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
  }) {
    const maxLen = CheckoutAddressLines.maxLineLength;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.streetAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 14),
      maxLength: maxLen,
      inputFormatters: [
        LengthLimitingTextInputFormatter(maxLen),
      ],
      validator: (value) {
        final text = value?.trim() ?? '';
        if (isRequired && text.isEmpty) {
          return 'Field ini wajib diisi';
        }
        if (text.length > maxLen) {
          return 'Maksimal $maxLen karakter';
        }
        return null;
      },
      decoration: CheckoutInputDecoration.form(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ).copyWith(counterText: ''),
    );
  }
}
