import 'package:flutter/services.dart';
import '../../../../../core/utils/format_helper.dart';

/// Formatter untuk input currency dengan format Rupiah
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus semua karakter non-digit
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Konversi ke double dan format
    double value = double.parse(cleaned);
    String formatted = "Rp ${FormatHelper.formatCurrency(value)}";

    // Hitung posisi cursor yang benar
    int cursorPosition = formatted.length;
    if (newValue.selection.baseOffset < newValue.text.length) {
      // Jika user mengetik di tengah, coba pertahankan posisi relatif
      int oldLength = oldValue.text.length;
      int newLength = formatted.length;
      int oldCursor = newValue.selection.baseOffset;

      if (oldLength > 0) {
        double ratio = oldCursor / oldLength;
        cursorPosition = (ratio * newLength).round();
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

