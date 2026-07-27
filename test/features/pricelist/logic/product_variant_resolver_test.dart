import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/pricelist/logic/product_variant_resolver.dart';
import 'package:alitapricelist/features/pricelist/presentation/widgets/product_anchor_type.dart';
import 'package:flutter_test/flutter_test.dart';

Product _p({
  required String kasur,
  required String divan,
  required String headboard,
  required String sorong,
  String ukuran = '160x200',
  bool isSet = false,
}) {
  return Product(
    id: '$kasur|$divan|$headboard|$sorong|$ukuran',
    name: divan,
    price: 1_000,
    imageUrl: 'https://example.com/i.png',
    category: 'c',
    channel: 'ch',
    brand: 'b',
    kasur: kasur,
    ukuran: ukuran,
    divan: divan,
    headboard: headboard,
    sorong: sorong,
    isSet: isSet,
    pricelist: 1_000,
    eupKasur: kasur.toLowerCase().contains('tanpa') ? 0 : 3_000_000,
    eupDivan: 500_000,
    eupHeadboard: 200_000,
    eupSorong: 0,
    plKasur: kasur.toLowerCase().contains('tanpa') ? 0 : 3_500_000,
    plDivan: 600_000,
    plHeadboard: 250_000,
    plSorong: 0,
  );
}

void main() {
  group('ProductVariantResolver.resolve — divan anchor kasur leak (regression)', () {
    test(
      'never selects a full-SET row as activeProduct when the only catalog '
      'row offering the chosen headboard bundles a real mattress — the '
      'resolved product must stay "Tanpa Kasur" (divan+headboard only)',
      () {
        final masterProduct = _p(
          kasur: 'Tanpa Kasur',
          divan: 'Superfit',
          headboard: 'Tanpa Headboard',
          sorong: 'Tanpa Sorong',
        );
        // Divan-only companion for the default "Tanpa Headboard" state.
        final divanOnly = _p(
          kasur: 'Tanpa Kasur',
          divan: 'Superfit',
          headboard: 'Tanpa Headboard',
          sorong: 'Tanpa Sorong',
        );
        // The only row in the catalog offering headboard "Matrix" alongside
        // divan "Superfit" is a full SET row that also carries a real
        // mattress. This must NOT leak into the resolved activeProduct.
        final fullSetWithMatrix = _p(
          kasur: 'Bulan Purnama',
          divan: 'Superfit',
          headboard: 'Matrix',
          sorong: 'Tanpa Sorong',
          isSet: true,
        );

        final result = ProductVariantResolver.resolve(
          masterProduct: masterProduct,
          rawProducts: [masterProduct, divanOnly, fullSetWithMatrix],
          anchor: AnchorType.divan,
          isKasurOnly: false,
          selectedSize: '160x200',
          selectedDivan: 'Superfit',
          selectedHeadboard: 'Matrix',
          selectedSorong: null,
          selectedKasurLookup: null,
          selectedDivanLookup: null,
          selectedHeadboardLookup: null,
          selectedSorongLookup: null,
          isKasurCustom: false,
          isDivanCustom: false,
          isHeadboardCustom: false,
          isSorongCustom: false,
          groupedLookups: const {},
        );

        expect(result.effectiveHeadboard, 'Matrix');
        expect(
          result.activeProduct.kasur.trim().toLowerCase(),
          'tanpa kasur',
          reason: 'A divan-anchor selection must never resolve to a product '
              'row that carries a real mattress, even if that is the only '
              'catalog row exposing the chosen headboard.',
        );
        // Headboard pricing must still come through even though the source
        // row was a full SET — only the mattress leak is stripped.
        expect(result.activeProduct.eupHeadboard, 200_000);
      },
    );

    test('kasur anchor keeps the real mattress name (no stripping)', () {
      final masterProduct = _p(
        kasur: 'Bulan Purnama',
        divan: 'Tanpa Divan',
        headboard: 'Tanpa Headboard',
        sorong: 'Tanpa Sorong',
      );

      final result = ProductVariantResolver.resolve(
        masterProduct: masterProduct,
        rawProducts: [masterProduct],
        anchor: AnchorType.kasur,
        isKasurOnly: true,
        selectedSize: '160x200',
        selectedDivan: null,
        selectedHeadboard: null,
        selectedSorong: null,
        selectedKasurLookup: null,
        selectedDivanLookup: null,
        selectedHeadboardLookup: null,
        selectedSorongLookup: null,
        isKasurCustom: false,
        isDivanCustom: false,
        isHeadboardCustom: false,
        isSorongCustom: false,
        groupedLookups: const {},
      );

      expect(result.activeProduct.kasur, 'Bulan Purnama');
    });
  });
}
