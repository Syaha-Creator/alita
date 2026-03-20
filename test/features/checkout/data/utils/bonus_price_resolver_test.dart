import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/checkout/data/utils/bonus_price_resolver.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';

Product _makeProduct({
  String? bonus1,
  double? plBonus1,
  String? bonus2,
  double? plBonus2,
  String? bonus3,
  double? plBonus3,
  String? bonus4,
  double? plBonus4,
  String? bonus5,
  double? plBonus5,
  String? bonus6,
  double? plBonus6,
  String? bonus7,
  double? plBonus7,
  String? bonus8,
  double? plBonus8,
}) {
  return Product(
    id: 'test-id',
    name: 'Test Product',
    price: 1000,
    imageUrl: '',
    category: 'Test',
    kasur: 'Kasur A',
    ukuran: '160x200',
    divan: '',
    headboard: '',
    sorong: '',
    isSet: false,
    pricelist: 1000,
    eupKasur: 1000,
    eupDivan: 0,
    eupHeadboard: 0,
    eupSorong: 0,
    plKasur: 1000,
    plDivan: 0,
    plHeadboard: 0,
    plSorong: 0,
    bonus1: bonus1,
    plBonus1: plBonus1,
    bonus2: bonus2,
    plBonus2: plBonus2,
    bonus3: bonus3,
    plBonus3: plBonus3,
    bonus4: bonus4,
    plBonus4: plBonus4,
    bonus5: bonus5,
    plBonus5: plBonus5,
    bonus6: bonus6,
    plBonus6: plBonus6,
    bonus7: bonus7,
    plBonus7: plBonus7,
    bonus8: bonus8,
    plBonus8: plBonus8,
  );
}

void main() {
  group('BonusPriceResolver.resolvePlPrice', () {
    test('matches bonus1', () {
      final product = _makeProduct(bonus1: 'Bantal', plBonus1: 50000);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Bantal'), 50000);
    });

    test('matches bonus2', () {
      final product = _makeProduct(bonus2: 'Guling', plBonus2: 30000);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Guling'), 30000);
    });

    test('matches bonus3', () {
      final product = _makeProduct(bonus3: 'Selimut', plBonus3: 75000);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Selimut'), 75000);
    });

    test('matches bonus4', () {
      final product = _makeProduct(bonus4: 'Sprei', plBonus4: 40000);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Sprei'), 40000);
    });

    test('matches bonus5', () {
      final product = _makeProduct(bonus5: 'Topper', plBonus5: 100000);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Topper'), 100000);
    });

    test('matches bonus6', () {
      final product = _makeProduct(bonus6: 'Bed Cover', plBonus6: 120000);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Bed Cover'), 120000);
    });

    test('matches bonus7', () {
      final product = _makeProduct(bonus7: 'Sarung', plBonus7: 25000);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Sarung'), 25000);
    });

    test('matches bonus8', () {
      final product = _makeProduct(bonus8: 'Protector', plBonus8: 60000);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Protector'), 60000);
    });

    test('returns 0 when no match found', () {
      final product = _makeProduct(bonus1: 'Bantal', plBonus1: 50000);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Guling'), 0.0);
    });

    test('returns 0 when all bonuses are null', () {
      final product = _makeProduct();
      expect(BonusPriceResolver.resolvePlPrice(product, 'Bantal'), 0.0);
    });

    test('returns 0 when bonus name matches but price is null', () {
      final product = _makeProduct(bonus1: 'Bantal', plBonus1: null);
      expect(BonusPriceResolver.resolvePlPrice(product, 'Bantal'), 0.0);
    });

    test('matches first occurrence when multiple bonuses have same name', () {
      final product = _makeProduct(
        bonus1: 'Bantal',
        plBonus1: 50000,
        bonus3: 'Bantal',
        plBonus3: 75000,
      );
      expect(BonusPriceResolver.resolvePlPrice(product, 'Bantal'), 50000);
    });
  });
}
