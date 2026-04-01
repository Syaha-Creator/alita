import 'package:alitapricelist/features/pricelist/data/models/item_lookup.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/pricelist/logic/cart_item_builder.dart';
import 'package:flutter_test/flutter_test.dart';

Product _p({
  String kasur = 'Foam X',
  String divan = 'Tanpa Divan',
  String headboard = 'Tanpa Headboard',
  String sorong = 'Tanpa Sorong',
  double price = 1_000,
}) {
  return Product(
    id: '1',
    name: '$kasur 180',
    price: price,
    imageUrl: 'https://example.com/i.png',
    category: 'c',
    description: 'd',
    channel: 'ch',
    brand: 'b',
    kasur: kasur,
    ukuran: '180',
    divan: divan,
    headboard: headboard,
    sorong: sorong,
    isSet: false,
    pricelist: price,
    eupKasur: price,
    eupDivan: 0,
    eupHeadboard: 0,
    eupSorong: 0,
    plKasur: 0,
    plDivan: 0,
    plHeadboard: 0,
    plSorong: 0,
  );
}

void main() {
  group('CartItemBuilder.buildSummaryForToast', () {
    test('returns size when all tanpa', () {
      expect(
        CartItemBuilder.buildSummaryForToast(
          effectiveSize: '180x200',
          effectiveDivan: 'Tanpa Divan',
          effectiveHeadboard: 'Tanpa Headboard',
          effectiveSorong: 'Tanpa Sorong',
        ),
        '180x200',
      );
    });

    test('includes non-tanpa parts', () {
      final s = CartItemBuilder.buildSummaryForToast(
        effectiveSize: '180',
        effectiveDivan: 'Divan A',
        effectiveHeadboard: 'Tanpa Headboard',
        effectiveSorong: 'Tanpa Sorong',
      );
      expect(s, contains('180'));
      expect(s.toLowerCase(), contains('divan a'));
    });
  });

  group('CartItemBuilder.build', () {
    test('kasur-only build carries SKU from lookup', () {
      final active = _p();
      final lookup = ItemLookup(
        tipe: 'kasur',
        ukuran: '180',
        itemNum: 'FAB-001',
        jenisKain: 'Knit',
        warnaKain: 'Grey',
      );

      final item = CartItemBuilder.build(
        activeProduct: active,
        masterProduct: active,
        effectiveSize: '180',
        effectiveDivan: 'Tanpa Divan',
        effectiveHeadboard: 'Tanpa Headboard',
        effectiveSorong: 'Tanpa Sorong',
        totalFinalPrice: 1000,
        finalKasurPrice: 1000,
        finalDivanPrice: 0,
        finalHeadboardPrice: 0,
        finalSorongPrice: 0,
        isKasurOnly: true,
        appliedDiscounts: const [0.1],
        groupedLookups: {'kasur': [lookup]},
        isKasurCustom: false,
        effectiveKasurLookup: lookup,
        customKasurNote: '',
        isDivanCustom: false,
        effectiveDivanLookup: null,
        customDivanNote: '',
        isHeadboardCustom: false,
        effectiveHeadboardLookup: null,
        customHbNote: '',
        isSorongCustom: false,
        effectiveSorongLookup: null,
        customSorongNote: '',
      );

      expect(item.kasurSku, 'FAB-001');
      expect(item.product.price, 1000);
      expect(item.discount1, closeTo(10, 0.01));
    });

    test('applies rounding diff to kasur EUP when totals diverge', () {
      final active = _p(price: 1000);
      final item = CartItemBuilder.build(
        activeProduct: active,
        masterProduct: active,
        effectiveSize: '180',
        effectiveDivan: 'Tanpa Divan',
        effectiveHeadboard: 'Tanpa Headboard',
        effectiveSorong: 'Tanpa Sorong',
        totalFinalPrice: 1005,
        finalKasurPrice: 1000,
        finalDivanPrice: 0,
        finalHeadboardPrice: 0,
        finalSorongPrice: 0,
        isKasurOnly: true,
        appliedDiscounts: const [],
        groupedLookups: const {},
        isKasurCustom: false,
        effectiveKasurLookup: null,
        customKasurNote: '',
        isDivanCustom: false,
        effectiveDivanLookup: null,
        customDivanNote: '',
        isHeadboardCustom: false,
        effectiveHeadboardLookup: null,
        customHbNote: '',
        isSorongCustom: false,
        effectiveSorongLookup: null,
        customSorongNote: '',
      );
      expect(item.product.eupKasur, closeTo(1005, 0.001));
    });

    test('customBonuses resolve SKU via groupedLookups', () {
      final active = _p();
      final bonusLookup = ItemLookup(
        tipe: 'bantal',
        ukuran: '180',
        itemNum: 'BONUS-SKU',
        jenisKain: null,
        warnaKain: null,
      );

      final item = CartItemBuilder.build(
        activeProduct: active,
        masterProduct: active,
        effectiveSize: '180',
        effectiveDivan: 'Tanpa Divan',
        effectiveHeadboard: 'Tanpa Headboard',
        effectiveSorong: 'Tanpa Sorong',
        totalFinalPrice: 1000,
        finalKasurPrice: 1000,
        finalDivanPrice: 0,
        finalHeadboardPrice: 0,
        finalSorongPrice: 0,
        isKasurOnly: true,
        appliedDiscounts: const [],
        groupedLookups: {'bantal': [bonusLookup]},
        isKasurCustom: false,
        effectiveKasurLookup: null,
        customKasurNote: '',
        isDivanCustom: false,
        effectiveDivanLookup: null,
        customDivanNote: '',
        isHeadboardCustom: false,
        effectiveHeadboardLookup: null,
        customHbNote: '',
        isSorongCustom: false,
        effectiveSorongLookup: null,
        customSorongNote: '',
        customBonuses: [
          {'name': 'bantal', 'qty': 2},
        ],
      );

      expect(item.bonusSnapshots, hasLength(1));
      expect(item.bonusSnapshots.single.sku, 'BONUS-SKU');
      expect(item.bonusSnapshots.single.qty, 2);
    });
  });
}
