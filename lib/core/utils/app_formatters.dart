import 'package:intl/intl.dart';

import 'log.dart';

/// Centralized app formatters for currency and date output.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _idrCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final NumberFormat _idrNoSymbol = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  static final DateFormat _idShortDate = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _idMonthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _idDayMonth = DateFormat('dd MMM', 'id_ID');
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _idDateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  static String currencyIdr(num value) => _idrCurrency.format(value);
  static String currencyIdrNoSymbol(num value) => _idrNoSymbol.format(value).trim();

  /// Format ISO-like date string to "dd MMM yyyy".
  /// Falls back to the original input when parsing fails.
  static String shortDateId(String rawDate) {
    try {
      return _idShortDate.format(DateTime.parse(rawDate));
    } catch (_) {
      Log.warning('shortDateId parse failed: $rawDate', tag: 'Formatter');
      return rawDate;
    }
  }

  /// Format date as "MMMM yyyy" in Indonesian locale.
  static String monthYearId(DateTime value) => _idMonthYear.format(value);

  /// Format date as "dd MMM" in Indonesian locale.
  static String dayMonthId(DateTime value) => _idDayMonth.format(value);

  /// Format date to API payload format "yyyy-MM-dd".
  static String apiDate(DateTime value) => _apiDate.format(value);

  /// Format ISO-like datetime string to "dd MMM yyyy, HH:mm".
  /// Falls back to the original input when parsing fails.
  static String dateTimeId(String rawDateTime) {
    try {
      return _idDateTime.format(DateTime.parse(rawDateTime));
    } catch (_) {
      Log.warning('dateTimeId parse failed: $rawDateTime', tag: 'Formatter');
      return rawDateTime;
    }
  }

  /// Build date-range label used in filter action buttons.
  static String dateRangeFilterLabel({
    required DateTime? start,
    required DateTime? end,
    DateTime? fallbackDate,
    bool includeEndYear = false,
  }) {
    if (start == null || end == null) {
      return monthYearId(fallbackDate ?? DateTime.now());
    }

    final endLabel = includeEndYear ? _idShortDate.format(end) : dayMonthId(end);
    return '${dayMonthId(start)} - $endLabel';
  }
}
