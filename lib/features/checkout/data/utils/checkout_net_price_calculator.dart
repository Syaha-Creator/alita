/// Calculates net selling price after cascading discounts.
class CheckoutNetPriceCalculator {
  const CheckoutNetPriceCalculator._();

  static double calculate({
    required double customerPrice,
    required int qty,
    required double discount1,
    required double discount2,
    required double discount3,
    required double discount4,
    bool isBonus = false,
  }) {
    if (isBonus) return 0.0;
    if (customerPrice <= 0) return 0.0;
    if (qty <= 0) return 0.0;

    final d1 = discount1.clamp(0.0, 100.0);
    final d2 = discount2.clamp(0.0, 100.0);
    final d3 = discount3.clamp(0.0, 100.0);
    final d4 = discount4.clamp(0.0, 100.0);

    double net = customerPrice * qty;
    if (d1 > 0) net *= (1 - d1 / 100);
    if (d2 > 0) net *= (1 - d2 / 100);
    if (d3 > 0) net *= (1 - d3 / 100);
    if (d4 > 0) net *= (1 - d4 / 100);

    final rounded = double.parse(net.toStringAsFixed(2));
    return rounded > 0 ? rounded : customerPrice * qty;
  }
}
