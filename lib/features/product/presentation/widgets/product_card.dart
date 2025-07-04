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

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
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
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Informasi Utama Produk ---
                  DetailInfoRow(title: "Kasur", value: product.kasur),
                  DetailInfoRow(title: "Divan", value: product.divan),
                  DetailInfoRow(title: "Headboard", value: product.headboard),
                  DetailInfoRow(title: "Sorong", value: product.sorong),
                  DetailInfoRow(title: "Ukuran", value: product.ukuran),
                  const SizedBox(height: 12),

                  // --- Informasi Harga ---
                  DetailInfoRow(
                    title: "Pricelist",
                    value: FormatHelper.formatCurrency(product.pricelist),
                    isStrikethrough: true,
                    valueColor: AppColors.error,
                  ),
                  DetailInfoRow(
                    title: "Program",
                    value: product.program.isNotEmpty
                        ? product.program
                        : "Tidak ada promo",
                  ),
                  DetailInfoRow(
                    title: "Harga Net",
                    value: FormatHelper.formatCurrency(netPrice),
                    isBoldValue: true,
                    valueColor: AppColors.success,
                  ),
                  DetailInfoRow(
                    title: "Total Diskon",
                    value: "- ${FormatHelper.formatCurrency(totalDiscount)}",
                    valueColor: AppColors.warning,
                  ),
                  const SizedBox(height: 12),

                  // --- Informasi Bonus ---
                  _buildBonusInfo(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonusInfo() {
    final hasBonus =
        product.bonus.isNotEmpty && product.bonus.any((b) => b.name.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Complimentary:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (hasBonus)
          ...product.bonus.where((b) => b.name.isNotEmpty).map(
                (bonus) => Text("• ${bonus.quantity}x ${bonus.name}",
                    style: const TextStyle(fontSize: 14)),
              )
        else
          const Text("Tidak ada bonus.",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
