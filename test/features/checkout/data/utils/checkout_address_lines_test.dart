import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/checkout/data/utils/checkout_address_lines.dart';

void main() {
  group('CheckoutAddressLines.join', () {
    test('joins non-empty lines', () {
      expect(
        CheckoutAddressLines.join('Jl. Melati 1', 'Blok A', 'RT 02'),
        'Jl. Melati 1, Blok A, RT 02',
      );
    });

    test('skips empty line 3', () {
      expect(
        CheckoutAddressLines.join('Jl. Melati 1', 'Blok A', ''),
        'Jl. Melati 1, Blok A',
      );
    });

    test('legacyCombined includes county/city/state', () {
      expect(
        CheckoutAddressLines.legacyCombined(
          detailJoined: 'Jl. Melati 1, Blok A',
          kecamatan: 'Menteng',
          kota: 'Jakarta Pusat',
          provinsi: 'DKI Jakarta',
        ),
        'Jl. Melati 1, Blok A, Kec. Menteng, Jakarta Pusat, DKI Jakarta',
      );
    });

    test('structuredBlock maps county from kecamatan', () {
      final m = CheckoutAddressLines.structuredBlock(
        prefix: 'soldto',
        address1: 'A',
        address2: 'B',
        address3: '',
        city: 'Jakarta',
        state: 'DKI',
        county: 'Menteng',
      );
      expect(m['soldto_county'], 'Menteng');
      expect(m['soldto_city'], 'Jakarta');
      expect(m['soldto_state'], 'DKI');
      expect(m['soldto_country'], 'Indonesia');
      expect(m['soldto_postal_code'], '');
    });

    test('clampLine truncates to maxLineLength', () {
      final long = 'a' * (CheckoutAddressLines.maxLineLength + 5);
      expect(
        CheckoutAddressLines.clampLine(long).length,
        CheckoutAddressLines.maxLineLength,
      );
    });

    test('structuredBlock clamps each address line', () {
      final long = 'x' * (CheckoutAddressLines.maxLineLength + 10);
      final m = CheckoutAddressLines.structuredBlock(
        prefix: 'shipto',
        address1: long,
        address2: '  short  ',
        address3: long,
        city: null,
        state: null,
        county: null,
      );
      expect(
        (m['shipto_address1'] as String).length,
        CheckoutAddressLines.maxLineLength,
      );
      expect(m['shipto_address2'], 'short');
      expect(
        (m['shipto_address3'] as String).length,
        CheckoutAddressLines.maxLineLength,
      );
    });
  });

  group('CheckoutAddressLines.split', () {
    test('single chunk → line1 only', () {
      final s = CheckoutAddressLines.split('Jl. Melati No. 1');
      expect(s.line1, 'Jl. Melati No. 1');
      expect(s.line2, isEmpty);
      expect(s.line3, isEmpty);
    });

    test('three+ chunks → line3 absorbs rest', () {
      final s = CheckoutAddressLines.split('A, B, C, D');
      expect(s.line1, 'A');
      expect(s.line2, 'B');
      expect(s.line3, 'C, D');
    });
  });
}
