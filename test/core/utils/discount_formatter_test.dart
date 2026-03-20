import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/discount_formatter.dart';

void main() {
  group('DiscountFormatter.percentLabel', () {
    test('formats whole number', () {
      expect(DiscountFormatter.percentLabel(10), '10%');
    });

    test('formats decimal', () {
      expect(DiscountFormatter.percentLabel(10.5), '10.5%');
    });

    test('strips trailing zeros from decimal', () {
      expect(DiscountFormatter.percentLabel(10.50), '10.5%');
    });

    test('formats two-decimal place value', () {
      expect(DiscountFormatter.percentLabel(10.25), '10.25%');
    });

    test('formats zero', () {
      expect(DiscountFormatter.percentLabel(0), '0%');
    });

    test('handles string input', () {
      expect(DiscountFormatter.percentLabel('15'), '15%');
    });

    test('handles string decimal input', () {
      expect(DiscountFormatter.percentLabel('7.5'), '7.5%');
    });

    test('returns raw value for non-parseable input', () {
      expect(DiscountFormatter.percentLabel('abc'), 'abc%');
    });

    test('handles null input', () {
      expect(DiscountFormatter.percentLabel(null), '');
    });

    test('respects appendPercentSymbol=false', () {
      expect(
        DiscountFormatter.percentLabel(10, appendPercentSymbol: false),
        '10',
      );
    });

    test('respects appendPercentSymbol=false for string', () {
      expect(
        DiscountFormatter.percentLabel('abc', appendPercentSymbol: false),
        'abc',
      );
    });

    test('handles empty string', () {
      expect(DiscountFormatter.percentLabel(''), '');
    });
  });
}
