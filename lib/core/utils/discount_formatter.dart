/// Utility formatter for discount percentage labels.
class DiscountFormatter {
  DiscountFormatter._();

  /// Converts discount value into compact percentage text.
  ///
  /// Examples:
  /// - `10` -> `10%`
  /// - `10.5` -> `10.5%`
  /// - `10.25` -> `10.25%`
  /// If parsing fails, returns the raw value as-is.
  static String percentLabel(
    dynamic rawValue, {
    bool appendPercentSymbol = true,
  }) {
    final parsed = double.tryParse(rawValue?.toString() ?? '');
    if (parsed == null) {
      final raw = rawValue?.toString() ?? '';
      return appendPercentSymbol && raw.isNotEmpty ? '$raw%' : raw;
    }

    final isWhole = parsed == parsed.truncateToDouble();
    final text = isWhole
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return appendPercentSymbol ? '$text%' : text;
  }
}
