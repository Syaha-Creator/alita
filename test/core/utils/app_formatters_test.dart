import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:alitapricelist/core/utils/app_formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('currencyIdr', () {
    test('formats positive integer', () {
      expect(AppFormatters.currencyIdr(1500000), 'Rp 1.500.000');
    });

    test('formats zero', () {
      expect(AppFormatters.currencyIdr(0), 'Rp 0');
    });

    test('formats negative value', () {
      expect(AppFormatters.currencyIdr(-250000), contains('-'));
      expect(AppFormatters.currencyIdr(-250000), contains('250.000'));
    });

    test('truncates decimals', () {
      expect(AppFormatters.currencyIdr(1234.56), 'Rp 1.235');
    });
  });

  group('currencyIdrNoSymbol', () {
    test('formats without Rp symbol', () {
      final result = AppFormatters.currencyIdrNoSymbol(1500000);
      expect(result, isNot(contains('Rp')));
      expect(result, contains('1.500.000'));
    });

    test('formats zero', () {
      expect(AppFormatters.currencyIdrNoSymbol(0), '0');
    });
  });

  group('shortDateId', () {
    test('formats valid ISO date', () {
      final result = AppFormatters.shortDateId('2025-03-15');
      expect(result, contains('15'));
      expect(result, contains('Mar'));
      expect(result, contains('2025'));
    });

    test('returns raw input on invalid date', () {
      expect(AppFormatters.shortDateId('not-a-date'), 'not-a-date');
    });

    test('returns empty on empty input', () {
      expect(AppFormatters.shortDateId(''), '');
    });
  });

  group('dateTimeId', () {
    test('formats valid ISO datetime', () {
      final result = AppFormatters.dateTimeId('2025-03-15T14:30:00');
      expect(result, contains('15'));
      expect(result, contains('14:30'));
    });

    test('parses dd-MM-yyyy HH:mm from API / quotation requestDate', () {
      final result = AppFormatters.dateTimeId('08-04-2026 16:23');
      expect(result, contains('2026'));
      expect(result, contains('16:23'));
    });

    test('returns raw input on invalid datetime', () {
      expect(AppFormatters.dateTimeId('invalid'), 'invalid');
    });
  });

  group('apiDate', () {
    test('formats to yyyy-MM-dd', () {
      final date = DateTime(2025, 3, 15);
      expect(AppFormatters.apiDate(date), '2025-03-15');
    });

    test('pads single-digit month and day', () {
      final date = DateTime(2025, 1, 5);
      expect(AppFormatters.apiDate(date), '2025-01-05');
    });
  });

  group('monthYearId', () {
    test('formats date to Indonesian month year', () {
      final date = DateTime(2025, 3, 15);
      final result = AppFormatters.monthYearId(date);
      expect(result, contains('2025'));
    });
  });

  group('dayMonthId', () {
    test('formats date to dd MMM', () {
      final date = DateTime(2025, 3, 15);
      final result = AppFormatters.dayMonthId(date);
      expect(result, contains('15'));
    });
  });

  group('dateRangeFilterLabel', () {
    test('returns month-year when no range provided', () {
      final fallback = DateTime(2025, 6, 1);
      final result = AppFormatters.dateRangeFilterLabel(
        start: null,
        end: null,
        fallbackDate: fallback,
      );
      expect(result, contains('2025'));
    });

    test('returns range when both dates provided', () {
      final start = DateTime(2025, 3, 1);
      final end = DateTime(2025, 3, 31);
      final result = AppFormatters.dateRangeFilterLabel(
        start: start,
        end: end,
      );
      expect(result, contains('-'));
      expect(result, contains('1'));
      expect(result, contains('31'));
    });

    test('includes end year when flag is set', () {
      final start = DateTime(2025, 3, 1);
      final end = DateTime(2025, 12, 31);
      final result = AppFormatters.dateRangeFilterLabel(
        start: start,
        end: end,
        includeEndYear: true,
      );
      expect(result, contains('2025'));
    });
  });
}
