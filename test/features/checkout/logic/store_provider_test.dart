import 'package:alitapricelist/features/checkout/data/models/store_model.dart';
import 'package:alitapricelist/features/checkout/data/services/store_repository.dart';
import 'package:alitapricelist/features/checkout/logic/store_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStoreRepository extends Mock implements StoreRepository {}

StoreModel _store({required int id, required String name}) =>
    StoreModel(id: id, name: name);

void main() {
  late MockStoreRepository mockRepo;

  setUp(() {
    mockRepo = MockStoreRepository();
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [storeRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('storeListProvider', () {
    test('build() resolves with the repository\'s store list', () async {
      when(() => mockRepo.getAllStores()).thenAnswer(
        (_) async => [_store(id: 1, name: 'Toko A'), _store(id: 2, name: 'Toko B')],
      );

      final container = buildContainer();
      final stores = await container.read(storeListProvider.future);

      expect(stores, hasLength(2));
      verify(() => mockRepo.getAllStores()).called(1);
    });

    test('propagates repository errors as AsyncError', () async {
      when(() => mockRepo.getAllStores())
          .thenThrow(Exception('Gagal mengambil daftar toko'));

      final container = buildContainer();

      await expectLater(
        container.read(storeListProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('refreshFromNetwork() forces a refetch via forceRefresh: true',
        () async {
      when(() => mockRepo.getAllStores())
          .thenAnswer((_) async => [_store(id: 1, name: 'Cached')]);
      when(() => mockRepo.getAllStores(forceRefresh: true)).thenAnswer(
        (_) async => [_store(id: 1, name: 'Fresh')],
      );

      final container = buildContainer();
      await container.read(storeListProvider.future);

      await container.read(storeListProvider.notifier).refreshFromNetwork();

      final state = container.read(storeListProvider);
      expect(state.value?.single.name, 'Fresh');
      verify(() => mockRepo.getAllStores(forceRefresh: true)).called(1);
    });

    test('refreshFromNetwork() guards against concurrent calls', () async {
      when(() => mockRepo.getAllStores())
          .thenAnswer((_) async => [_store(id: 1, name: 'Initial')]);
      when(() => mockRepo.getAllStores(forceRefresh: true)).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return [_store(id: 1, name: 'Refreshed')];
        },
      );

      final container = buildContainer();
      await container.read(storeListProvider.future);

      final notifier = container.read(storeListProvider.notifier);
      // Fire twice back-to-back — the second call should be a no-op while
      // the first is still in flight.
      final first = notifier.refreshFromNetwork();
      final second = notifier.refreshFromNetwork();
      await Future.wait([first, second]);

      verify(() => mockRepo.getAllStores(forceRefresh: true)).called(1);
    });
  });
}
