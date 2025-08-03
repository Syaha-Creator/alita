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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final accent = isDark ? AppColors.accentDark : AppColors.accentLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) {
        return previous.roundedPrices[product.id] !=
            current.roundedPrices[product.id];
      },
      builder: (context, state) {
        final netPrice =
            state.roundedPrices[product.id] ?? product.endUserPrice;
        final totalDiscount = product.pricelist - netPrice;
        final setProduct = _findSetProduct(state, product);
        final individualKasurProduct =
            _findIndividualKasurProduct(state, product);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 320,
              maxWidth: 500,
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: border, width: 1.2),
              ),
              elevation: 2.5,
              margin: const EdgeInsets.fromLTRB(4, 8, 4, 12),
              shadowColor: accent.withOpacity(0.13),
              color: cardColor,
              child: InkWell(
                onTap: () {
                  context.read<ProductBloc>().add(SelectProduct(product));
                  context.pushNamed(
                    RoutePaths.productDetail,
                    extra: product,
                  );
                },
                borderRadius: BorderRadius.circular(22),
                splashColor: accent.withOpacity(0.08),
                highlightColor: accent.withOpacity(0.04),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: cardColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Header ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Brand dan program tanpa background, hanya bold dan warna
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.brand,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: accent,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              product.program.isNotEmpty
                                                  ? product.program
                                                  : "Tidak ada promo",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.secondaryLight,
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (product.isSet)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.info,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.info
                                                    .withOpacity(0.13),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            "SET",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- Informasi Utama Produk ---
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: border.withOpacity(0.7)),
                          ),
                          child: Column(
                            children: [
                              DetailInfoRow(
                                  title: "Kasur", value: product.kasur),
                              DetailInfoRow(
                                  title: "Divan", value: product.divan),
                              DetailInfoRow(
                                  title: "Headboard", value: product.headboard),
                              DetailInfoRow(
                                  title: "Sorong", value: product.sorong),
                              DetailInfoRow(
                                  title: "Ukuran", value: product.ukuran),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Informasi Harga ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: accent.withOpacity(0.18)),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              DetailInfoRow(
                                title: "Pricelist",
                                value: FormatHelper.formatCurrency(
                                    product.pricelist),
                                isStrikethrough: true,
                                valueColor: accent,
                              ),
                              const SizedBox(height: 4),
                              DetailInfoRow(
                                title: "Harga Net",
                                value: FormatHelper.formatCurrency(netPrice),
                                isBoldValue: true,
                                valueColor: AppColors.primaryLight,
                              ),
                              const SizedBox(height: 2),
                              DetailInfoRow(
                                title: "Total Diskon",
                                value:
                                    "- ${FormatHelper.formatCurrency(totalDiscount)}",
                                valueColor: AppColors.error,
                                isBoldValue: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 15),
                        _buildBonusInfo(isDark: isDark),

                        const SizedBox(height: 15),
                        if (product.isSet) ...[
                          _buildIndividualPricingSection(),
                        ],

                        if (!product.isSet && setProduct != null) ...[
                          const SizedBox(height: 15),
                          _buildSetComparison(setProduct, state,
                              isDark: isDark),
                        ],

                        if (product.isSet &&
                            individualKasurProduct != null) ...[
                          const SizedBox(height: 15),
                          _buildIndividualComparison(
                              individualKasurProduct, state,
                              isDark: isDark),
                        ],
                      ],
                    ),
                  ),
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
  Widget _buildSetComparison(ProductEntity setProduct, ProductState state,
      {bool isDark = false}) {
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
      ProductEntity individualProduct, ProductState state,
      {bool isDark = false}) {
    final individualNetPrice = state.roundedPrices[individualProduct.id] ??
        individualProduct.endUserPrice;
    final currentNetPrice =
        state.roundedPrices[product.id] ?? product.endUserPrice;
    final priceDifference = currentNetPrice - individualNetPrice;
    final isMoreExpensive = priceDifference > 0;
    final savingsPercentage = ((priceDifference.abs() / currentNetPrice) * 100);
    final cardBg = isDark
        ? AppColors.primaryDark.withOpacity(0.13)
        : AppColors.accentLight.withOpacity(0.25);
    final border = isDark ? AppColors.primaryDark : AppColors.accentLight;
    final iconColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.single_bed,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Perbandingan dengan Kasur Only",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Harga Set Kasur:", style: TextStyle(color: textColor)),
              Text(
                FormatHelper.formatCurrency(currentNetPrice),
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Harga Kasur Only:", style: TextStyle(color: textColor)),
              Text(
                FormatHelper.formatCurrency(individualNetPrice),
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Selisih:", style: TextStyle(color: textColor)),
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

  Widget _buildBonusInfo({bool isDark = false}) {
    final hasBonus =
        product.bonus.isNotEmpty && product.bonus.any((b) => b.name.isNotEmpty);
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final iconColor = AppColors.warning;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                "Complimentary:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasBonus)
            ...product.bonus.where((b) => b.name.isNotEmpty).map(
                  (bonus) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: iconColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${bonus.quantity}x ${bonus.name}",
                            style: TextStyle(fontSize: 14, color: textColor),
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
                  color: border,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Tidak ada bonus.",
                  style: TextStyle(fontSize: 14, color: border),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
