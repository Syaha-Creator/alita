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

  /// Format string tanggal-waktu ke "dd MMM yyyy, HH:mm" (locale id_ID).
  ///
  /// Menerima:
  /// - ISO 8601 ([DateTime.parse], mis. `2026-04-08T16:23:00`)
  /// - `dd-MM-yyyy HH:mm` / `dd-MM-yyyy HH:mm:ss` (sering dari API kuotasi / approval)
  /// - `dd/MM/yyyy HH:mm` (varian)
  ///
  /// Jika tidak ada yang cocok, mengembalikan teks asli dan mencatat peringatan.
  static String dateTimeId(String rawDateTime) {
    final trimmed = rawDateTime.trim();
    if (trimmed.isEmpty) return rawDateTime;

    final parsed = _tryParseDateTimeLoose(trimmed);
    if (parsed != null) {
      try {
        return _idDateTime.format(parsed);
      } catch (_) {
        Log.warning('dateTimeId format failed: $rawDateTime', tag: 'Formatter');
        return rawDateTime;
      }
    }
    Log.warning('dateTimeId parse failed: $rawDateTime', tag: 'Formatter');
    return rawDateTime;
  }

  static DateTime? _tryParseDateTimeLoose(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {}

    final fallbackFormats = <DateFormat>[
      DateFormat('dd-MM-yyyy HH:mm'),
      DateFormat('dd-MM-yyyy HH:mm:ss'),
      DateFormat('dd/MM/yyyy HH:mm'),
      DateFormat('dd/MM/yyyy HH:mm:ss'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('dd/MM/yyyy'),
    ];
    for (final fmt in fallbackFormats) {
      try {
        return fmt.parse(s);
      } catch (_) {}
    }
    return null;
  }

  /// Title case per kata (pemisah spasi). Berguna setelah [String.toLowerCase]
  /// untuk menormalkan label API yang ALL CAPS.
  ///
  /// Kata yang **tepat tiga huruf** (a–z), atau tiga huruf diikuti **hanya angka**
  /// (mis. `pik`, `pik2`, `idd10`), dipertahankan **ALL CAPS** (`PIK`, `PIK2`).
  static String titleCase(String text) {
    final acronymOrCode = RegExp(r'^[a-z]{3}\d*$');
    return text.split(' ').map((w) {
      if (w.isEmpty) return '';
      final lower = w.toLowerCase();
      if (acronymOrCode.hasMatch(lower)) {
        return lower.toUpperCase();
      }
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).join(' ');
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
