import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/area_utils.dart';

void main() {
  group('AreaUtils.mapUserAreaToSystemArea', () {
    test('maps province to city name', () {
      expect(AreaUtils.mapUserAreaToSystemArea('Sumatra Selatan'), 'Palembang');
    });

    test('maps abbreviation', () {
      expect(AreaUtils.mapUserAreaToSystemArea('Sumsel'), 'Palembang');
    });

    test('is case-insensitive', () {
      expect(AreaUtils.mapUserAreaToSystemArea('JAWA BARAT'), 'Bandung');
    });

    test('returns null for unknown area', () {
      expect(AreaUtils.mapUserAreaToSystemArea('Mars'), isNull);
    });

    test('returns null for empty input', () {
      expect(AreaUtils.mapUserAreaToSystemArea(''), isNull);
    });

    test('trims whitespace', () {
      expect(AreaUtils.mapUserAreaToSystemArea('  Bali  '), 'Denpasar');
    });

    test('maps Jakarta variants to Jabodetabek', () {
      expect(AreaUtils.mapUserAreaToSystemArea('Jakarta'), 'Jabodetabek');
      expect(AreaUtils.mapUserAreaToSystemArea('Bogor'), 'Jabodetabek');
      expect(AreaUtils.mapUserAreaToSystemArea('Bekasi'), 'Jabodetabek');
    });
  });

  group('AreaUtils.resolveDefaultArea', () {
    const areas = ['Jabodetabek', 'Palembang', 'Bandung', 'Surabaya', 'Nasional'];

    test('returns exact match preserving casing', () {
      expect(AreaUtils.resolveDefaultArea('jabodetabek', areas), 'Jabodetabek');
    });

    test('maps province name to matching area', () {
      expect(AreaUtils.resolveDefaultArea('Sumatra Selatan', areas), 'Palembang');
    });

    test('falls back to Nasional when no match', () {
      expect(AreaUtils.resolveDefaultArea('Unknown', areas), 'Nasional');
    });

    test('falls back to Jabodetabek when Nasional not in list', () {
      final noNasional = ['Jabodetabek', 'Palembang', 'Bandung'];
      expect(AreaUtils.resolveDefaultArea('Unknown', noNasional), 'Jabodetabek');
    });

    test('falls back to first item when neither Nasional nor Jabodetabek in list', () {
      final minimal = ['Bandung', 'Surabaya'];
      expect(AreaUtils.resolveDefaultArea('Unknown', minimal), 'Bandung');
    });

    test('returns Nasional for empty user area', () {
      expect(AreaUtils.resolveDefaultArea('', areas), 'Nasional');
    });

    test('handles empty available list', () {
      expect(AreaUtils.resolveDefaultArea('Jakarta', []), 'Nasional');
    });
  });
}
