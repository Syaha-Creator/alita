import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/product/domain/entities/product_entity.dart';
import 'package:alitapricelist/features/product/presentation/helpers/product_price_calculator.dart';

/// Helper function untuk membuat ProductEntity untuk testing
ProductEntity _createTestProduct({
  int id = 1,
  String area = 'Test Area',
  String channel = 'Test Channel',
  String brand = 'Test Brand',
  String kasur = 'Test Kasur',
  String divan = '',
  String headboard = '',
  String sorong = '',
  String ukuran = '90x200',
  double pricelist = 1000000,
  String program = 'Regular',
  double eupKasur = 0,
  double eupDivan = 0,
  double eupHeadboard = 0,
  double endUserPrice = 1000000,
  List<BonusItem>? bonus,
  List<double>? discounts,
  bool isSet = false,
  double plKasur = 0,
  double plDivan = 0,
  double plHeadboard = 0,
  double plSorong = 0,
  double eupSorong = 0,
  double bottomPriceAnalyst = 800000,
  double disc1 = 0.1,
  double disc2 = 0.05,
  double disc3 = 0.03,
  double disc4 = 0.02,
  double disc5 = 0.01,
}) {
  return ProductEntity(
    id: id,
    area: area,
    channel: channel,
    brand: brand,
    kasur: kasur,
    divan: divan,
    headboard: headboard,
    sorong: sorong,
    ukuran: ukuran,
    pricelist: pricelist,
    program: program,
    eupKasur: eupKasur,
    eupDivan: eupDivan,
    eupHeadboard: eupHeadboard,
    endUserPrice: endUserPrice,
    bonus: bonus ?? const [],
    discounts: discounts ?? const [],
    isSet: isSet,
    plKasur: plKasur,
    plDivan: plDivan,
    plHeadboard: plHeadboard,
    plSorong: plSorong,
    eupSorong: eupSorong,
    bottomPriceAnalyst: bottomPriceAnalyst,
    disc1: disc1,
    disc2: disc2,
    disc3: disc3,
    disc4: disc4,
    disc5: disc5,
  );
}

void main() {
  group('ProductPriceCalculator', () {
    group('calculateSplitDiscounts', () {
      test('should calculate discounts correctly for simple case', () {
        // Arrange
        final product = _createTestProduct(
          endUserPrice: 1000000,
          bottomPriceAnalyst: 800000,
          disc1: 0.1, // 10%
          disc2: 0.05, // 5%
          disc3: 0.03, // 3%
          disc4: 0.02, // 2%
          disc5: 0.01, // 1%
        );

        // Act
        final result = ProductPriceCalculator.calculateSplitDiscounts(
          product,
          900000, // Target price: 900k (10% discount from 1M)
        );

        // Assert
        expect(result['discounts'], isNotNull);
        expect(result['nominals'], isNotNull);
        expect(result['discounts']!.length, equals(5));
        expect(result['nominals']!.length, equals(5));

        // Verify final price is close to target
        double finalPrice = product.endUserPrice;
        for (var discount in result['discounts']!) {
          finalPrice = finalPrice * (1 - discount / 100);
        }
        expect(finalPrice, closeTo(900000, 1000)); // Within 1000 tolerance
      });

      test('should respect bottomPriceAnalyst limit', () {
        // Arrange
        final product = _createTestProduct(
          endUserPrice: 1000000,
          bottomPriceAnalyst: 800000,
        );

        // Act - Try to set price below bottomPriceAnalyst
        final result = ProductPriceCalculator.calculateSplitDiscounts(
          product,
          700000, // Below bottomPriceAnalyst (800k)
        );

        // Assert - Should use bottomPriceAnalyst instead
        double finalPrice = product.endUserPrice;
        for (var discount in result['discounts']!) {
          finalPrice = finalPrice * (1 - discount / 100);
        }
        expect(finalPrice, greaterThanOrEqualTo(800000));
      });

      test('should handle zero discounts correctly', () {
        // Arrange
        final product = _createTestProduct(
          endUserPrice: 1000000,
          bottomPriceAnalyst: 800000,
          disc1: 0.0,
          disc2: 0.0,
          disc3: 0.0,
          disc4: 0.0,
          disc5: 0.0,
        );

        // Act
        final result = ProductPriceCalculator.calculateSplitDiscounts(
          product,
          900000,
        );

        // Assert
        expect(result['discounts']!.every((d) => d == 0), isTrue);
        expect(result['nominals']!.every((n) => n == 0), isTrue);
      });

      test('should handle target price equal to original price', () {
        // Arrange
        final product = _createTestProduct(
          endUserPrice: 1000000,
          bottomPriceAnalyst: 800000,
        );

        // Act
        final result = ProductPriceCalculator.calculateSplitDiscounts(
          product,
          1000000, // Same as original
        );

        // Assert - All discounts should be 0
        expect(result['discounts']!.every((d) => d == 0), isTrue);
      });
    });

    group('calculateFinalPrice', () {
      test('should calculate final price correctly with single discount', () {
        // Arrange
        const originalPrice = 1000000.0;
        const discountPercentages = [10.0]; // 10% discount

        // Act
        final result = ProductPriceCalculator.calculateFinalPrice(
          originalPrice,
          discountPercentages,
        );

        // Assert
        expect(result, equals(900000.0)); // 1M - 10% = 900k
      });

      test('should calculate final price correctly with multiple discounts',
          () {
        // Arrange
        const originalPrice = 1000000.0;
        const discountPercentages = [10.0, 5.0]; // 10% then 5%

        // Act
        final result = ProductPriceCalculator.calculateFinalPrice(
          originalPrice,
          discountPercentages,
        );

        // Assert
        // First discount: 1M * 0.9 = 900k
        // Second discount: 900k * 0.95 = 855k
        expect(result, closeTo(855000.0, 1.0));
      });

      test('should handle zero discounts', () {
        // Arrange
        const originalPrice = 1000000.0;
        const discountPercentages = [0.0, 0.0];

        // Act
        final result = ProductPriceCalculator.calculateFinalPrice(
          originalPrice,
          discountPercentages,
        );

        // Assert
        expect(result, equals(originalPrice));
      });

      test('should handle empty discounts list', () {
        // Arrange
        const originalPrice = 1000000.0;
        const discountPercentages = <double>[];

        // Act
        final result = ProductPriceCalculator.calculateFinalPrice(
          originalPrice,
          discountPercentages,
        );

        // Assert
        expect(result, equals(originalPrice));
      });

      test('should clamp result to not exceed original price', () {
        // Arrange
        const originalPrice = 1000000.0;
        const discountPercentages = [
          -10.0
        ]; // Negative discount (should not happen but test edge case)

        // Act
        final result = ProductPriceCalculator.calculateFinalPrice(
          originalPrice,
          discountPercentages,
        );

        // Assert
        expect(result, lessThanOrEqualTo(originalPrice));
      });

      test('should clamp result to not be negative', () {
        // Arrange
        const originalPrice = 1000000.0;
        const discountPercentages = [150.0]; // More than 100% discount

        // Act
        final result = ProductPriceCalculator.calculateFinalPrice(
          originalPrice,
          discountPercentages,
        );

        // Assert
        expect(result, greaterThanOrEqualTo(0.0));
      });
    });
  });
}
