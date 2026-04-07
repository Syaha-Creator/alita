import 'package:alitapricelist/features/pricelist/logic/indirect_catalog_filter_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IndirectCatalogFilterUtils', () {
    test('filterTokoChannels keeps only names containing toko', () {
      expect(
        IndirectCatalogFilterUtils.filterTokoChannels([
          'Direct',
          'Toko Mitra',
          'Wholesale',
        ]),
        ['Toko Mitra'],
      );
    });

    test('pickDefaultTokoChannel prefers exact Toko', () {
      expect(
        IndirectCatalogFilterUtils.pickDefaultTokoChannel([
          'Toko Cabang',
          'Toko',
          'Mini Toko',
        ]),
        'Toko',
      );
    });

    test('brandNamesForChannel matches store code to hyphenated catcode (SA → SA-REG)', () {
      final channels = <Map<String, dynamic>>[
        {'id': 10, 'channel': 'Toko'},
      ];
      final brands = <Map<String, dynamic>>[
        {
          'brand': 'Other',
          'pl_channel_id': 10,
          'catcode_27': 'XX',
        },
        {
          'brand': 'Spring Line',
          'pl_channel_id': 10,
          'catcode_27': 'SA-REG',
        },
      ];
      final names = IndirectCatalogFilterUtils.brandNamesForChannel(
        channels,
        brands,
        'Toko',
        catcode27: 'SA',
      );
      expect(names, ['Spring Line']);
    });

    test('brandNamesForChannel narrows by catcode_27 on brand row', () {
      final channels = <Map<String, dynamic>>[
        {'id': 10, 'channel': 'Toko'},
      ];
      final brands = <Map<String, dynamic>>[
        {
          'brand': 'Alita',
          'pl_channel_id': 10,
          'catcode_27': 'XX',
        },
        {
          'brand': 'Comforta',
          'pl_channel_id': 10,
          'catcode_27': 'SA',
        },
      ];
      final names = IndirectCatalogFilterUtils.brandNamesForChannel(
        channels,
        brands,
        'Toko',
        catcode27: 'SA',
      );
      expect(names, ['Comforta']);
    });

    test(
        'brandNamesForChannel returns empty when catcode set but no brand aligns',
        () {
      final channels = <Map<String, dynamic>>[
        {'id': 10, 'channel': 'Toko'},
      ];
      final brands = <Map<String, dynamic>>[
        {'brand': 'Alita', 'pl_channel_id': 10},
      ];
      final unknownCode = IndirectCatalogFilterUtils.brandNamesForChannel(
        channels,
        brands,
        'Toko',
        catcode27: 'ZZ',
      );
      expect(unknownCode, isEmpty);

      final saNoRows = IndirectCatalogFilterUtils.brandNamesForChannel(
        channels,
        brands,
        'Toko',
        catcode27: 'SA',
      );
      expect(saNoRows, isEmpty);
    });

    test(
        'brandNamesForChannel uses catcode hints when brand rows lack catcode fields',
        () {
      final channels = <Map<String, dynamic>>[
        {'id': 10, 'channel': 'Toko'},
      ];
      final brands = <Map<String, dynamic>>[
        {'brand': 'Comforta', 'pl_channel_id': 10},
        {
          'brand': 'Spring Air - American Classic',
          'pl_channel_id': 10,
        },
      ];
      final names = IndirectCatalogFilterUtils.brandNamesForChannel(
        channels,
        brands,
        'Toko',
        catcode27: 'SA',
      );
      expect(names, ['Spring Air - American Classic']);
    });

    test('brandNamesForChannel SF is Superfit only, not Sleep Spa', () {
      final channels = <Map<String, dynamic>>[
        {'id': 10, 'channel': 'Toko'},
      ];
      final brands = <Map<String, dynamic>>[
        {'brand': 'Sleep Spa Line', 'pl_channel_id': 10},
        {'brand': 'Superfit Collection', 'pl_channel_id': 10},
      ];
      final names = IndirectCatalogFilterUtils.brandNamesForChannel(
        channels,
        brands,
        'Toko',
        catcode27: 'SF',
      );
      expect(names, ['Superfit Collection']);
    });
  });
}
