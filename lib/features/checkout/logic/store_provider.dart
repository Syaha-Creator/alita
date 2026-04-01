import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/store_model.dart';
import '../data/services/store_repository.dart';

final _storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository();
});

/// Cached store list — auto-fetched on first access, refreshable via
/// `ref.invalidate(storeListProvider)`.
final storeListProvider = FutureProvider<List<StoreModel>>((ref) {
  return ref.watch(_storeRepositoryProvider).getAllStores();
});
