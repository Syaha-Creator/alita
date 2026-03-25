import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/core/services/storage_service.dart';
import 'package:alitapricelist/features/quotation/data/quotation_model.dart';
import 'package:alitapricelist/features/quotation/logic/quotation_list_provider.dart';

import '../../../helpers/mock_app_support_dir.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuotationListNotifier notifier;

  setUp(() async {
    StorageService.debugResetFileCacheForTests();
    setMockApplicationSupportDirectory(
      Directory.systemTemp.createTempSync('alita_quotation_test_').path,
    );
    SharedPreferences.setMockInitialValues({});
    notifier = QuotationListNotifier();
    await Future.delayed(const Duration(milliseconds: 100));
  });

  group('QuotationListNotifier', () {
    test('starts with empty state', () {
      expect(notifier.state, isEmpty);
    });

    test('add inserts at front', () async {
      final q1 = _makeQuotation(id: 'q1', name: 'First');
      final q2 = _makeQuotation(id: 'q2', name: 'Second');

      await notifier.add(q1);
      await notifier.add(q2);

      expect(notifier.state, hasLength(2));
      expect(notifier.state[0].customerName, 'Second');
      expect(notifier.state[1].customerName, 'First');
    });

    test('remove deletes by id', () async {
      final q = _makeQuotation(id: 'q-remove');
      await notifier.add(q);
      expect(notifier.state, hasLength(1));

      await notifier.remove('q-remove');
      expect(notifier.state, isEmpty);
    });

    test('remove does nothing for non-existent id', () async {
      final q = _makeQuotation(id: 'q-keep');
      await notifier.add(q);

      await notifier.remove('q-nonexistent');
      expect(notifier.state, hasLength(1));
    });

    test('update replaces matching quotation', () async {
      final q = _makeQuotation(id: 'q-update', name: 'Before');
      await notifier.add(q);

      final updated = q.copyWith(customerName: 'After');
      await notifier.update(updated);

      expect(notifier.state, hasLength(1));
      expect(notifier.state[0].customerName, 'After');
    });

    test('update leaves non-matching items unchanged', () async {
      final q1 = _makeQuotation(id: 'q1', name: 'One');
      final q2 = _makeQuotation(id: 'q2', name: 'Two');
      await notifier.add(q1);
      await notifier.add(q2);

      final updated = q1.copyWith(customerName: 'One Updated');
      await notifier.update(updated);

      expect(notifier.state, hasLength(2));
      final names = notifier.state.map((q) => q.customerName).toList();
      expect(names, contains('One Updated'));
      expect(names, contains('Two'));
    });

    test('persists data across instances', () async {
      final q = _makeQuotation(id: 'q-persist', name: 'Persisted');
      await notifier.add(q);

      final notifier2 = QuotationListNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier2.state, hasLength(1));
      expect(notifier2.state[0].customerName, 'Persisted');
    });
  });
}

QuotationModel _makeQuotation({
  required String id,
  String name = 'Test',
}) =>
    QuotationModel(
      id: id,
      customerName: name,
      items: const [],
      subtotal: 100000,
      totalPrice: 100000,
      createdAt: DateTime(2026, 3, 1),
    );
