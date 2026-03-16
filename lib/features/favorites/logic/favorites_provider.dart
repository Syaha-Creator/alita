import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../../pricelist/data/models/product.dart';
import '../../pricelist/logic/product_provider.dart';

/// Favorites state notifier (stores product IDs only for efficiency)
class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  /// Load favorites from storage on init
  Future<void> _loadFavorites() async {
    final favoriteIds = await StorageService.loadFavorites();
    state = favoriteIds;
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String productId) async {
    if (state.contains(productId)) {
      // Remove from favorites
      state = state.where((id) => id != productId).toList();
    } else {
      // Add to favorites
      state = [...state, productId];
    }
    
    // Save to storage
    await StorageService.saveFavorites(state);
  }

  /// Check if product is favorite
  bool isFavorite(String productId) {
    return state.contains(productId);
  }

  /// Clear all favorites
  Future<void> clearFavorites() async {
    state = [];
    await StorageService.saveFavorites([]);
  }

  /// Get total favorites count
  int get favoritesCount => state.length;
}

/// Favorites provider
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  return FavoritesNotifier();
});

/// Check if specific product is favorite
final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.contains(productId);
});

/// Total favorites count provider
final favoritesCountProvider = Provider<int>((ref) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.length;
});

/// Favorite products provider - returns only favorited products
final favoriteProductsProvider = Provider<List<Product>>((ref) {
  final allProducts = ref.watch(productListProvider).valueOrNull ?? [];
  final favoriteIds = ref.watch(favoritesProvider);
  
  return allProducts
      .where((product) => favoriteIds.contains(product.id))
      .toList();
});
