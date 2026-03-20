import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/shipping_utils.dart';

void main() {
  group('isShippingDifferent', () {
    test('returns false when shipping is empty', () {
      expect(
        isShippingDifferent(
          shipToName: '',
          shipToAddress: '',
          customerName: 'John',
          customerAddress: 'Jl. Test 1',
        ),
        isFalse,
      );
    });

    test('returns false when shipping matches customer', () {
      expect(
        isShippingDifferent(
          shipToName: 'John',
          shipToAddress: 'Jl. Test 1',
          customerName: 'John',
          customerAddress: 'Jl. Test 1',
        ),
        isFalse,
      );
    });

    test('returns false when shipping matches case-insensitively', () {
      expect(
        isShippingDifferent(
          shipToName: 'JOHN',
          shipToAddress: 'jl. test 1',
          customerName: 'john',
          customerAddress: 'Jl. Test 1',
        ),
        isFalse,
      );
    });

    test('returns true when name differs', () {
      expect(
        isShippingDifferent(
          shipToName: 'Jane',
          shipToAddress: 'Jl. Test 1',
          customerName: 'John',
          customerAddress: 'Jl. Test 1',
        ),
        isTrue,
      );
    });

    test('returns true when address differs', () {
      expect(
        isShippingDifferent(
          shipToName: 'John',
          shipToAddress: 'Jl. Different 99',
          customerName: 'John',
          customerAddress: 'Jl. Test 1',
        ),
        isTrue,
      );
    });

    test('treats dash as empty', () {
      expect(
        isShippingDifferent(
          shipToName: '-',
          shipToAddress: '-',
          customerName: 'John',
          customerAddress: 'Jl. Test 1',
        ),
        isFalse,
      );
    });

    test('trims whitespace before comparison', () {
      expect(
        isShippingDifferent(
          shipToName: '  John  ',
          shipToAddress: '  Jl. Test 1  ',
          customerName: 'John',
          customerAddress: 'Jl. Test 1',
        ),
        isFalse,
      );
    });
  });
}
