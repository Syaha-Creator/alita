import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Reusable numeric input formatter with thousands separators.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter({String Function(int value)? format})
      : _format = format ?? NumberFormat('#,###', 'id_ID').format;

  final String Function(int value) _format;

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^\d]'), '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = digitsOnly(newValue.text);
    if (cleaned.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.tryParse(cleaned) ?? 0;
    final formatted = _format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
