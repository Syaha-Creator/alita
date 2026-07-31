// Tests for AnalystLimitAutoApprover — verifies that Analyst-level
// (`approver_level_id: 4`) discount rows are auto-approved only when:
//   1. There IS a pending Analyst row with nominal > 0, AND
//   2. The remaining limit (`available`) covers the TOTAL nominal across
//      every pending row for that analyst (not per-row), AND
// ...and that the flow fails SAFE (leaves rows pending) on any API failure
// or insufficient limit — this call must never throw into checkout submit.

import 'package:alitapricelist/features/checkout/data/models/checkout_models.dart';
import 'package:alitapricelist/features/checkout/data/services/order_letter_limit_service.dart';
import 'package:alitapricelist/features/checkout/data/utils/analyst_limit_auto_approver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderLetterLimitService extends Mock
    implements OrderLetterLimitService {}

PendingDetail _detailWithDiscounts(List<Map<String, dynamic>> discounts) =>
    PendingDetail(payload: const {}, discounts: discounts, label: 'item');

Map<String, dynamic> _analystRow({
  required int approverId,
  required double nominal,
  bool? approved,
}) => {
      'approver': approverId,
      'approver_name': 'Analis Test',
      'approver_level_id': 4,
      'approver_level': 'Analyst',
      'approved': approved,
      'approved_at': null,
      'discount_extra_price': nominal,
    };

Map<String, dynamic> _spvRow() => {
      'approver': 99,
      'approver_name': 'SPV Test',
      'approver_level_id': 2,
      'approver_level': 'SPV',
      'approved': null,
      'approved_at': null,
    };

void main() {
  late _MockOrderLetterLimitService mockLimitService;
  late AnalystLimitAutoApprover approver;

  setUp(() {
    mockLimitService = _MockOrderLetterLimitService();
    approver = AnalystLimitAutoApprover(limitService: mockLimitService);
  });

  test(
      'auto-approves the Analyst row when available limit covers '
      'nominal + 10% safety margin', () async {
    final discRow = _analystRow(approverId: 7, nominal: 500000);
    final details = [_detailWithDiscounts([discRow, _spvRow()])];

    when(() => mockLimitService.fetchAvailableLimit(7))
        .thenAnswer((_) async => 1000000);

    await approver.apply(details);

    expect(discRow['approved'], isTrue);
    expect(discRow['approved_at'], isNotNull);
    expect(discRow['lokasi_approval'], contains('Auto-approved'));
    // Rows for other levels must stay untouched.
    expect(details.first.discounts[1]['approved'], isNull);
  });

  test('sums nominal across MULTIPLE Analyst rows for the same analyst '
      'before comparing to the limit (per-item nominal alone can '
      'under-report the real total)', () async {
    final row1 = _analystRow(approverId: 7, nominal: 400000);
    final row2 = _analystRow(approverId: 7, nominal: 400000);
    final details = [
      _detailWithDiscounts([row1]),
      _detailWithDiscounts([row2]),
    ];

    // Each row alone (400k) fits in a 500k limit, but the sum (800k) does not.
    when(() => mockLimitService.fetchAvailableLimit(7))
        .thenAnswer((_) async => 500000);

    await approver.apply(details);

    expect(row1['approved'], isNull);
    expect(row2['approved'], isNull);
  });

  test(
      'does NOT auto-approve when available is exactly equal to nominal '
      '(no safety margin left) — race-condition mitigation', () async {
    final discRow = _analystRow(approverId: 7, nominal: 500000);
    final details = [_detailWithDiscounts([discRow])];

    // available == nominal exactly → 0% margin, must fail the >=10% check.
    when(() => mockLimitService.fetchAvailableLimit(7))
        .thenAnswer((_) async => 500000);

    await approver.apply(details);

    expect(discRow['approved'], isNull);
  });

  test('leaves rows pending (fail-safe) when available limit is insufficient',
      () async {
    final discRow = _analystRow(approverId: 7, nominal: 900000);
    final details = [_detailWithDiscounts([discRow])];

    when(() => mockLimitService.fetchAvailableLimit(7))
        .thenAnswer((_) async => 500000);

    await approver.apply(details);

    expect(discRow['approved'], isNull);
  });

  test('leaves rows pending (fail-safe) when the limit API returns null',
      () async {
    final discRow = _analystRow(approverId: 7, nominal: 100000);
    final details = [_detailWithDiscounts([discRow])];

    when(() => mockLimitService.fetchAvailableLimit(7))
        .thenAnswer((_) async => null);

    await approver.apply(details);

    expect(discRow['approved'], isNull);
  });

  test('never calls the limit API when there is no pending Analyst row',
      () async {
    final details = [_detailWithDiscounts([_spvRow()])];

    await approver.apply(details);

    verifyNever(() => mockLimitService.fetchAvailableLimit(any()));
  });

  test('skips rows already decided (approved != null) and does not '
      'double-count them into the nominal total', () async {
    final alreadyApproved =
        _analystRow(approverId: 7, nominal: 300000, approved: true);
    final pending = _analystRow(approverId: 7, nominal: 200000);
    final details = [
      _detailWithDiscounts([alreadyApproved, pending]),
    ];

    when(() => mockLimitService.fetchAvailableLimit(7))
        .thenAnswer((_) async => 250000);

    await approver.apply(details);

    // Only the pending row's nominal (200k) should count — 250k covers it.
    expect(pending['approved'], isTrue);
    // Already-decided row must not be re-touched.
    expect(alreadyApproved['lokasi_approval'], isNull);
  });
}
