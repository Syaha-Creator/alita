// lib/features/product/presentation/widgets/product_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/detail_info_row.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) {
        // Hanya rebuild jika ada perubahan pada harga produk ini
        return previous.roundedPrices[product.id] !=
            current.roundedPrices[product.id];
      },
      builder: (context, state) {
        final netPrice =
            state.roundedPrices[product.id] ?? product.endUserPrice;
        final totalDiscount = product.pricelist - netPrice;

        // Cari produk set yang sesuai untuk perbandingan
        final setProduct = _findSetProduct(state, product);
        // Cari produk kasur individual untuk perbandingan (jika ini adalah set)
        final individualKasurProduct =
            _findIndividualKasurProduct(state, product);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: InkWell(
            onTap: () {
              // Simpan produk yang dipilih di BLoC sebelum navigasi
              context.read<ProductBloc>().add(SelectProduct(product));
              // Navigasi ke halaman detail
              context.pushNamed(
                RoutePaths.productDetail,
                extra: product,
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: product.isSet
                    ? LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white,
                          AppColors.success.withOpacity(0.05),
                        ],
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header dengan Badge Set ---
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.brand,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.program.isNotEmpty
                                    ? product.program
                                    : "Tidak ada promo",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: product.program.isNotEmpty
                                      ? AppColors.success
                                      : Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (product.isSet)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              "SET",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Informasi Utama Produk ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          DetailInfoRow(title: "Kasur", value: product.kasur),
                          DetailInfoRow(title: "Divan", value: product.divan),
                          DetailInfoRow(
                              title: "Headboard", value: product.headboard),
                          DetailInfoRow(title: "Sorong", value: product.sorong),
                          DetailInfoRow(title: "Ukuran", value: product.ukuran),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Informasi Harga ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primaryLight.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          DetailInfoRow(
                            title: "Pricelist",
                            value:
                                FormatHelper.formatCurrency(product.pricelist),
                            isStrikethrough: true,
                            valueColor: AppColors.primaryLight,
                          ),
                          DetailInfoRow(
                            title: "Harga Net",
                            value: FormatHelper.formatCurrency(netPrice),
                            isBoldValue: true,
                            valueColor: AppColors.success,
                          ),
                          DetailInfoRow(
                            title: "Total Diskon",
                            value:
                                "- ${FormatHelper.formatCurrency(totalDiscount)}",
                            valueColor: AppColors.error,
                          ),
                        ],
                      ),
                    ),

                    // --- Informasi Harga Individual untuk Set ---
                    if (product.isSet) ...[
                      const SizedBox(height: 12),
                      _buildIndividualPricingSection(),
                    ],

                    // --- Informasi Bonus ---
                    const SizedBox(height: 12),
                    _buildBonusInfo(),

                    // --- Informasi Perbandingan Set (jika produk non-set) ---
                    if (!product.isSet && setProduct != null) ...[
                      const SizedBox(height: 12),
                      _buildSetComparison(setProduct, state),
                    ],

                    // --- Informasi Perbandingan Individual (jika produk set) ---
                    if (product.isSet && individualKasurProduct != null) ...[
                      const SizedBox(height: 12),
                      _buildIndividualComparison(individualKasurProduct, state),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Method untuk mencari produk set yang sesuai
  ProductEntity? _findSetProduct(
      ProductState state, ProductEntity currentProduct) {
    try {
      // Cari produk set dengan spesifikasi yang sama
      return state.products.firstWhere(
        (product) =>
            product.isSet == true &&
            product.kasur == currentProduct.kasur &&
            product.divan == currentProduct.divan &&
            product.headboard == currentProduct.headboard &&
            product.sorong == currentProduct.sorong &&
            product.ukuran == currentProduct.ukuran &&
            product.brand == currentProduct.brand &&
            product.channel == currentProduct.channel &&
            product.area == currentProduct.area,
      );
    } catch (e) {
      // Return null jika tidak ditemukan produk set yang sesuai
      return null;
    }
  }

  // Method untuk mencari produk kasur individual yang sesuai
  ProductEntity? _findIndividualKasurProduct(
      ProductState state, ProductEntity currentProduct) {
    try {
      // Cari produk kasur individual dengan kasur dan ukuran yang sama
      return state.products.firstWhere(
        (product) =>
            product.isSet == false &&
            product.kasur == currentProduct.kasur &&
            product.ukuran == currentProduct.ukuran &&
            product.brand == currentProduct.brand &&
            product.channel == currentProduct.channel &&
            product.area == currentProduct.area &&
            product.divan == AppStrings.noDivan &&
            product.headboard == AppStrings.noHeadboard &&
            product.sorong == AppStrings.noSorong,
      );
    } catch (e) {
      // Return null jika tidak ditemukan produk individual yang sesuai
      return null;
    }
  }

  // Widget untuk menampilkan perbandingan dengan produk set
  Widget _buildSetComparison(ProductEntity setProduct, ProductState state) {
    final setNetPrice =
        state.roundedPrices[setProduct.id] ?? setProduct.endUserPrice;
    final currentNetPrice =
        state.roundedPrices[product.id] ?? product.endUserPrice;
    final priceDifference = setNetPrice - currentNetPrice;
    final isMoreExpensive = priceDifference > 0;
    final savingsPercentage = ((priceDifference.abs() / setNetPrice) * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.info.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Perbandingan dengan Set",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Harga Set:"),
              Text(
                FormatHelper.formatCurrency(setNetPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Selisih:"),
              Text(
                "${isMoreExpensive ? '+' : '-'}${FormatHelper.formatCurrency(priceDifference.abs())}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMoreExpensive ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isMoreExpensive
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isMoreExpensive
                  ? "Customer hanya menambah ${FormatHelper.formatCurrency(priceDifference)} (${savingsPercentage.toStringAsFixed(1)}%)"
                  : "Customer hanya menambah ${FormatHelper.formatCurrency(priceDifference.abs())} (${savingsPercentage.toStringAsFixed(1)}%)",
              style: TextStyle(
                fontSize: 12,
                color: isMoreExpensive ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan perbandingan dengan produk individual
  Widget _buildIndividualComparison(
      ProductEntity individualProduct, ProductState state) {
    final individualNetPrice = state.roundedPrices[individualProduct.id] ??
        individualProduct.endUserPrice;
    final currentNetPrice =
        state.roundedPrices[product.id] ?? product.endUserPrice;
    final priceDifference = currentNetPrice - individualNetPrice;
    final isMoreExpensive = priceDifference > 0;
    final savingsPercentage = ((priceDifference.abs() / currentNetPrice) * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withOpacity(0.1),
            AppColors.warning.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.single_bed,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Perbandingan dengan Kasur Only",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Harga Set Kasur:"),
              Text(
                FormatHelper.formatCurrency(currentNetPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Harga Kasur Only:"),
              Text(
                FormatHelper.formatCurrency(individualNetPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Selisih:"),
              Text(
                "${isMoreExpensive ? '+' : '-'}${FormatHelper.formatCurrency(priceDifference.abs())}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMoreExpensive ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isMoreExpensive
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isMoreExpensive
                  ? "Customer hanya menambah ${FormatHelper.formatCurrency(priceDifference)} (${savingsPercentage.toStringAsFixed(1)}%)"
                  : "Customer hanya menambah ${FormatHelper.formatCurrency(priceDifference.abs())} (${savingsPercentage.toStringAsFixed(1)}%)",
              style: TextStyle(
                fontSize: 12,
                color: isMoreExpensive ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan harga individual
  Widget _buildIndividualPricingSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: AppColors.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                "Harga per Item:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (product.plKasur > 0)
            DetailInfoRow(
              title: "Kasur",
              value: FormatHelper.formatCurrency(product.plKasur),
            ),
          if (product.plDivan > 0)
            DetailInfoRow(
              title: "Divan",
              value: FormatHelper.formatCurrency(product.plDivan),
            ),
          if (product.plHeadboard > 0)
            DetailInfoRow(
              title: "Headboard",
              value: FormatHelper.formatCurrency(product.plHeadboard),
            ),
          if (product.plSorong > 0)
            DetailInfoRow(
              title: "Sorong",
              value: FormatHelper.formatCurrency(product.plSorong),
            ),
        ],
      ),
    );
  }

  Widget _buildBonusInfo() {
    final hasBonus =
        product.bonus.isNotEmpty && product.bonus.any((b) => b.name.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: Colors.orange[700],
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                "Complimentary:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasBonus)
            ...product.bonus.where((b) => b.name.isNotEmpty).map(
                  (bonus) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.orange[700],
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${bonus.quantity}x ${bonus.name}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
          else
            Row(
              children: [
                Icon(
                  Icons.remove_circle,
                  color: Colors.grey[600],
                  size: 14,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Tidak ada bonus.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
