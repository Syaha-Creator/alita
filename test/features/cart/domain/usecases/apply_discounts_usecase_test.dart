import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/cart/domain/usecases/apply_discounts_usecase.dart';

void main() {
  group('ApplyDiscountsUsecase', () {
    late ApplyDiscountsUsecase useCase;

    setUp(() {
      useCase = const ApplyDiscountsUsecase();
    });

    test('should apply single discount correctly', () {
      // Arrange
      const basePrice = 1000000.0;
      const discountPercentages = [10.0]; // 10% discount

      // Act
      final result = useCase.applySequentially(basePrice, discountPercentages);

      // Assert
      expect(result, equals(900000.0)); // 1M - 10% = 900k
    });

    test('should apply multiple discounts sequentially', () {
      // Arrange
      const basePrice = 1000000.0;
      const discountPercentages = [10.0, 5.0]; // 10% then 5%

      // Act
      final result = useCase.applySequentially(basePrice, discountPercentages);

      // Assert
      // First discount: 1M * 0.9 = 900k
      // Second discount: 900k * 0.95 = 855k
      expect(result, closeTo(855000.0, 1.0));
    });

    test('should handle zero discounts', () {
      // Arrange
      const basePrice = 1000000.0;
      const discountPercentages = [0.0, 0.0];

      // Act
      final result = useCase.applySequentially(basePrice, discountPercentages);

      // Assert
      expect(result, equals(basePrice));
    });

    test('should skip negative discounts', () {
      // Arrange
      const basePrice = 1000000.0;
      const discountPercentages = [
        10.0,
        -5.0,
        5.0
      ]; // Negative discount should be skipped

      // Act
      final result = useCase.applySequentially(basePrice, discountPercentages);

      // Assert
      // First discount: 1M * 0.9 = 900k
      // Second discount: -5% (skipped)
      // Third discount: 900k * 0.95 = 855k
      expect(result, closeTo(855000.0, 1.0));
    });

    test('should handle empty discounts list', () {
      // Arrange
      const basePrice = 1000000.0;
      const discountPercentages = <double>[];

      // Act
      final result = useCase.applySequentially(basePrice, discountPercentages);

      // Assert
      expect(result, equals(basePrice));
    });

    test('should not result in negative price', () {
      // Arrange
      const basePrice = 1000000.0;
      const discountPercentages = [150.0]; // More than 100% discount

      // Act
      final result = useCase.applySequentially(basePrice, discountPercentages);

      // Assert
      expect(result, greaterThanOrEqualTo(0.0));
    });

    test('should handle large number of discounts', () {
      // Arrange
      const basePrice = 1000000.0;
      const discountPercentages = [
        5.0,
        5.0,
        5.0,
        5.0,
        5.0
      ]; // 5 discounts of 5% each

      // Act
      final result = useCase.applySequentially(basePrice, discountPercentages);

      // Assert
      // Each 5% discount reduces price by 5%
      // Result should be less than original price
      expect(result, lessThan(basePrice));
      expect(result, greaterThan(0.0));
    });

    test('should handle very small base price', () {
      // Arrange
      const basePrice = 100.0;
      const discountPercentages = [10.0];

      // Act
      final result = useCase.applySequentially(basePrice, discountPercentages);

      // Assert
      expect(result, equals(90.0));
    });
  });
}
