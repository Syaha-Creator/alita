import 'package:alitapricelist/core/enums/order_status.dart';
import 'package:alitapricelist/features/approval/logic/approval_prior_check.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _disc({
  required int id,
  required int level,
  required String approved,
}) {
  return {
    'order_letter_discount_id': id,
    'approver_level_id': level,
    'approved': approved,
  };
}

void main() {
  group('arePriorApprovalsSatisfied', () {
    test('level-based: lower level must be approved before higher', () {
      final discounts = [
        _disc(id: 1, level: 2, approved: OrderStatus.pending.apiValue),
        _disc(id: 2, level: 1, approved: OrderStatus.approved.apiValue),
      ];
      // Index 0 is level 2; prior level 1 is approved → OK even if out of order.
      expect(
        arePriorApprovalsSatisfied(discounts: discounts, myIndex: 0),
        isTrue,
      );
    });

    test('level-based: blocks when lower level still pending', () {
      final discounts = [
        _disc(id: 1, level: 1, approved: OrderStatus.pending.apiValue),
        _disc(id: 2, level: 2, approved: OrderStatus.pending.apiValue),
      ];
      expect(
        arePriorApprovalsSatisfied(discounts: discounts, myIndex: 1),
        isFalse,
      );
    });

    test('index fallback when level missing', () {
      final discounts = [
        {
          'order_letter_discount_id': 1,
          'approved': OrderStatus.pending.apiValue,
        },
        {
          'order_letter_discount_id': 2,
          'approved': OrderStatus.pending.apiValue,
        },
      ];
      expect(
        arePriorApprovalsSatisfied(discounts: discounts, myIndex: 1),
        isFalse,
      );
      discounts[0]['approved'] = OrderStatus.approved.apiValue;
      expect(
        arePriorApprovalsSatisfied(discounts: discounts, myIndex: 1),
        isTrue,
      );
    });

    test('treats batchIds as already satisfied (same-user cascade)', () {
      final discounts = [
        _disc(id: 1, level: 1, approved: OrderStatus.pending.apiValue),
        _disc(id: 2, level: 2, approved: OrderStatus.pending.apiValue),
      ];
      expect(
        arePriorApprovalsSatisfied(
          discounts: discounts,
          myIndex: 1,
          treatedAsApprovedIds: {1},
        ),
        isTrue,
      );
    });
  });
}
