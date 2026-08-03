import 'package:alitapricelist/features/history/data/models/order_history.dart';
import 'package:alitapricelist/features/history/logic/edit_order_context_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('editOrderContextProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(editOrderContextProvider), isNull);
    });

    test('can be set and cleared', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final order = OrderHistory.fromApiJson(const {
        'id': 1,
        'no_sp': 'SP-1',
        'order_date': '2026-01-01',
        'request_date': '-',
        'note': '',
        'customer_name': 'Edit Target',
        'phone': '0',
        'address': '-',
        'email': '',
        'extended_amount': 0,
        'status': 'Pending',
        'order_letter_details': <dynamic>[],
        'order_letter_payments': <dynamic>[],
      });

      container.read(editOrderContextProvider.notifier).state = order;
      expect(
        container.read(editOrderContextProvider)?.customerName,
        'Edit Target',
      );

      container.read(editOrderContextProvider.notifier).state = null;
      expect(container.read(editOrderContextProvider), isNull);
    });
  });
}
