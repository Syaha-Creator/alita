import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/checkout/data/utils/checkout_net_price_calculator.dart';

void main() {
  group('CheckoutNetPriceCalculator.calculate', () {
    test('basic calculation without discounts', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 1000,
        qty: 2,
        discount1: 0,
        discount2: 0,
        discount3: 0,
        discount4: 0,
      );
      expect(result, 2000.0);
    });

    test('single discount applied', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 1000,
        qty: 1,
        discount1: 10,
        discount2: 0,
        discount3: 0,
        discount4: 0,
      );
      expect(result, 900.0);
    });

    test('cascading discounts applied correctly', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 1000,
        qty: 1,
        discount1: 10,
        discount2: 20,
        discount3: 0,
        discount4: 0,
      );
      // 1000 * 0.9 = 900, 900 * 0.8 = 720
      expect(result, 720.0);
    });

    test('all four discounts cascade', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 10000,
        qty: 1,
        discount1: 10,
        discount2: 5,
        discount3: 2,
        discount4: 1,
      );
      // 10000 * 0.9 * 0.95 * 0.98 * 0.99 = 8295.21
      expect(result, closeTo(8295.21, 0.01));
    });

    test('returns 0 for bonus items', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 1000,
        qty: 5,
        discount1: 10,
        discount2: 0,
        discount3: 0,
        discount4: 0,
        isBonus: true,
      );
      expect(result, 0.0);
    });

    test('returns 0 for zero price', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 0,
        qty: 5,
        discount1: 10,
        discount2: 0,
        discount3: 0,
        discount4: 0,
      );
      expect(result, 0.0);
    });

    test('returns 0 for negative price', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: -100,
        qty: 1,
        discount1: 0,
        discount2: 0,
        discount3: 0,
        discount4: 0,
      );
      expect(result, 0.0);
    });

    test('returns 0 for zero quantity', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 1000,
        qty: 0,
        discount1: 10,
        discount2: 0,
        discount3: 0,
        discount4: 0,
      );
      expect(result, 0.0);
    });

    test('returns 0 for negative quantity', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 1000,
        qty: -1,
        discount1: 0,
        discount2: 0,
        discount3: 0,
        discount4: 0,
      );
      expect(result, 0.0);
    });

    test('clamps discount above 100 to 100', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 1000,
        qty: 1,
        discount1: 150,
        discount2: 0,
        discount3: 0,
        discount4: 0,
      );
      // 100% discount → 0, fallback to base = 1000
      expect(result, 1000.0);
    });

    test('clamps negative discount to 0', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 1000,
        qty: 1,
        discount1: -10,
        discount2: 0,
        discount3: 0,
        discount4: 0,
      );
      expect(result, 1000.0);
    });

    test('quantity multiplies base before discount', () {
      final result = CheckoutNetPriceCalculator.calculate(
        customerPrice: 500,
        qty: 3,
        discount1: 10,
        discount2: 0,
        discount3: 0,
        discount4: 0,
      );
      // 500 * 3 = 1500, 1500 * 0.9 = 1350
      expect(result, 1350.0);
    });
  });
}
