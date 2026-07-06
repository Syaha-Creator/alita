import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/store_model.dart';
import '../data/services/store_repository.dart';

final _storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository();
});

/// Daftar toko `/all_stores` (cache file + TTL 24 jam di [StoreRepository]).
///
/// - Muat awal: [StoreRepository.getAllStores] (cache jika masih segar).
/// - [StoreListNotifier.refreshFromNetwork]: paksa ambil API dan tulis ulang cache.
/// - [ref.invalidate(storeListProvider)] hanya membangun ulang notifier; tanpa
///   [refreshFromNetwork] tetap bisa memakai cache yang sama.
class StoreListNotifier extends AsyncNotifier<List<StoreModel>> {
  bool _refreshInFlight = false;

  @override
  Future<List<StoreModel>> build() async {
    return ref.read(_storeRepositoryProvider).getAllStores();
  }

  Future<void> refreshFromNetwork() async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;
    state = const AsyncLoading<List<StoreModel>>();
    try {
      state = await AsyncValue.guard(
        () => ref.read(_storeRepositoryProvider).getAllStores(forceRefresh: true),
      );
    } finally {
      _refreshInFlight = false;
    }
  }
}

final storeListProvider =
    AsyncNotifierProvider<StoreListNotifier, List<StoreModel>>(
  StoreListNotifier.new,
);
