/// Perhitungan diskon toko berjenjang (cascading) pada nilai dasar (biasanya EUP).
class StoreDiscountCalculator {
  StoreDiscountCalculator._();

  /// Terapkan diskon bertingkat: setiap persen mengurangi hasil sebelumnya.
  static double cascade(double base, List<double> discountPercents) {
    if (discountPercents.isEmpty) return base;
    var result = base;
    for (final d in discountPercents) {
      if (d <= 0) continue;
      result *= (1 - d / 100);
    }
    return result;
  }

  /// Total baris (harga per unit × qty).
  static double lineTotal(double unitValue, int qty) => unitValue * qty;

  /// String tampilan: `40% + 10% + 5%`
  static String formatDisplay(List<double> discounts) {
    if (discounts.isEmpty) return '-';
    return discounts.map((d) {
      if (d == d.truncateToDouble()) {
        return '${d.toInt()}%';
      }
      return '${d.toString().replaceAll('.', ',')}%';
    }).join(' + ');
  }
}
