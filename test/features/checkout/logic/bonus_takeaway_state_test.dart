import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/checkout/logic/bonus_takeaway_state.dart';

CartBonusSnapshot _bonus({String sku = 'B1', int qty = 1}) =>
    CartBonusSnapshot(name: 'Pillow', sku: sku, qty: qty);

void main() {
  group('BonusTakeAwayState', () {
    test('plus can rise up to bonus.qty * itemQuantity', () {
      final state = BonusTakeAwayState();
      const itemIndex = 0;
      final bonus = _bonus(qty: 1);
      const maxQty = 2; // item.quantity = 2

      state.toggle(itemIndex, bonus, true, maxQty: maxQty);
      expect(state.currentQty(itemIndex, bonus, maxQty: maxQty), 1);

      state.setQty(itemIndex, bonus, 2, maxQty: maxQty);
      expect(state.currentQty(itemIndex, bonus, maxQty: maxQty), 2);

      state.setQty(itemIndex, bonus, 99, maxQty: maxQty);
      expect(state.currentQty(itemIndex, bonus, maxQty: maxQty), 2);
    });

    test('old bug: clamping only to bonus.qty blocked the + stepper', () {
      final state = BonusTakeAwayState();
      const itemIndex = 0;
      final bonus = _bonus(qty: 1);
      // Simulate pre-fix ceiling (bonus.qty only).
      state.toggle(itemIndex, bonus, true, maxQty: 1);
      expect(state.currentQty(itemIndex, bonus, maxQty: 1), 1);
      // UI thought max was 2, but state rejected 2 when maxQty was wrongly 1.
      state.setQty(itemIndex, bonus, 2, maxQty: 1);
      expect(state.currentQty(itemIndex, bonus, maxQty: 1), 1);
    });

    test('uncheck clears qty', () {
      final state = BonusTakeAwayState();
      final bonus = _bonus();
      state.toggle(0, bonus, true, maxQty: 3);
      state.setQty(0, bonus, 3, maxQty: 3);
      state.toggle(0, bonus, false, maxQty: 3);
      expect(state.isChecked(0, bonus), isFalse);
      expect(state.currentQty(0, bonus, maxQty: 3), 0);
    });
  });
}
