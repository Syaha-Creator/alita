import 'package:alitapricelist/core/utils/store_display_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreDisplayUtils', () {
    test('strips parenthetical and trailing period before end', () {
      expect(
        StoreDisplayUtils.assignedStoreTitle('57 SEJAHTERA (SA - REG).'),
        '57 SEJAHTERA',
      );
    });

    test('row label appends catcode_27', () {
      expect(
        StoreDisplayUtils.assignedStoreRowLabel(
          alphaName: '57 SEJAHTERA (SA - REG).',
          catcode27: 'ABC',
        ),
        '57 SEJAHTERA · ABC',
      );
    });

    test('row label without catcode is title only', () {
      expect(
        StoreDisplayUtils.assignedStoreRowLabel(
          alphaName: 'ANEKA FURNITURE CAWANG',
          catcode27: null,
        ),
        'ANEKA FURNITURE CAWANG',
      );
    });
  });
}
