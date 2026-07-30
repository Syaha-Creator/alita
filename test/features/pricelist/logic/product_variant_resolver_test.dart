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
      'never offers a headboard that only exists bundled inside a full-SET '
      'row (a combination above the anchor) as a "Beli Set" option for a '
      'standalone divan — falls back to "Tanpa Headboard" instead',
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
        // mattress — a combination *above* the divan anchor. This must NOT
        // leak into the standalone divan's available options or pricing.
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

        expect(
          result.availableHeadboards,
          ['Tanpa Headboard'],
          reason: 'Matrix only exists bundled with a real mattress, so it is '
              'not a valid below-anchor option for the standalone divan.',
        );
        expect(result.effectiveHeadboard, 'Tanpa Headboard');
        expect(result.activeProduct.kasur.trim().toLowerCase(), 'tanpa kasur');
        expect(result.activeProduct.headboard, 'Tanpa Headboard');
        expect(
          result.hasSetOptions,
          false,
          reason: '"Beli Set" must not be offered when no headboard exists '
              'below the divan anchor without a mattress attached.',
        );
      },
    );

    test(
      'offers a headboard as a "Beli Set" option when a genuine below-anchor '
      'row exists (same divan, still no kasur attached)',
      () {
        final masterProduct = _p(
          kasur: 'Tanpa Kasur',
          divan: 'Superfit',
          headboard: 'Tanpa Headboard',
          sorong: 'Tanpa Sorong',
        );
        final divanWithHeadboardNoKasur = _p(
          kasur: 'Tanpa Kasur',
          divan: 'Superfit',
          headboard: 'Matrix',
          sorong: 'Tanpa Sorong',
        );

        final result = ProductVariantResolver.resolve(
          masterProduct: masterProduct,
          rawProducts: [masterProduct, divanWithHeadboardNoKasur],
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
        expect(result.activeProduct.eupHeadboard, 200_000);
        expect(result.hasSetOptions, true);
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
