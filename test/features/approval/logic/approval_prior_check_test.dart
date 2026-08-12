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

    test(
      'RSM blocked when SPV row still pending even if SPV level_id missing '
      '(label SPV only) — regression: RSM muncul di Menunggu sebelum SPV',
      () {
        final discounts = [
          _disc(id: 1, level: 1, approved: OrderStatus.approved.apiValue),
          {
            'order_letter_discount_id': 2,
            'approver_id': '10',
            'approver_level': 'SPV',
            // level_id hilang/0 dari API — dulu di-skip sehingga RSM lolos.
            'approved': OrderStatus.pending.apiValue,
          },
          _disc(id: 3, level: 3, approved: OrderStatus.pending.apiValue),
        ];
        expect(
          arePriorApprovalsSatisfied(discounts: discounts, myIndex: 2),
          isFalse,
        );
      },
    );

    test('resolves ASM label as level 2 prior for RSM', () {
      final discounts = [
        _disc(id: 1, level: 1, approved: OrderStatus.approved.apiValue),
        {
          'order_letter_discount_id': 2,
          'approver_level': 'ASM',
          'approved': OrderStatus.pending.apiValue,
        },
        _disc(id: 3, level: 3, approved: OrderStatus.pending.apiValue),
      ];
      expect(
        arePriorApprovalsSatisfied(discounts: discounts, myIndex: 2),
        isFalse,
      );
    });

    test(
      'pending row without level before RSM still blocks (index fallback)',
      () {
        final discounts = [
          _disc(id: 1, level: 1, approved: OrderStatus.approved.apiValue),
          {
            'order_letter_discount_id': 2,
            'approved': OrderStatus.pending.apiValue,
          },
          _disc(id: 3, level: 3, approved: OrderStatus.pending.apiValue),
        ];
        expect(
          arePriorApprovalsSatisfied(discounts: discounts, myIndex: 2),
          isFalse,
        );
      },
    );
  });

  group('resolveApproverLevel', () {
    test('prefers numeric level_id', () {
      expect(
        resolveApproverLevel({'approver_level_id': 2, 'approver_level': 'RSM'}),
        2,
      );
    });

    test('falls back to label when level_id missing', () {
      expect(resolveApproverLevel({'approver_level': 'SPV'}), 2);
      expect(resolveApproverLevel({'approver_level': 'RSM'}), 3);
      expect(resolveApproverLevel({'approver_level': 'User'}), 1);
    });
  });

  group('areLowerApprovalLevelsSatisfied (order-wide)', () {
    test('blocks RSM when SPV pending even if array order is 1,3,4,2', () {
      final all = [
        _disc(id: 1, level: 1, approved: OrderStatus.approved.apiValue),
        _disc(id: 3, level: 3, approved: OrderStatus.pending.apiValue),
        _disc(id: 4, level: 4, approved: OrderStatus.pending.apiValue),
        _disc(id: 2, level: 2, approved: OrderStatus.pending.apiValue),
      ];
      expect(
        areLowerApprovalLevelsSatisfied(allDiscounts: all, myLevel: 3),
        isFalse,
      );
      expect(
        areLowerApprovalLevelsSatisfied(allDiscounts: all, myLevel: 2),
        isTrue,
      );
    });

    test('FOC level 90 only waits for User, not RSM/Analyst', () {
      final all = [
        _disc(id: 1, level: 1, approved: OrderStatus.approved.apiValue),
        _disc(id: 2, level: 2, approved: OrderStatus.pending.apiValue),
        _disc(id: 3, level: 3, approved: OrderStatus.pending.apiValue),
        _disc(id: 90, level: 90, approved: OrderStatus.pending.apiValue),
      ];
      expect(
        areLowerApprovalLevelsSatisfied(allDiscounts: all, myLevel: 90),
        isTrue,
      );
    });
  });

  group('discountApproverId', () {
    test('reads approver_id or approver fallback', () {
      expect(discountApproverId({'approver_id': 787}), '787');
      expect(discountApproverId({'approver': 787}), '787');
      expect(discountApproverId({'approver': {'id': 9}}), '9');
    });
  });
}
