import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../logic/favorites_provider.dart';
import '../../../pricelist/data/models/product.dart';
import '../../../pricelist/logic/product_provider.dart';
import '../../../pricelist/presentation/widgets/product_card.dart';
import '../../../pricelist/presentation/widgets/product_card_shimmer.dart';

/// Favorites page - Shows all favorited products
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final favoriteProducts = ref.watch(favoriteProductsProvider);
    final isLoading = productsAsync.isLoading && favoriteProducts.isEmpty;
    final hasError = productsAsync.hasError && favoriteProducts.isEmpty;
    final showStalePl = productsAsync.valueOrNull?.isFromStaleCache ?? false;
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Favorit Saya',
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
                'Hapus Semua',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showStalePl)
            Material(
              color: AppColors.warning.withValues(alpha: 0.12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.history_edu_outlined,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Katalog disimpan offline — favorit mengikuti data terakhir. Refresh di Beranda.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? _buildLoadingSkeleton()
                : hasError
                    ? _buildErrorState(context, ref, isOffline: isOffline)
                    : favoriteProducts.isEmpty
                        ? _buildEmptyState(context)
                        : _buildFavoritesGrid(context, favoriteProducts,
                            ref: ref),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ProductCardShimmer(),
    );
  }

  Widget _buildFavoritesGrid(
    BuildContext context,
    List<Product> products, {
    required WidgetRef ref,
  }) {
    return RefreshIndicator.adaptive(
      color: AppColors.accent,
      onRefresh: () async => ref.invalidate(productListProvider),
      child: CustomScrollView(
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
              '${products.length} produk favorit',
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
              return AnimatedListItem(
                index: index,
                child: RepaintBoundary(
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      context.push('/product/${product.id}', extra: product);
                    },
                  ),
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
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref,
      {required bool isOffline}) {
    return ErrorStateView(
      icon: isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: isOffline ? 'Sedang offline' : 'Gagal memuat katalog',
      message: isOffline
          ? 'Periksa koneksi internet Anda dan coba lagi.'
          : 'Terjadi kesalahan saat memuat data produk.',
      onRetry: () => ref.invalidate(productListProvider),
      iconColor: isOffline ? AppColors.warning : AppColors.error,
      buttonColor: AppColors.accent,
      buttonTextColor: AppColors.onPrimary,
      messageStyle:
          const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateView(
      icon: Icons.favorite_border,
      iconSize: 100,
      title: 'Belum ada produk favorit',
      subtitle:
          'Yuk cari barang impianmu!\nTap ikon favorit untuk menandai produk favorit',
      action: ActionButtonBar(
        fullWidth: false,
        mainAxisSize: MainAxisSize.min,
        height: 44,
        borderRadius: 12,
        primaryLabel: 'Lihat Katalog',
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
      title: 'Hapus Semua Favorit?',
      content: 'Semua produk akan dihapus dari daftar favorit Anda.',
      actions: [
        const AdaptiveAction(label: 'Batal', popResult: false),
        AdaptiveAction(
          label: 'Hapus',
          isDestructive: true,
          popResult: true,
          onPressed: () {
            ref.read(favoritesProvider.notifier).clearFavorites();
            if (context.mounted) {
              AppFeedback.plain(
                context,
                'Semua favorit dihapus',
                duration: const Duration(seconds: 2),
              );
            }
          },
        ),
      ],
    );
  }
}
