import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/checkout/logic/checkout_provider.dart';
import 'package:alitapricelist/features/history/data/models/order_history.dart';

/// Regression coverage for [CheckoutNotifier]'s approval-drop guard — a
/// defense-in-depth check added after the "Customer Baru hilang saat edit
/// item" bug (Jul 2026), where a required ASM/SPV approval row silently
/// disappeared because the page-level "is approval required" flag and the
/// actually-selected approver could drift apart.
///
/// The guard makes that class of bug fail loudly (submitError set, no API
/// calls made) instead of silently producing an order/edit with a missing
/// approval row — for ANY caller of [CheckoutNotifier.submitOrder] /
/// [CheckoutNotifier.submitEditOrder], not just the current checkout page UI.
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  bool noTakeAway(int _) => false;
  bool noBonusTakeAway(int _, CartBonusSnapshot __) => false;
  int zeroTakeAwayQty(int _, CartBonusSnapshot __) => 0;

  OrderHistory buildEditOrder() => const OrderHistory(
        id: 1,
        noSp: 'SP-T',
        orderDate: '-',
        requestDate: '-',
        note: '',
        customerName: 'Test',
        phone: '-',
        address: '-',
        email: '',
        isTakeAway: false,
        workPlaceName: '-',
        companyName: '-',
        totalAmount: 0,
        status: 'Approved',
      );

  group('submitOrder — approval guard', () {
    test(
      'fails fast with submitError when SPV/ASM required but not selected',
      () async {
        final notifier = container.read(checkoutProvider.notifier);
        // Sanity: no approver selected (default state).
        expect(container.read(checkoutProvider).selectedSpv, isNull);

        await notifier.submitOrder(
          cartItems: const [],
          headerPayload: const {},
          contactsPayload: const [],
          paymentPayloads: const [],
          receiptImages: const [],
          lineIsTakeAway: noTakeAway,
          isBonusTakeAwayChecked: noBonusTakeAway,
          currentTakeAwayQty: zeroTakeAwayQty,
          selectedCartItems: null,
          requiresSpvApproval: true,
        );

        final state = container.read(checkoutProvider);
        expect(state.isSubmitting, isFalse);
        expect(state.submitError, isNotNull);
        expect(state.submitError, contains('SPV/ASM'));
      },
    );

    test(
      'fails fast with submitError when Manager/RSM required but not selected',
      () async {
        final notifier = container.read(checkoutProvider.notifier);
        expect(container.read(checkoutProvider).selectedManager, isNull);

        await notifier.submitOrder(
          cartItems: const [],
          headerPayload: const {},
          contactsPayload: const [],
          paymentPayloads: const [],
          receiptImages: const [],
          lineIsTakeAway: noTakeAway,
          isBonusTakeAwayChecked: noBonusTakeAway,
          currentTakeAwayQty: zeroTakeAwayQty,
          selectedCartItems: null,
          requiresManagerApproval: true,
        );

        final state = container.read(checkoutProvider);
        expect(state.submitError, contains('Manager/RSM'));
      },
    );

    test(
      'does NOT assert when requiresSpvApproval/requiresManagerApproval are '
      'left at their default (false) — old callers/tests keep working',
      () async {
        final notifier = container.read(checkoutProvider.notifier);

        await notifier.submitOrder(
          cartItems: const [],
          headerPayload: const {},
          contactsPayload: const [],
          paymentPayloads: const [],
          receiptImages: const [],
          lineIsTakeAway: noTakeAway,
          isBonusTakeAwayChecked: noBonusTakeAway,
          currentTakeAwayQty: zeroTakeAwayQty,
          selectedCartItems: null,
        );

        // Should fail later (no real StorageService/API in this test), but
        // NOT with our "belum dipilih" approval-guard message — proving the
        // guard is opt-in via the new flags and doesn't change behavior for
        // callers that don't pass them.
        final state = container.read(checkoutProvider);
        expect(state.submitError, isNotNull);
        expect(state.submitError, isNot(contains('SPV/ASM')));
        expect(state.submitError, isNot(contains('Manager/RSM')));
      },
    );
  });

  group('submitEditOrder — approval guard', () {
    test(
      'fails fast with submitError when SPV/ASM required but not selected',
      () async {
        final notifier = container.read(checkoutProvider.notifier);

        await notifier.submitEditOrder(
          editOrder: buildEditOrder(),
          cartItems: const [],
          lineIsTakeAway: noTakeAway,
          isBonusTakeAwayChecked: noBonusTakeAway,
          currentTakeAwayQty: zeroTakeAwayQty,
          requiresSpvApproval: true,
        );

        final state = container.read(checkoutProvider);
        expect(state.isSubmitting, isFalse);
        expect(state.submitError, contains('SPV/ASM'));
      },
    );

    test(
      'fails fast with submitError when Manager/RSM required but not selected',
      () async {
        final notifier = container.read(checkoutProvider.notifier);

        await notifier.submitEditOrder(
          editOrder: buildEditOrder(),
          cartItems: const [],
          lineIsTakeAway: noTakeAway,
          isBonusTakeAwayChecked: noBonusTakeAway,
          currentTakeAwayQty: zeroTakeAwayQty,
          requiresManagerApproval: true,
        );

        final state = container.read(checkoutProvider);
        expect(state.submitError, contains('Manager/RSM'));
      },
    );

    test('passes the guard once selectedSpv is set', () async {
      final notifier = container.read(checkoutProvider.notifier);

      await notifier.submitEditOrder(
        editOrder: buildEditOrder(),
        cartItems: const [],
        lineIsTakeAway: noTakeAway,
        isBonusTakeAwayChecked: noBonusTakeAway,
        currentTakeAwayQty: zeroTakeAwayQty,
        requiresSpvApproval: false,
      );

      // Fails later for unrelated reasons (no real backend in this test),
      // but must NOT be the approval-guard message.
      final state = container.read(checkoutProvider);
      expect(state.submitError, isNot(contains('SPV/ASM')));
    });
  });
}
