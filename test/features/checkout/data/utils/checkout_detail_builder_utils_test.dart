import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/checkout/data/utils/checkout_detail_builder_utils.dart';
import 'package:alitapricelist/features/pricelist/data/models/item_lookup.dart';

void main() {
  group('CheckoutDetailBuilderUtils.buildCleanItemDescription', () {
    test('name only', () {
      expect(
        CheckoutDetailBuilderUtils.buildCleanItemDescription('Spring Bed'),
        'Spring Bed',
      );
    });

    test('name + code', () {
      expect(
        CheckoutDetailBuilderUtils.buildCleanItemDescription(
          'Spring Bed',
          code: 'Oscar',
        ),
        'Spring Bed - Oscar',
      );
    });

    test('name + code + color', () {
      expect(
        CheckoutDetailBuilderUtils.buildCleanItemDescription(
          'Spring Bed',
          code: 'Oscar',
          color: 'Biru',
        ),
        'Spring Bed - Oscar - Biru',
      );
    });

    test('strips dash-only code', () {
      expect(
        CheckoutDetailBuilderUtils.buildCleanItemDescription(
          'Spring Bed',
          code: '-',
          color: 'Biru',
        ),
        'Spring Bed - Biru',
      );
    });

    test('strips empty code and color', () {
      expect(
        CheckoutDetailBuilderUtils.buildCleanItemDescription(
          'Spring Bed',
          code: '',
          color: '  ',
        ),
        'Spring Bed',
      );
    });

    test('trims whitespace from all parts', () {
      expect(
        CheckoutDetailBuilderUtils.buildCleanItemDescription(
          '  Spring Bed  ',
          code: '  Oscar  ',
          color: '  Biru  ',
        ),
        'Spring Bed - Oscar - Biru',
      );
    });

    test('empty base name with code and color', () {
      expect(
        CheckoutDetailBuilderUtils.buildCleanItemDescription(
          '',
          code: 'Oscar',
          color: 'Biru',
        ),
        'Oscar - Biru',
      );
    });
  });

  group('CheckoutDetailBuilderUtils.buildDescription', () {
    test('uses lookup data when available', () {
      final lookupMap = {
        'SKU001': ItemLookup(
          tipe: 'Kasur',
          ukuran: '160',
          itemNum: 'SKU001',
          jenisKain: 'Oscar',
          warnaKain: 'Biru',
        ),
      };
      final result = CheckoutDetailBuilderUtils.buildDescription(
        baseDesc: 'Spring Bed',
        sku: 'SKU001',
        lookupByItemNum: lookupMap,
      );
      expect(result, 'Spring Bed - Oscar - Biru');
    });

    test('falls back to stored kain/warna when no lookup', () {
      final result = CheckoutDetailBuilderUtils.buildDescription(
        baseDesc: 'Spring Bed',
        sku: 'SKU999',
        lookupByItemNum: {},
        storedKain: 'Katun',
        storedWarna: 'Merah',
      );
      expect(result, 'Spring Bed - Katun - Merah');
    });

    test('ignores null-string stored values', () {
      final result = CheckoutDetailBuilderUtils.buildDescription(
        baseDesc: 'Spring Bed',
        sku: 'SKU999',
        lookupByItemNum: {},
        storedKain: 'null',
        storedWarna: 'null',
      );
      expect(result, 'Spring Bed');
    });

    test('uses sku as base when baseDesc is empty', () {
      final result = CheckoutDetailBuilderUtils.buildDescription(
        baseDesc: '',
        sku: 'SKU001',
        lookupByItemNum: {},
      );
      expect(result, 'SKU001');
    });
  });

  group('CheckoutDetailBuilderUtils.validateRequiredField', () {
    test('throws for null value', () {
      expect(
        () => CheckoutDetailBuilderUtils.validateRequiredField('name', null),
        throwsException,
      );
    });

    test('throws for empty string', () {
      expect(
        () => CheckoutDetailBuilderUtils.validateRequiredField('name', ''),
        throwsException,
      );
    });

    test('throws for zero number', () {
      expect(
        () => CheckoutDetailBuilderUtils.validateRequiredField('qty', 0),
        throwsException,
      );
    });

    test('passes for non-empty string', () {
      expect(
        () => CheckoutDetailBuilderUtils.validateRequiredField('name', 'OK'),
        returnsNormally,
      );
    });

    test('passes for non-zero number', () {
      expect(
        () => CheckoutDetailBuilderUtils.validateRequiredField('qty', 5),
        returnsNormally,
      );
    });
  });

  group('CheckoutDetailBuilderUtils.normalizeNullableSku', () {
    test('returns null for empty string', () {
      expect(CheckoutDetailBuilderUtils.normalizeNullableSku(''), isNull);
    });

    test('returns null for dash', () {
      expect(CheckoutDetailBuilderUtils.normalizeNullableSku('-'), isNull);
    });

    test('returns null for "null" string', () {
      expect(CheckoutDetailBuilderUtils.normalizeNullableSku('null'), isNull);
    });

    test('returns trimmed SKU for valid value', () {
      expect(
        CheckoutDetailBuilderUtils.normalizeNullableSku('  SKU001  '),
        'SKU001',
      );
    });

    test('returns SKU as-is for normal value', () {
      expect(
        CheckoutDetailBuilderUtils.normalizeNullableSku('ABC123'),
        'ABC123',
      );
    });
  });
}
