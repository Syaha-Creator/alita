import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../../pricelist/data/models/product.dart';
import '../../pricelist/logic/product_provider.dart';

/// Favorites state notifier (stores product IDs only for efficiency)
class FavoritesNotifier extends Notifier<List<String>> {
  bool _loadComplete = false;

  @override
  List<String> build() {
    _loadFavorites();
    return [];
  }

  /// Load favorites from storage on init
  Future<void> _loadFavorites() async {
    try {
      final favoriteIds = await StorageService.loadFavorites();
      state = favoriteIds;
    } finally {
      _loadComplete = true;
    }
  }

  /// Waits for the initial [_loadFavorites] to finish before any mutation
  /// runs — otherwise a toggle racing ahead of the load would compute its
  /// result against the empty initial state, and the load completing
  /// afterwards would then clobber the toggle back to the on-disk data.
  Future<void> _ensureLoaded() async {
    if (_loadComplete) return;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return !_loadComplete;
    });
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String productId) async {
    await _ensureLoaded();
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }

    await StorageService.saveFavorites(state);
  }

  /// Check if product is favorite
  bool isFavorite(String productId) {
    return state.contains(productId);
  }

  /// Clear all favorites
  Future<void> clearFavorites() async {
    await _ensureLoaded();
    state = [];
    await StorageService.saveFavorites([]);
  }

  /// Get total favorites count
  int get favoritesCount => state.length;
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<String>>(
  FavoritesNotifier.new,
);

/// Check if specific product is favorite.
///
/// Uses [select] so toggling one heart only rebuilds cards whose bool changed,
/// not the entire masonry grid.
final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(
    favoritesProvider.select((ids) => ids.contains(productId)),
  );
});

final favoritesCountProvider = Provider<int>((ref) {
  return ref.watch(favoritesProvider.select((ids) => ids.length));
});

/// Products filtered down to only favorited IDs.
final favoriteProductsProvider = Provider<List<Product>>((ref) {
  final allProducts =
      ref.watch(productListProvider.select((v) => v.valueOrNull?.products ?? []));
  final favoriteIds = ref.watch(favoritesProvider);

  return allProducts
      .where((product) => favoriteIds.contains(product.id))
      .toList();
});
