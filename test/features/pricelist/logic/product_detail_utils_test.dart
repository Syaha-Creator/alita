import 'package:alitapricelist/features/pricelist/data/models/item_lookup.dart';
import 'package:alitapricelist/features/pricelist/logic/product_detail_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductDetailUtils.computeDiscountsFromTargetTotal', () {
    test('returns empty when target >= base or target <= 0', () {
      expect(
        ProductDetailUtils.computeDiscountsFromTargetTotal(100, 100, [0.5]),
        isEmpty,
      );
      expect(
        ProductDetailUtils.computeDiscountsFromTargetTotal(0, 100, [0.5]),
        isEmpty,
      );
    });

    test('computes cascading discounts within limits', () {
      final limits = [0.5, 0.5];
      final out = ProductDetailUtils.computeDiscountsFromTargetTotal(
        50,
        100,
        limits,
      );
      expect(out, isNotEmpty);
      expect(out.length, lessThanOrEqualTo(limits.length));
      for (final d in out) {
        expect(d, greaterThanOrEqualTo(0));
        expect(d, lessThanOrEqualTo(0.5));
      }
    });
  });

  group('ProductDetailUtils.calculateCascadingPrice', () {
    test('applies discounts in order', () {
      final p = ProductDetailUtils.calculateCascadingPrice(100, [0.1, 0.2]);
      expect(p, closeTo(72, 0.001));
    });
  });

  group('ProductDetailUtils.lookupKey', () {
    test('empty for null', () {
      expect(ProductDetailUtils.lookupKey(null), '');
    });

    test('joins normalized fields', () {
      final l = ItemLookup(
        tipe: ' Kasur ',
        ukuran: '180',
        itemNum: 'SKU1',
        jenisKain: 'A',
        warnaKain: 'B',
      );
      expect(
        ProductDetailUtils.lookupKey(l),
        'kasur|180|sku1|a|b',
      );
    });
  });

  group('ProductDetailUtils.isComponentPresent', () {
    test('false for empty or tanpa prefix', () {
      expect(ProductDetailUtils.isComponentPresent(''), false);
      expect(ProductDetailUtils.isComponentPresent('Tanpa Divan'), false);
    });

    test('true for real label', () {
      expect(ProductDetailUtils.isComponentPresent('Divan X'), true);
    });
  });

  group('ProductDetailUtils.collectMaxLimits', () {
    test('filters zeros', () {
      expect(
        ProductDetailUtils.collectMaxLimits([0, 0.2, 0, 0.05]),
        [0.2, 0.05],
      );
    });
  });
}
