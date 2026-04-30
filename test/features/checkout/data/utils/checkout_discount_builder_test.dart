// Tests for CheckoutDiscountBuilder — verifies every approval-chain row
// sent to the server (discount, approver, level_id, approved flag, etc.).
//
// These are payload-contract tests. If a field name, conditional rule, or
// level number changes, these tests will catch it before it hits the API.

import 'package:alitapricelist/features/checkout/data/models/approver_model.dart';
import 'package:alitapricelist/features/checkout/data/utils/checkout_discount_builder.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

const _userId = 9;
const _creatorName = 'Sales A';
const _creatorTitle = 'Sales';
const _analystId = 55;
const _analystName = 'Analyst X';
const _analystTitle = 'Analyst';

Approver _spv({int id = 10, String name = 'SPV Budi'}) => Approver(
      id: id,
      userName: 'spv_budi',
      fullName: name,
      jobLevelName: 'Supervisor',
    );

Approver _manager({int id = 20, String name = 'RSM Siti'}) => Approver(
      id: id,
      userName: 'rsm_siti',
      fullName: name,
      jobLevelName: 'RSM',
    );

List<Map<String, dynamic>> _build({
  double d1 = 0,
  double d2 = 0,
  double d3 = 0,
  double d4 = 0,
  Approver? spv,
  Approver? manager,
  bool isIndirect = false,
  bool isBonusCustomized = false,
  double? d1Nominal,
  double? d2Nominal,
  double? d3Nominal,
  double? d4Nominal,
}) =>
    CheckoutDiscountBuilder.build(
      userId: _userId,
      creatorName: _creatorName,
      creatorTitle: _creatorTitle,
      selectedSpv: spv,
      selectedManager: manager,
      analystId: d4 > 0 ? _analystId : null,
      analystName: _analystName,
      analystTitle: _analystTitle,
      discount1: d1,
      discount2: d2,
      discount3: d3,
      discount4: d4,
      isIndirectOrder: isIndirect,
      isBonusCustomized: isBonusCustomized,
      discount1NominalLine: d1Nominal,
      discount2NominalLine: d2Nominal,
      discount3NominalLine: d3Nominal,
      discount4NominalLine: d4Nominal,
    );

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── DIRECT order ──────────────────────────────────────────────────────────
  group('CheckoutDiscountBuilder.build — DIRECT order', () {
    group('Level 1 (User)', () {
      test('always present as first row', () {
        final rows = _build(d1: 5);
        expect(rows, isNotEmpty);
        final l1 = rows.first;
        expect(l1['approver_level_id'], 1);
        expect(l1['approver_level'], 'User');
      });

      test('auto-approved with approved=true and approved_at not null', () {
        final rows = _build(d1: 5);
        final l1 = rows.first;
        expect(l1['approved'], true);
        expect(l1['approved_at'], isNotNull);
      });

      test('discount field equals d1 as string', () {
        final rows = _build(d1: 7.5);
        expect(rows.first['discount'], '7.5');
      });

      test('discount_price present when d1 > 0 and nominal provided', () {
        final rows = _build(d1: 5, d1Nominal: 100_000);
        expect(rows.first['discount_price'], 100_000.0);
      });

      test('discount_price NOT present when d1 = 0', () {
        final rows = _build(d1: 0, d1Nominal: 100_000);
        expect(rows.first.containsKey('discount_price'), isFalse);
      });

      test('approver = userId', () {
        final rows = _build(d1: 5);
        expect(rows.first['approver'], _userId);
      });

      test('approver_name = creatorName', () {
        final rows = _build();
        expect(rows.first['approver_name'], _creatorName);
      });
    });

    group('Level 2 (SPV)', () {
      test('not included when selectedSpv is null', () {
        final rows = _build(d1: 5, d2: 3);
        expect(rows.where((r) => r['approver_level_id'] == 2), isEmpty);
      });

      test('included when selectedSpv provided', () {
        final rows = _build(d1: 5, d2: 3, spv: _spv());
        final l2 = rows.firstWhere((r) => r['approver_level_id'] == 2);
        expect(l2['approver_level'], 'SPV');
        expect(l2['approver'], 10);
      });

      test('approved = null (pending approval)', () {
        final rows = _build(d1: 5, d2: 3, spv: _spv());
        final l2 = rows.firstWhere((r) => r['approver_level_id'] == 2);
        expect(l2['approved'], isNull);
        expect(l2['approved_at'], isNull);
      });

      test('discount_price present when d2 > 0 and nominal provided', () {
        final rows = _build(d1: 5, d2: 3, spv: _spv(), d2Nominal: 50_000);
        final l2 = rows.firstWhere((r) => r['approver_level_id'] == 2);
        expect(l2['discount_price'], 50_000.0);
      });

      test('discount_price NOT present when d2 = 0', () {
        final rows = _build(d2: 0, spv: _spv(), d2Nominal: 50_000);
        final l2 = rows.firstWhere((r) => r['approver_level_id'] == 2);
        expect(l2.containsKey('discount_price'), isFalse);
      });
    });

    group('Level 3 (RSM/Manager)', () {
      test('included when discount3 > 0 and manager provided', () {
        final rows = _build(d3: 2, manager: _manager());
        final l3 = rows.firstWhere((r) => r['approver_level_id'] == 3);
        expect(l3['approver_level'], 'RSM');
        expect(l3['approved'], isNull);
      });

      test('NOT included when discount3 = 0 and bonus not customized', () {
        final rows = _build(d3: 0, manager: _manager());
        expect(rows.where((r) => r['approver_level_id'] == 3), isEmpty);
      });

      test('included when isBonusCustomized = true even if d3 = 0', () {
        final rows =
            _build(d3: 0, manager: _manager(), isBonusCustomized: true);
        final l3 = rows.firstWhere((r) => r['approver_level_id'] == 3);
        // 0.0.toString() = '0.0' — production sends '0.0' to server for zero discount
        expect(l3['discount'], '0.0');
      });

      test('NOT included when manager is null even if d3 > 0', () {
        final rows = _build(d3: 5, manager: null);
        expect(rows.where((r) => r['approver_level_id'] == 3), isEmpty);
      });
    });

    group('Level 4 (Analyst)', () {
      test('included when discount4 > 0 and analystId not null', () {
        final rows = _build(d4: 1.5);
        final l4 = rows.firstWhere((r) => r['approver_level_id'] == 4);
        expect(l4['approver_level'], 'Analyst');
        expect(l4['discount_extra'], '1.5');
        expect(l4['approved'], isNull);
      });

      test('NOT included when discount4 = 0', () {
        final rows = _build(d4: 0);
        expect(rows.where((r) => r['approver_level_id'] == 4), isEmpty);
      });

      test('discount_price and discount_extra_price present when nominal > 0',
          () {
        final rows = _build(d4: 2, d4Nominal: 80_000);
        final l4 = rows.firstWhere((r) => r['approver_level_id'] == 4);
        expect(l4['discount_price'], 80_000.0);
        expect(l4['discount_extra_price'], 80_000.0);
      });
    });

    group('order of rows', () {
      test('rows are in level order: 1, 2, 3, 4', () {
        final rows = _build(
          d1: 5,
          d2: 3,
          d3: 2,
          d4: 1,
          spv: _spv(),
          manager: _manager(),
        );
        final levels = rows.map((r) => r['approver_level_id'] as int).toList();
        expect(levels, [1, 2, 3, 4]);
      });
    });

    group('row field completeness', () {
      test('every row has required keys', () {
        final rows = _build(d1: 5, d2: 3, spv: _spv());
        const required = [
          'discount', 'approver', 'approver_name', 'approver_level_id',
          'approver_level', 'approver_work_tittle', 'approved', 'approved_at',
        ];
        for (final row in rows) {
          for (final key in required) {
            expect(row.containsKey(key), isTrue, reason: 'Row missing key: $key');
          }
        }
      });
    });
  });

  // ── INDIRECT order ────────────────────────────────────────────────────────
  group('CheckoutDiscountBuilder.build — INDIRECT order', () {
    group('Level 1 (User) indirect', () {
      test('always present with discount = 0', () {
        final rows = _build(isIndirect: true, d1: 5);
        final l1 = rows.firstWhere((r) => r['approver_level_id'] == 1);
        expect(l1['discount'], '0');
        expect(l1['approved'], true);
      });

      test('approver_level = User', () {
        final rows = _build(isIndirect: true);
        final l1 = rows.firstWhere((r) => r['approver_level_id'] == 1);
        expect(l1['approver_level'], 'User');
      });
    });

    group('Level 2 (ASM) indirect', () {
      test('included with discount = 0 when spv provided', () {
        final rows = _build(isIndirect: true, spv: _spv());
        final l2 = rows.firstWhere((r) => r['approver_level_id'] == 2);
        expect(l2['discount'], '0');
        expect(l2['approver_level'], 'ASM');
        expect(l2['approved'], isNull);
      });

      test('NOT included when spv is null', () {
        final rows = _build(isIndirect: true);
        expect(rows.where((r) => r['approver_level_id'] == 2), isEmpty);
      });
    });

    group('Level 3 (RSM) indirect — one row per non-zero discount', () {
      test('one RSM row when only d1 > 0', () {
        final rows =
            _build(isIndirect: true, d1: 3, manager: _manager());
        final l3 = rows.where((r) => r['approver_level_id'] == 3).toList();
        expect(l3, hasLength(1));
        expect(l3.first['discount'], '3.0');
      });

      test('two RSM rows when d1 and d2 > 0', () {
        final rows =
            _build(isIndirect: true, d1: 3, d2: 2, manager: _manager());
        final l3 = rows.where((r) => r['approver_level_id'] == 3).toList();
        expect(l3, hasLength(2));
      });

      test('three RSM rows when d1, d2, d3 all > 0', () {
        final rows = _build(
          isIndirect: true,
          d1: 3,
          d2: 2,
          d3: 1,
          manager: _manager(),
        );
        final l3 = rows.where((r) => r['approver_level_id'] == 3).toList();
        expect(l3, hasLength(3));
      });

      test('RSM rows include discount_extra field', () {
        final rows =
            _build(isIndirect: true, d1: 5, manager: _manager());
        final l3 = rows.firstWhere((r) => r['approver_level_id'] == 3);
        expect(l3.containsKey('discount_extra'), isTrue);
        expect(l3['discount_extra'], '5.0');
      });

      test('discount_price and discount_extra_price only when nominal > 0', () {
        final rows = _build(
          isIndirect: true,
          d1: 5,
          manager: _manager(),
          d1Nominal: 200_000,
        );
        final l3 = rows.firstWhere((r) => r['approver_level_id'] == 3);
        expect(l3['discount_price'], 200_000.0);
        expect(l3['discount_extra_price'], 200_000.0);
      });

      test('no RSM row when all discounts = 0 and bonus not customized', () {
        final rows = _build(isIndirect: true, manager: _manager());
        expect(rows.where((r) => r['approver_level_id'] == 3), isEmpty);
      });

      test('one RSM row with discount=0 when bonus customized, no discounts',
          () {
        final rows = _build(
          isIndirect: true,
          manager: _manager(),
          isBonusCustomized: true,
        );
        final l3 = rows.where((r) => r['approver_level_id'] == 3).toList();
        expect(l3, hasLength(1));
        // 0.0.toString() = '0.0' — production sends '0.0' to server for zero discount
        expect(l3.first['discount'], '0.0');
      });
    });

    group('Level 4 (Analyst) — same logic for indirect', () {
      test('included when d4 > 0', () {
        final rows = _build(isIndirect: true, d4: 2);
        expect(rows.where((r) => r['approver_level_id'] == 4), isNotEmpty);
      });
    });
  });

  // ── buildFocVoucherRow ────────────────────────────────────────────────────
  group('CheckoutDiscountBuilder.buildFocVoucherRow', () {
    late List<Map<String, dynamic>> rows;

    setUp(() {
      rows = CheckoutDiscountBuilder.buildFocVoucherRow(selectedSpv: _spv());
    });

    test('returns exactly one row', () {
      expect(rows, hasLength(1));
    });

    test('approver_level_id = 90 (avoids collision with 1-4)', () {
      expect(rows.first['approver_level_id'], 90);
    });

    test('discount = 100 as string', () {
      expect(rows.first['discount'], '100');
    });

    test('approver_level = FOC', () {
      expect(rows.first['approver_level'], 'FOC');
    });

    test('approved = null (pending spv approval)', () {
      expect(rows.first['approved'], isNull);
    });

    test('approved_at = null', () {
      expect(rows.first['approved_at'], isNull);
    });

    test('approver = spv id', () {
      expect(rows.first['approver'], 10);
    });

    test('contains all required keys', () {
      for (final key in [
        'discount',
        'approver',
        'approver_name',
        'approver_level_id',
        'approver_level',
        'approver_work_tittle',
        'approved',
        'approved_at',
      ]) {
        expect(rows.first.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });
  });

  // ── buildStoreDiscountRows ────────────────────────────────────────────────
  group('CheckoutDiscountBuilder.buildStoreDiscountRows', () {
    test('zero discounts are skipped', () {
      final rows = CheckoutDiscountBuilder.buildStoreDiscountRows(
        storeDiscounts: [5, 0, 3],
        storeAlphaName: 'Toko ABC',
      );
      expect(rows, hasLength(2));
    });

    test('approver_level_id starts at 5 for first slot', () {
      final rows = CheckoutDiscountBuilder.buildStoreDiscountRows(
        storeDiscounts: [5, 3],
        storeAlphaName: 'Toko ABC',
      );
      expect(rows[0]['approver_level_id'], 5);
      expect(rows[1]['approver_level_id'], 6);
    });

    test('standard_discount matches discount string', () {
      final rows = CheckoutDiscountBuilder.buildStoreDiscountRows(
        storeDiscounts: [7.5],
        storeAlphaName: 'Toko X',
      );
      expect(rows.first['standard_discount'], '7.5');
      expect(rows.first['discount'], '7.5');
    });

    test('approved = true, approved_at = not null (auto-approved)', () {
      final rows = CheckoutDiscountBuilder.buildStoreDiscountRows(
        storeDiscounts: [5],
        storeAlphaName: 'Toko X',
      );
      expect(rows.first['approved'], true);
      expect(rows.first['approved_at'], isNotNull);
    });

    test('approver_level label includes slot number', () {
      final rows = CheckoutDiscountBuilder.buildStoreDiscountRows(
        storeDiscounts: [5, 3],
        storeAlphaName: 'Toko X',
      );
      expect(rows[0]['approver_level'], 'Diskon Toko 1');
      expect(rows[1]['approver_level'], 'Diskon Toko 2');
    });

    test('discount_price and standart_discount_price only when nominal > 0', () {
      final rows = CheckoutDiscountBuilder.buildStoreDiscountRows(
        storeDiscounts: [5, 3],
        storeAlphaName: 'Toko X',
        storeDiscountNominals: [150_000, 0],
      );
      expect(rows[0]['discount_price'], 150_000.0);
      expect(rows[0]['standart_discount_price'], 150_000.0);
      expect(rows[1].containsKey('discount_price'), isFalse);
      expect(rows[1].containsKey('standart_discount_price'), isFalse);
    });

    test('empty storeDiscounts returns empty list', () {
      final rows = CheckoutDiscountBuilder.buildStoreDiscountRows(
        storeDiscounts: [],
        storeAlphaName: 'Toko X',
      );
      expect(rows, isEmpty);
    });

    test('approver = null for store rows (no user approver)', () {
      final rows = CheckoutDiscountBuilder.buildStoreDiscountRows(
        storeDiscounts: [5],
        storeAlphaName: 'Toko X',
      );
      expect(rows.first['approver'], isNull);
    });

    test('contains all required keys', () {
      final rows = CheckoutDiscountBuilder.buildStoreDiscountRows(
        storeDiscounts: [5],
        storeAlphaName: 'Toko X',
      );
      for (final key in [
        'discount',
        'approver',
        'approver_name',
        'approver_level_id',
        'approver_level',
        'approver_work_tittle',
        'approved',
        'approved_at',
        'standard_discount',
      ]) {
        expect(rows.first.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });
  });
}
