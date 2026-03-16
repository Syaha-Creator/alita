import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../logic/favorites_provider.dart';
import '../../../pricelist/data/models/product.dart';
import '../../../pricelist/presentation/widgets/product_card.dart';

/// Favorites page - Shows all favorited products
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteProducts = ref.watch(favoriteProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Favorites',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        elevation: 0,
        actions: [
          if (favoriteProducts.isNotEmpty)
            TextButton(
              onPressed: () {
                _showClearConfirmation(context, ref);
              },
              child: Text(
                'Clear All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
      body: favoriteProducts.isEmpty
          ? _buildEmptyState(context)
          : _buildFavoritesGrid(context, favoriteProducts),
    );
  }

  Widget _buildFavoritesGrid(BuildContext context, List<Product> products) {
    return CustomScrollView(
      slivers: [
        // Padding at top
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),

        // Favorites count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${products.length} favorite ${products.length == 1 ? 'product' : 'products'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ),
        ),

        // Masonry Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return RepaintBoundary(
                child: ProductCard(
                  product: product,
                  onTap: () {
                    context.push('/product/${product.id}', extra: product);
                  },
                ),
              );
            },
          ),
        ),

        // Padding at bottom
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateView(
      icon: Icons.favorite_border,
      iconSize: 100,
      title: 'Belum ada produk favorit',
      subtitle: 'Yuk cari barang impianmu!\nTap ikon ❤️ untuk menandai produk favorit',
      action: ActionButtonBar(
        fullWidth: false,
        mainAxisSize: MainAxisSize.min,
        height: 44,
        borderRadius: 12,
        primaryLabel: 'Browse Products',
        primaryLeading: const Icon(Icons.arrow_back),
        onPrimaryPressed: () {
          Navigator.of(context).pop();
        },
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showAdaptiveAlert(
      context: context,
      title: 'Clear All Favorites?',
      content: 'This will remove all products from your favorites list.',
      actions: [
        const AdaptiveAction(label: 'Cancel', popResult: false),
        AdaptiveAction(
          label: 'Clear',
          isDestructive: true,
          onPressed: () {
            ref.read(favoritesProvider.notifier).clearFavorites();
            Navigator.of(context).pop();
            AppFeedback.plain(
              context,
              'All favorites cleared',
              duration: const Duration(seconds: 2),
            );
          },
        ),
      ],
    );
  }
}
