import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/core/services/storage_service.dart';
import 'package:alitapricelist/features/quotation/data/quotation_model.dart';
import 'package:alitapricelist/features/quotation/logic/quotation_list_provider.dart';

import '../../../helpers/mock_app_support_dir.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late QuotationListNotifier notifier;

  /// Draft quotation disimpan di secure storage (lihat
  /// [StorageService.saveQuotationsJson]) — perlu mock channel-nya di sini.
  void mockSecureStorage() {
    final store = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall call) async {
        switch (call.method) {
          case 'read':
            return store[call.arguments['key']];
          case 'write':
            store[call.arguments['key'] as String] =
                call.arguments['value'] as String;
            return null;
          case 'delete':
            store.remove(call.arguments['key']);
            return null;
          case 'deleteAll':
            store.clear();
            return null;
          default:
            return null;
        }
      },
    );
  }

  setUp(() async {
    StorageService.debugResetFileCacheForTests();
    setMockApplicationSupportDirectory(
      Directory.systemTemp.createTempSync('alita_quotation_test_').path,
    );
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    container = ProviderContainer();
    notifier = container.read(quotationListProvider.notifier); // trigger build()
    await Future.delayed(const Duration(milliseconds: 100));
  });

  tearDown(() => container.dispose());

  group('QuotationListNotifier', () {
    test('starts with empty state', () {
      expect(container.read(quotationListProvider), isEmpty);
    });

    test('add inserts at front', () async {
      final q1 = _makeQuotation(id: 'q1', name: 'First');
      final q2 = _makeQuotation(id: 'q2', name: 'Second');

      await notifier.add(q1);
      await notifier.add(q2);

      final state = container.read(quotationListProvider);
      expect(state, hasLength(2));
      expect(state[0].customerName, 'Second');
      expect(state[1].customerName, 'First');
    });

    test('remove deletes by id', () async {
      final q = _makeQuotation(id: 'q-remove');
      await notifier.add(q);
      expect(container.read(quotationListProvider), hasLength(1));

      await notifier.remove('q-remove');
      expect(container.read(quotationListProvider), isEmpty);
    });

    test('remove does nothing for non-existent id', () async {
      final q = _makeQuotation(id: 'q-keep');
      await notifier.add(q);

      await notifier.remove('q-nonexistent');
      expect(container.read(quotationListProvider), hasLength(1));
    });

    test('update replaces matching quotation', () async {
      final q = _makeQuotation(id: 'q-update', name: 'Before');
      await notifier.add(q);

      final updated = q.copyWith(customerName: 'After');
      await notifier.update(updated);

      final state = container.read(quotationListProvider);
      expect(state, hasLength(1));
      expect(state[0].customerName, 'After');
    });

    test('update leaves non-matching items unchanged', () async {
      final q1 = _makeQuotation(id: 'q1', name: 'One');
      final q2 = _makeQuotation(id: 'q2', name: 'Two');
      await notifier.add(q1);
      await notifier.add(q2);

      final updated = q1.copyWith(customerName: 'One Updated');
      await notifier.update(updated);

      final state = container.read(quotationListProvider);
      expect(state, hasLength(2));
      final names = state.map((q) => q.customerName).toList();
      expect(names, contains('One Updated'));
      expect(names, contains('Two'));
    });

    test('remove called before initial load finishes does not get clobbered '
        'by the in-flight load', () async {
      // Seed disk with a quotation via one notifier instance, then create a
      // brand-new instance and call remove() immediately — before its
      // build()-triggered _load() has had a chance to complete.
      final seed = _makeQuotation(id: 'q-race', name: 'Racey');
      await notifier.add(seed);

      final racing = ProviderContainer();
      addTearDown(racing.dispose);
      // No delay here — remove() must itself await the in-flight load.
      // Reading `.notifier` triggers build() (kicking off `_load()`) AND
      // gives us the instance to call remove() on, same tick.
      final racingNotifier = racing.read(quotationListProvider.notifier);
      await racingNotifier.remove('q-race');

      expect(racing.read(quotationListProvider), isEmpty);

      // Reload from disk to make sure the removal was actually persisted,
      // not just clobbered back in-memory by the late-finishing _load().
      final verify = ProviderContainer();
      addTearDown(verify.dispose);
      verify.read(quotationListProvider); // trigger lazy build()
      await Future.delayed(const Duration(milliseconds: 100));
      expect(verify.read(quotationListProvider), isEmpty);
    });

    test('update called before initial load finishes does not get clobbered '
        'by the in-flight load', () async {
      final seed = _makeQuotation(id: 'q-race-2', name: 'Before');
      await notifier.add(seed);

      final racing = ProviderContainer();
      addTearDown(racing.dispose);
      final updated = seed.copyWith(customerName: 'After');
      final racingNotifier = racing.read(quotationListProvider.notifier);
      await racingNotifier.update(updated);

      final racingState = racing.read(quotationListProvider);
      expect(racingState, hasLength(1));
      expect(racingState[0].customerName, 'After');

      final verify = ProviderContainer();
      addTearDown(verify.dispose);
      verify.read(quotationListProvider); // trigger lazy build()
      await Future.delayed(const Duration(milliseconds: 100));
      expect(verify.read(quotationListProvider)[0].customerName, 'After');
    });

    test('persists data across instances', () async {
      final q = _makeQuotation(id: 'q-persist', name: 'Persisted');
      await notifier.add(q);

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      container2.read(quotationListProvider); // trigger lazy build()
      await Future.delayed(const Duration(milliseconds: 100));

      final state2 = container2.read(quotationListProvider);
      expect(state2, hasLength(1));
      expect(state2[0].customerName, 'Persisted');
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
