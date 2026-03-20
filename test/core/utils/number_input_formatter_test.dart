import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/number_input_formatter.dart';

void main() {
  late ThousandsSeparatorInputFormatter formatter;

  setUp(() {
    formatter = ThousandsSeparatorInputFormatter();
  });

  TextEditingValue apply(String text) {
    return formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  group('ThousandsSeparatorInputFormatter', () {
    test('formats thousands with dot separator', () {
      final result = apply('1500000');
      expect(result.text, '1.500.000');
    });

    test('handles empty input', () {
      final result = apply('');
      expect(result.text, '');
      expect(result.selection.baseOffset, 0);
    });

    test('strips non-digit characters', () {
      final result = apply('1.500.000');
      expect(result.text, '1.500.000');
    });

    test('formats small numbers without separator', () {
      final result = apply('500');
      expect(result.text, '500');
    });

    test('cursor is at end of formatted text', () {
      final result = apply('1500000');
      expect(result.selection.baseOffset, result.text.length);
    });
  });

  group('digitsOnly', () {
    test('strips non-digit chars', () {
      expect(ThousandsSeparatorInputFormatter.digitsOnly('1.500.000'), '1500000');
    });

    test('returns empty for non-numeric string', () {
      expect(ThousandsSeparatorInputFormatter.digitsOnly('abc'), '');
    });

    test('handles already clean input', () {
      expect(ThousandsSeparatorInputFormatter.digitsOnly('12345'), '12345');
    });
  });
}
