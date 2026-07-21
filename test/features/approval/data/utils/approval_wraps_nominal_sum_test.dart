import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/approval/data/utils/approval_wraps_nominal_sum.dart';

void main() {
  group('sumNominalFromApprovedSpOrderWrapsOnly', () {
    test('sums extended_amount only for Approved status', () {
      final wraps = [
        {
          'order_letter': {'status': 'Approved', 'extended_amount': '100000'},
        },
        {
          'order_letter': {'status': 'Pending', 'extended_amount': '999999'},
        },
        {
          'order_letter': {'status': 'Rejected', 'extended_amount': '999999'},
        },
      ];

      expect(sumNominalFromApprovedSpOrderWrapsOnly(wraps), 100000.0);
    });

    test('reads status/extended_amount from flat map when no order_letter nesting', () {
      final wraps = [
        {'status': 'Approved', 'extended_amount': 50000},
      ];

      expect(sumNominalFromApprovedSpOrderWrapsOnly(wraps), 50000.0);
    });

    test('skips non-Map elements without throwing', () {
      final wraps = [
        'not-a-map',
        42,
        null,
        {
          'order_letter': {'status': 'Approved', 'extended_amount': 100},
        },
      ];

      expect(sumNominalFromApprovedSpOrderWrapsOnly(wraps), 100.0);
    });

    test('missing extended_amount defaults to 0 instead of throwing', () {
      final wraps = [
        {
          'order_letter': {'status': 'Approved'},
        },
      ];

      expect(sumNominalFromApprovedSpOrderWrapsOnly(wraps), 0.0);
    });

    test('missing status defaults to pending (excluded from sum)', () {
      final wraps = [
        {
          'order_letter': {'extended_amount': 100000},
        },
      ];

      expect(sumNominalFromApprovedSpOrderWrapsOnly(wraps), 0.0);
    });
  });

  group('countApprovedSpOrderWrapsOnly', () {
    test('counts only Approved wraps', () {
      final wraps = [
        {
          'order_letter': {'status': 'Approved', 'extended_amount': 1},
        },
        {
          'order_letter': {'status': 'Approved', 'extended_amount': 2},
        },
        {
          'order_letter': {'status': 'Pending', 'extended_amount': 3},
        },
      ];

      expect(countApprovedSpOrderWrapsOnly(wraps), 2);
    });
  });

  group('approverProfileLeftColumnFromWraps', () {
    test('returns placeholder while loading', () {
      final result = approverProfileLeftColumnFromWraps(
        wraps: const [],
        isLoading: true,
      );

      expect(result.$1, '...');
      expect(result.$2, 0);
    });

    test('returns compact currency + count when loaded', () {
      final wraps = [
        {
          'order_letter': {'status': 'Approved', 'extended_amount': 1500000},
        },
      ];

      final result = approverProfileLeftColumnFromWraps(
        wraps: wraps,
        isLoading: false,
      );

      expect(result.$2, 1);
      expect(result.$1, isNotEmpty);
    });
  });
}
