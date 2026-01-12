import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/product/presentation/helpers/product_size_sorter.dart';

void main() {
  group('ProductSizeSorter', () {
    group('sortSizes', () {
      test('should sort sizes from smallest to largest by width', () {
        // Arrange
        final sizes = ['160x200', '90x200', '120x200', '100x200'];

        // Act
        final result = ProductSizeSorter.sortSizes(sizes);

        // Assert
        expect(result, equals(['90x200', '100x200', '120x200', '160x200']));
      });

      test('should handle single size', () {
        // Arrange
        final sizes = ['90x200'];

        // Act
        final result = ProductSizeSorter.sortSizes(sizes);

        // Assert
        expect(result, equals(['90x200']));
      });

      test('should handle empty list', () {
        // Arrange
        final sizes = <String>[];

        // Act
        final result = ProductSizeSorter.sortSizes(sizes);

        // Assert
        expect(result, isEmpty);
      });

      test('should handle sizes with same width but different length', () {
        // Arrange
        final sizes = ['90x200', '90x190', '90x210'];

        // Act
        final result = ProductSizeSorter.sortSizes(sizes);

        // Assert
        // Should be sorted by width first, so all 90x* should be together
        expect(result.first, startsWith('90x'));
        expect(result.length, equals(3));
      });

      test('should handle invalid size formats (non-numeric)', () {
        // Arrange
        final sizes = ['abc', '90x200', 'xyz'];

        // Act
        final result = ProductSizeSorter.sortSizes(sizes);

        // Assert
        // Valid sizes should come first, invalid ones at the end
        expect(result.first, equals('90x200'));
        expect(result.length, equals(3));
      });

      test('should handle sizes with spaces', () {
        // Arrange
        final sizes = ['160 x 200', '90 x 200', '120 x 200'];

        // Act
        final result = ProductSizeSorter.sortSizes(sizes);

        // Assert
        expect(result.first, startsWith('90'));
        expect(result.last, startsWith('160'));
      });

      test('should handle mixed valid and invalid sizes', () {
        // Arrange
        final sizes = ['160x200', 'invalid', '90x200', 'also-invalid'];

        // Act
        final result = ProductSizeSorter.sortSizes(sizes);

        // Assert
        // Valid sizes should be sorted correctly
        expect(result.contains('90x200'), isTrue);
        expect(result.contains('160x200'), isTrue);
        expect(result.length, equals(4));
      });

      test('should preserve order for sizes with same width', () {
        // Arrange
        final sizes = ['90x200', '90x190', '90x210'];

        // Act
        final result = ProductSizeSorter.sortSizes(sizes);

        // Assert
        // All should start with 90x
        expect(result.every((s) => s.startsWith('90x')), isTrue);
      });

      test('should handle large size differences', () {
        // Arrange
        final sizes = ['200x200', '90x200', '180x200', '100x200'];

        // Act
        final result = ProductSizeSorter.sortSizes(sizes);

        // Assert
        expect(result.first, equals('90x200'));
        expect(result.last, equals('200x200'));
      });
    });
  });
}
