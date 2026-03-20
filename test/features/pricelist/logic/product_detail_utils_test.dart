import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/pricelist/logic/product_detail_utils.dart';
import 'package:alitapricelist/features/pricelist/data/models/item_lookup.dart';

void main() {
  group('ProductDetailUtils.computeDiscountsFromTargetTotal', () {
    test('returns empty when target >= base', () {
      final result = ProductDetailUtils.computeDiscountsFromTargetTotal(
        1000, 1000, [0.3, 0.2],
      );
      expect(result, isEmpty);
    });

    test('returns empty when target is zero', () {
      final result = ProductDetailUtils.computeDiscountsFromTargetTotal(
        0, 1000, [0.3, 0.2],
      );
      expect(result, isEmpty);
    });

    test('returns empty when target is negative', () {
      final result = ProductDetailUtils.computeDiscountsFromTargetTotal(
        -100, 1000, [0.3],
      );
      expect(result, isEmpty);
    });

    test('returns empty when maxLimits is empty', () {
      final result = ProductDetailUtils.computeDiscountsFromTargetTotal(
        800, 1000, [],
      );
      expect(result, isEmpty);
    });

    test('computes single discount correctly', () {
      final result = ProductDetailUtils.computeDiscountsFromTargetTotal(
        800, 1000, [0.5],
      );
      expect(result, hasLength(1));
      expect(result[0], closeTo(0.2, 0.001));
    });

    test('computes multiple discounts with clamping', () {
      final result = ProductDetailUtils.computeDiscountsFromTargetTotal(
        500, 1000, [0.3, 0.5, 0.5],
      );
      expect(result, hasLength(3));
      for (final d in result) {
        expect(d, greaterThanOrEqualTo(0.0));
      }
    });
  });

  group('ProductDetailUtils.calculateCascadingPrice', () {
    test('single discount', () {
      final result = ProductDetailUtils.calculateCascadingPrice(1000, [0.1]);
      expect(result, closeTo(900, 0.01));
    });

    test('multiple discounts cascade', () {
      final result = ProductDetailUtils.calculateCascadingPrice(
        1000, [0.1, 0.2],
      );
      // 1000 * 0.9 = 900, 900 * 0.8 = 720
      expect(result, closeTo(720, 0.01));
    });

    test('zero discount returns original price', () {
      final result = ProductDetailUtils.calculateCascadingPrice(1000, [0.0]);
      expect(result, closeTo(1000, 0.01));
    });

    test('empty discounts returns original price', () {
      final result = ProductDetailUtils.calculateCascadingPrice(1000, []);
      expect(result, closeTo(1000, 0.01));
    });

    test('100% discount results in zero', () {
      final result = ProductDetailUtils.calculateCascadingPrice(1000, [1.0]);
      expect(result, closeTo(0, 0.01));
    });
  });

  group('ProductDetailUtils.lookupKey', () {
    test('generates key from lookup fields', () {
      final lookup = ItemLookup(
        tipe: 'Kasur',
        ukuran: '160x200',
        itemNum: 'SKU001',
        jenisKain: 'Oscar',
        warnaKain: 'Biru',
      );
      expect(
        ProductDetailUtils.lookupKey(lookup),
        'kasur|160x200|sku001|oscar|biru',
      );
    });

    test('handles null kain/warna', () {
      final lookup = ItemLookup(
        tipe: 'Kasur',
        ukuran: '160x200',
        itemNum: 'SKU001',
      );
      expect(
        ProductDetailUtils.lookupKey(lookup),
        'kasur|160x200|sku001||',
      );
    });

    test('returns empty string for null lookup', () {
      expect(ProductDetailUtils.lookupKey(null), '');
    });
  });

  group('ProductDetailUtils.isComponentPresent', () {
    test('returns true for non-empty valid field', () {
      expect(ProductDetailUtils.isComponentPresent('Oscar'), isTrue);
    });

    test('returns false for empty string', () {
      expect(ProductDetailUtils.isComponentPresent(''), isFalse);
    });

    test('returns false for whitespace only', () {
      expect(ProductDetailUtils.isComponentPresent('   '), isFalse);
    });

    test('returns false for "tanpa" prefix', () {
      expect(ProductDetailUtils.isComponentPresent('tanpa divan'), isFalse);
    });

    test('returns false for "Tanpa" (case-insensitive)', () {
      expect(ProductDetailUtils.isComponentPresent('Tanpa Headboard'), isFalse);
    });

    test('returns true for valid component with "tanpa" in middle', () {
      expect(ProductDetailUtils.isComponentPresent('Divan tanpa laci'), isTrue);
    });
  });

  group('ProductDetailUtils.collectMaxLimits', () {
    test('filters out zeros', () {
      expect(
        ProductDetailUtils.collectMaxLimits([0.3, 0.0, 0.2, 0.0, 0.1]),
        [0.3, 0.2, 0.1],
      );
    });

    test('returns empty for all zeros', () {
      expect(ProductDetailUtils.collectMaxLimits([0.0, 0.0, 0.0]), isEmpty);
    });

    test('returns all when none are zero', () {
      expect(
        ProductDetailUtils.collectMaxLimits([0.1, 0.2, 0.3]),
        [0.1, 0.2, 0.3],
      );
    });

    test('handles empty input', () {
      expect(ProductDetailUtils.collectMaxLimits([]), isEmpty);
    });
  });
}
