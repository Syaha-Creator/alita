import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/product.dart';
import '../../logic/product_provider.dart';
import 'product_detail_page.dart';

/// Shows product detail when navigated via deep link (product by ID only).
/// Resolves [Product] from product list; shows error if not found.
class ProductDetailFromLinkPage extends ConsumerWidget {
  final String productId;

  const ProductDetailFromLinkPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final products = productsAsync.valueOrNull?.products ?? [];

    Product? found;
    for (final p in products) {
      if (p.id == productId) {
        found = p;
        break;
      }
    }

    if (productsAsync.isLoading && products.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Memuat…'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    if (found == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Detail Produk'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Produk tidak ditemukan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Produk mungkin belum dimuat. Pastikan Anda sudah login dan memilih area/channel.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Ke Beranda'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ProductDetailPage(product: found);
  }
}
