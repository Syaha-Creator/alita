import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../theme/app_colors.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_state.dart';
import '../widgets/product_action.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final product = state.selectProduct;

        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: const Center(
                child: Text("Produk tidak ditemukan atau belum dipilih.")),
          );
        }

        final netPrice =
            state.roundedPrices[product.id] ?? product.endUserPrice;
        final discountPercentages =
            state.productDiscountsPercentage[product.id] ?? [];
        final editPopupDiscount =
            state.priceChangePercentages[product.id] ?? 0.0;
        final totalDiscount = product.pricelist - netPrice;
        final installmentMonths = state.installmentMonths[product.id];
        final note = state.productNotes[product.id] ?? "";

        final List<String> combinedDiscounts = [];
        final programDiscounts = discountPercentages
            .where((d) => d > 0.0)
            .map((d) =>
                d % 1 == 0 ? "${d.toInt()}%" : "${d.toStringAsFixed(2)}%")
            .toList();
        combinedDiscounts.addAll(programDiscounts);

        if (editPopupDiscount != 0.0) {
          final manualDiscountString = editPopupDiscount % 1 == 0
              ? "${editPopupDiscount.toInt()}%"
              : "${editPopupDiscount.toStringAsFixed(2)}%";
          combinedDiscounts.add(manualDiscountString);
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primaryLight,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    '${product.kasur} (${product.ukuran})',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [
                                AppColors.primaryLight,
                                AppColors.primaryLight.withOpacity(0.7)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                        ),
                      ),
                      LayoutBuilder(builder: (context, constraints) {
                        final top = constraints.biggest.height;
                        final double opacity =
                            (top - kToolbarHeight) / (200.0 - kToolbarHeight);

                        return Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: const Icon(
                            Icons.king_bed_outlined,
                            size: 100,
                            color: Colors.white24,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () =>
                        ProductActions.showSharePopup(context, product),
                    tooltip: 'Bagikan Produk',
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildPriceCard(product, netPrice, totalDiscount,
                        combinedDiscounts, installmentMonths),
                    _buildDetailCard(product),
                    _buildBonusAndNotesCard(product, note),
                    const SizedBox(height: 75),
                  ],
                ),
              ),
            ],
          ),
          bottomSheet: _buildActionButtons(context, product, state),
        );
      },
    );
  }

  Widget _buildPriceCard(
      ProductEntity product,
      double netPrice,
      double totalDiscount,
      List<String> combinedDiscounts,
      int? installmentMonths) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Penting untuk scrolling
          children: [
            const Text("Rincian Harga",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 18),
            _buildPriceRow(
              "Pricelist",
              FormatHelper.formatCurrency(product.pricelist),
              isStrikethrough: true,
              valueColor: AppColors.error,
            ),
            _buildPriceRow(
              "Program",
              product.program.isNotEmpty ? product.program : "Tidak ada promo",
            ),
            if (combinedDiscounts.isNotEmpty)
              _buildPriceRow(
                "Diskon Tambahan",
                combinedDiscounts.join(' + '),
                valueColor: AppColors.info,
              ),
            _buildPriceRow(
              "Total Diskon",
              "- ${FormatHelper.formatCurrency(totalDiscount)}",
              valueColor: AppColors.warning,
            ),
            const Divider(height: 18, thickness: 1.5),
            _buildPriceRow(
              "Harga Net",
              FormatHelper.formatCurrency(netPrice),
              isBold: true,
              valueSize: 20,
              valueColor: AppColors.success,
            ),
            if (installmentMonths != null && installmentMonths > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Center(
                  child: Text(
                    "Cicilan: ${FormatHelper.formatCurrency(netPrice / installmentMonths)} x $installmentMonths bulan",
                    style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.info),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(ProductEntity product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Spesifikasi Set",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildSpecRow(Icons.king_bed, "Tipe Kasur", product.kasur),
            if (product.divan.isNotEmpty && product.divan != AppStrings.noDivan)
              _buildSpecRow(Icons.layers, "Tipe Divan", product.divan),
            if (product.headboard.isNotEmpty &&
                product.headboard != AppStrings.noHeadboard)
              _buildSpecRow(
                  Icons.view_headline, "Tipe Headboard", product.headboard),
            if (product.sorong.isNotEmpty &&
                product.sorong != AppStrings.noSorong)
              _buildSpecRow(
                  Icons.arrow_downward, "Tipe Sorong", product.sorong),
            _buildSpecRow(Icons.straighten, "Ukuran", product.ukuran),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusAndNotesCard(ProductEntity product, String note) {
    final hasBonus =
        product.bonus.isNotEmpty && product.bonus.any((b) => b.name.isNotEmpty);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bonus & Catatan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            const Text("Complimentary:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (hasBonus)
              ...product.bonus.where((b) => b.name.isNotEmpty).map(
                    (bonus) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Text("• ${bonus.quantity}x ${bonus.name}"),
                    ),
                  )
            else
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text("Tidak ada bonus.",
                    style: TextStyle(color: Colors.grey)),
              ),
            if (note.isNotEmpty) ...[
              const Divider(height: 24),
              const Text("Catatan:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(note,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, ProductEntity product, ProductState state) {
    final netPrice = state.roundedPrices[product.id] ?? product.endUserPrice;
    final discountPercentages =
        state.productDiscountsPercentage[product.id] ?? [];
    final editPopupDiscount = state.priceChangePercentages[product.id] ?? 0.0;
    int? installmentMonths = state.installmentMonths[product.id];
    double? installmentPerMonth =
        installmentMonths != null && installmentMonths > 0
            ? netPrice / installmentMonths
            : null;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _actionIconButton(context, Icons.credit_card, "Credit",
                  () => ProductActions.showCreditPopup(context, product)),
              const SizedBox(width: 16),
              _actionIconButton(context, Icons.edit, "Edit",
                  () => ProductActions.showEditPopup(context, product)),
              const SizedBox(width: 16),
              _actionIconButton(context, Icons.info_outline, "Info",
                  () => ProductActions.showInfoPopup(context, product)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              context.read<CartBloc>().add(AddToCart(
                    product: product,
                    quantity: 1,
                    netPrice: netPrice,
                    discountPercentages: discountPercentages,
                    editPopupDiscount: editPopupDiscount,
                    installmentMonths: installmentMonths,
                    installmentPerMonth: installmentPerMonth,
                  ));
              CustomToast.showToast(
                  "${product.kasur} ditambahkan", ToastType.success);
            },
            icon: const Icon(Icons.add_shopping_cart, size: 20),
            label: const Text("Add to Cart"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String title, String value,
      {Color? valueColor,
      bool isStrikethrough = false,
      bool isBold = false,
      double valueSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              color: valueColor,
              decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 16),
          Text("$title:", style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value.isNotEmpty ? value : "-", textAlign: TextAlign.end),
        ],
      ),
    );
  }

  Widget _actionIconButton(BuildContext context, IconData icon, String tooltip,
      VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: Colors.grey.shade800, size: 24),
        ),
      ),
    );
  }
}
