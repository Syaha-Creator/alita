import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';

Product _product({double price = 1000, double eupKasur = 0}) => Product(
      id: '1',
      name: 'Test',
      price: price,
      imageUrl: '',
      category: 'C',
      kasur: 'K',
      ukuran: '160x200',
      divan: '',
      headboard: '',
      sorong: '',
      isSet: false,
      pricelist: price,
      eupKasur: eupKasur,
      eupDivan: 0,
      eupHeadboard: 0,
      eupSorong: 0,
      plKasur: price,
      plDivan: 0,
      plHeadboard: 0,
      plSorong: 0,
    );

void main() {
  group('CartItem.unitPriceAfterProgramBulanan', () {
    test('returns base price unchanged when Program Bulanan is not active',
        () {
      final item = CartItem(
        product: _product(price: 1000000),
        indirectStoreAddressNumber: 7,
      );
      expect(item.unitPriceAfterProgramBulanan(1000000), 1000000);
    });

    test('deducts nominal Program Bulanan from the base price', () {
      final item = CartItem(
        product: _product(price: 1000000),
        indirectStoreAddressNumber: 7,
        programBulananType: 'nominal',
        programBulananNominal: 100000,
      );
      expect(item.unitPriceAfterProgramBulanan(1000000), 900000);
    });

    test('deducts percent Program Bulanan from the base price', () {
      final item = CartItem(
        product: _product(price: 1000000),
        indirectStoreAddressNumber: 7,
        programBulananType: 'percent',
        programBulananDiscount: 10,
      );
      expect(item.unitPriceAfterProgramBulanan(1000000), 900000);
    });

    test('does not apply Program Bulanan for direct sales', () {
      final item = CartItem(
        product: _product(price: 1000000),
        programBulananType: 'nominal',
        programBulananNominal: 100000,
      );
      expect(item.unitPriceAfterProgramBulanan(1000000), 1000000);
    });

    test(
        'nominal PB is applied BEFORE diskon tambahan (d1), not after: order '
        'is diskon toko → Program Bulanan → diskon tambahan', () {
      // [base] passed in has already been through the d1 cascade, so the
      // nominal deduction is scaled by the same d1 factor to reproduce the
      // effect of cutting PB before diskon tambahan instead of after.
      final item = CartItem(
        product: _product(price: 1000000),
        indirectStoreAddressNumber: 7,
        discount1: 10,
        programBulananType: 'nominal',
        programBulananNominal: 100000,
      );
      // base − (nominal × salesFactor) = 1_000_000 − (100_000 × 0.9) = 910_000.
      expect(item.unitPriceAfterProgramBulanan(1000000), 910000);
    });

    test('percent PB is unaffected by diskon tambahan ordering (commutative)',
        () {
      final item = CartItem(
        product: _product(price: 1000000),
        indirectStoreAddressNumber: 7,
        discount1: 10,
        programBulananType: 'percent',
        programBulananDiscount: 10,
      );
      expect(item.unitPriceAfterProgramBulanan(1000000), 900000);
    });
  });

  group('CartItem.totalPrice (regular line, non-custom-pricelist)', () {
    test(
        'reflects Program Bulanan reduction so the cart line price matches '
        'the checkout total (regression: PB must be visible on the cart '
        'line, not only in the footer total)', () {
      final item = CartItem(
        product: _product(price: 1000000),
        quantity: 2,
        indirectStoreAddressNumber: 7,
        programBulananType: 'nominal',
        programBulananNominal: 100000,
      );
      expect(item.unitPriceAfterProgramBulanan(item.product.price), 900000);
      expect(item.totalPrice, 1800000);
    });
  });
}
