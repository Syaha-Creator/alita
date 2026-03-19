import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/floating_badge.dart';
import '../../data/models/product.dart';
import '../../logic/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_shimmer.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_header_widget.dart';
import '../widgets/sort_bottom_sheet.dart';
import '../../../cart/presentation/widgets/cart_fab.dart';
import '../../../favorites/logic/favorites_provider.dart';

/// Product list page with Pinterest-style masonry grid + Cascading Filters
class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final isFilterComplete = ref.watch(isFilterCompleteProvider);
    final favoritesCount = ref.watch(favoritesCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Alita Pricelist',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        elevation: 0,
        actions: [
          // Profile icon
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push('/profile');
            },
          ),
          // Favorites icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  context.push('/favorites');
                },
              ),
              if (favoritesCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: FloatingBadge(
                    count: favoritesCount,
                    maxCount: 9,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    textStyle: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncStateView(
        state: productsAsync,
        loading: _buildShimmerGrid(context),
        errorBuilder: (error, _) => _buildErrorState(context, ref),
        dataBuilder: (_) {
          if (!isFilterComplete) {
            return _buildFilterPrompt(context);
          }
          if (filteredProducts.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildProductGrid(context, filteredProducts);
        },
      ),
      floatingActionButton: const CartFAB(),
    );
  }

  // ─────────────────── Shared header helpers ───────────────────

  Widget _buildSearchRow(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SearchBarWidget()),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _SortButton(onTap: () => _showSortSheet(context)),
        ),
      ],
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SortBottomSheet(),
    );
  }

  /// Common sliver headers used in every state
  List<Widget> _buildStickyHeaders(BuildContext context) {
    return [
      // Search Bar + Sort Button
      SliverPersistentHeader(
        pinned: true,
        delegate: _SearchBarDelegate(
          child: Container(
            color: AppColors.background,
            child: _buildSearchRow(context),
          ),
        ),
      ),
      // Cascading Filter (Area → Channel → Brand)
      const SliverToBoxAdapter(child: FilterHeaderWidget()),
    ];
  }

  // ─────────────────── Body states ───────────────────

  /// Shimmer skeleton while product data loads
  Widget _buildShimmerGrid(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ..._buildStickyHeaders(context),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: 6,
            itemBuilder: (context, index) => const ProductCardShimmer(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  /// Prompt user to complete cascading filter selection
  Widget _buildFilterPrompt(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ..._buildStickyHeaders(context),
        const SliverFillRemaining(
          child: EmptyStateView(
            icon: Icons.filter_list_rounded,
            iconSize: 72,
            padding: EdgeInsets.all(32),
            title: 'Pilih Channel & Brand',
            subtitle:
                'Silakan pilih channel dan brand terlebih dahulu\nuntuk melihat daftar produk.',
          ),
        ),
      ],
    );
  }

  /// No products match the current filters
  Widget _buildEmptyState(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ..._buildStickyHeaders(context),
        const SliverFillRemaining(
          child: EmptyStateView(
            icon: Icons.search_off_outlined,
            title: 'Tidak ada produk ditemukan',
            subtitle: 'Coba kata kunci atau kombinasi filter lain',
          ),
        ),
      ],
    );
  }

  /// Product grid with data
  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return CustomScrollView(
      slivers: [
        ..._buildStickyHeaders(context),
        // Products count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${products.length} produk ditemukan',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
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
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  /// Error state with retry
  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return ErrorStateView(
      title: 'Gagal memuat produk',
      message: 'Periksa koneksi internet Anda dan coba lagi',
      icon: Icons.cloud_off_rounded,
      padding: const EdgeInsets.all(32),
      onRetry: () => ref.invalidate(productListProvider),
      titleStyle: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
      messageStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
      buttonColor: AppColors.accent,
      buttonTextColor: AppColors.surface,
    );
  }
}

// ─────────────────── Sliver delegates ───────────────────

/// Delegate for sticky search bar
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SearchBarDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 72;
  @override
  double get minExtent => 72;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

/// Sort button widget — shows accent dot when sort is active
class _SortButton extends ConsumerWidget {
  final VoidCallback onTap;
  const _SortButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOption = ref.watch(sortOptionProvider);
    final isActive = sortOption != SortOption.newest;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.sort_rounded,
              size: 22,
              color: isActive ? AppColors.accent : AppColors.textSecondary,
            ),
            if (isActive)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
