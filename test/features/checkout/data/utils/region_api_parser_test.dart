import 'package:alitapricelist/features/checkout/data/utils/region_api_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegionApiParser.parseListBody', () {
    test('parses geo.velrox.cloud {ok,data} envelope with kode/nama/kodepos', () {
      const body = '''
{
  "ok": true,
  "data": [
    {
      "kode": "31.71.01.1001",
      "nama": "Gambir",
      "level": 4,
      "kodepos": "10110"
    }
  ],
  "count": 1
}
''';

      final items = RegionApiParser.parseListBody(body);

      expect(items, hasLength(1));
      expect(items.single.kode, '31.71.01.1001');
      expect(items.single.nama, 'Gambir');
      expect(items.single.kodepos, '10110');
    });

    test('parses cached raw list of normalized maps', () {
      const body = '''
[
  {"kode": "11", "nama": "Aceh"},
  {"kode": "31", "nama": "DKI Jakarta", "kodepos": null}
]
''';

      final items = RegionApiParser.parseListBody(body);

      expect(items.map((e) => e.nama), ['Aceh', 'DKI Jakarta']);
      expect(items[0].kodepos, isNull);
    });

    test('returns empty for invalid JSON or missing data', () {
      expect(RegionApiParser.parseListBody('not-json'), isEmpty);
      expect(RegionApiParser.parseListBody('{"ok":true}'), isEmpty);
      expect(RegionApiParser.parseListBody('{"ok":true,"data":null}'), isEmpty);
    });

    test('skips non-map entries and blank kode/nama', () {
      const body = '''
{
  "ok": true,
  "data": [
    "skip-me",
    {"kode": "", "nama": "Empty"},
    {"kode": "31", "nama": "DKI Jakarta"}
  ]
}
''';

      final items = RegionApiParser.parseListBody(body);
      expect(items, hasLength(1));
      expect(items.single.kode, '31');
    });
  });

  group('RegionApiParser.toCacheJson', () {
    test('round-trips kode/nama/kodepos', () {
      final items = [
        const RegionItem(kode: '31.71.01.1001', nama: 'Gambir', kodepos: '10110'),
      ];
      final encoded = RegionApiParser.toCacheJson(items);
      final decoded = RegionApiParser.parseListBody(encoded);
      expect(decoded.single.kode, '31.71.01.1001');
      expect(decoded.single.kodepos, '10110');
    });
  });
}
