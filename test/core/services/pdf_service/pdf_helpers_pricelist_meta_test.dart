import 'package:alitapricelist/core/services/pdf_service/sections/pdf_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfHelpers.formatPricelistMetaLine', () {
    test('both empty → empty string', () {
      expect(PdfHelpers.formatPricelistMetaLine(), isEmpty);
      expect(
        PdfHelpers.formatPricelistMetaLine(type: '  ', area: ''),
        isEmpty,
      );
    });

    test('type only', () {
      expect(
        PdfHelpers.formatPricelistMetaLine(type: 'Retail'),
        'Tipe: Retail',
      );
    });

    test('area only', () {
      expect(
        PdfHelpers.formatPricelistMetaLine(area: 'Jakarta'),
        'Area: Jakarta',
      );
    });

    test('type and area joined with middle dot', () {
      expect(
        PdfHelpers.formatPricelistMetaLine(
          type: 'Retail',
          area: 'Jakarta',
        ),
        'Tipe: Retail · Area: Jakarta',
      );
    });

    test('trims whitespace', () {
      expect(
        PdfHelpers.formatPricelistMetaLine(
          type: '  Showroom  ',
          area: '  Bandung ',
        ),
        'Tipe: Showroom · Area: Bandung',
      );
    });
  });
}
