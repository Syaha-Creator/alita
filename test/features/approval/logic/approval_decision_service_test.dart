import 'package:alitapricelist/core/enums/order_status.dart';
import 'package:alitapricelist/features/approval/logic/approval_decision_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApprovalDecisionService.collectPendingDiscounts', () {
    test('collects SPV rows on every component (kasur + divan), not just one',
        () {
      const spvId = 787;
      final orderData = {
        'order_letter': {'id': 1, 'status': 'Pending'},
        'order_letter_details': [
          {
            'order_letter_discount': [
              {
                'order_letter_discount_id': 11,
                'approver_id': '1',
                'approver_level_id': 1,
                'approved': 'Approved',
              },
              {
                'order_letter_discount_id': 12,
                'approver_id': '$spvId',
                'approver_level_id': 2,
                'approver_level': 'SPV',
                'approved': null,
              },
            ],
          },
          {
            'order_letter_discount': [
              {
                'order_letter_discount_id': 21,
                'approver_id': '1',
                'approver_level_id': 1,
                'approved': 'Approved',
              },
              {
                'order_letter_discount_id': 22,
                'approver_id': '$spvId',
                'approver_level_id': 2,
                'approver_level': 'SPV',
                'approved': null,
              },
            ],
          },
        ],
      };

      final pending = ApprovalDecisionService.collectPendingDiscounts(
        orderData: orderData,
        myName: 'Andy',
        myUserId: spvId,
      );

      expect(pending.map((e) => e['order_letter_discount_id']), [12, 22]);
    });

    test('SPV also collects FOC (90) in same tap — does not wait for RSM', () {
      const spvId = 787;
      final orderData = {
        'order_letter': {'id': 2, 'status': 'Pending'},
        'order_letter_details': [
          {
            'order_letter_discount': [
              {
                'order_letter_discount_id': 1,
                'approver_id': '9',
                'approver_level_id': 1,
                'approved': 'Approved',
              },
              {
                'order_letter_discount_id': 2,
                'approver_id': '$spvId',
                'approver_level_id': 2,
                'approver_level': 'SPV',
                'approved': null,
              },
              {
                'order_letter_discount_id': 3,
                'approver_id': '6235',
                'approver_level_id': 3,
                'approver_level': 'RSM',
                'approved': null,
              },
              {
                'order_letter_discount_id': 90,
                'approver_id': '$spvId',
                'approver_level_id': 90,
                'approver_level': 'FOC',
                'approved': null,
              },
            ],
          },
        ],
      };

      final pending = ApprovalDecisionService.collectPendingDiscounts(
        orderData: orderData,
        myName: 'Andy',
        myUserId: spvId,
      );

      expect(
        pending.map((e) => e['order_letter_discount_id']).toList(),
        containsAll([2, 90]),
      );
      expect(
        pending.any((e) => e['order_letter_discount_id'] == 3),
        isFalse,
      );
    });

    test('reads discount id from `id` when order_letter_discount_id missing',
        () {
      const spvId = 10;
      final orderData = {
        'order_letter_details': [
          {
            'order_letter_discount': [
              {
                'id': 55,
                'approver_id': '$spvId',
                'approver_level_id': 2,
                'approved': OrderStatus.pending.apiValue,
              },
              {
                'id': 54,
                'approver_id': '1',
                'approver_level_id': 1,
                'approved': OrderStatus.approved.apiValue,
              },
            ],
          },
        ],
      };

      final pending = ApprovalDecisionService.collectPendingDiscounts(
        orderData: orderData,
        myName: '',
        myUserId: spvId,
      );

      expect(pending, hasLength(1));
      expect(pending.first['order_letter_discount_id'], 55);
    });
  });
}
