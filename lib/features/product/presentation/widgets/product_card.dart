import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/widgets/detail_info_row.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_state.dart';
import 'product_action.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final bool hideButtons;

  const ProductCard({
    super.key,
    required this.product,
    this.hideButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) {
        final id = product.id;
        return previous.roundedPrices[id] != current.roundedPrices[id] ||
            previous.productDiscountsPercentage[id] !=
                current.productDiscountsPercentage[id] ||
            previous.productNotes[id] != current.productNotes[id] ||
            previous.installmentMonths[id] != current.installmentMonths[id];
      },
      builder: (context, state) {
        final netPrice =
            state.roundedPrices[product.id] ?? product.endUserPrice;
        final discountPercentages =
            state.productDiscountsPercentage[product.id] ?? [];
        final editPopupDiscount =
            state.priceChangePercentages[product.id] ?? 0.0;
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductDetail(),
                const SizedBox(height: 12),
                _buildPriceInfo(context, state),
                const SizedBox(height: 12),
                _buildBonusInfo(state),
                if (!hideButtons) ...[
                  const SizedBox(height: 16),
                  _buildFooterButtons(context, state, netPrice,
                      discountPercentages, editPopupDiscount),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailInfoRow(title: "Kasur", value: product.kasur),
        DetailInfoRow(title: "Divan", value: product.divan),
        DetailInfoRow(title: "Headboard", value: product.headboard),
        DetailInfoRow(title: "Sorong", value: product.sorong),
        DetailInfoRow(title: "Ukuran", value: product.ukuran),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context, ProductState state) {
    final netPrice = state.roundedPrices[product.id] ?? product.endUserPrice;
    final totalDiscount = product.pricelist - netPrice;

    List<double> discountPercentages =
        state.productDiscountsPercentage[product.id] ?? [];
    double editPopupDiscount = state.priceChangePercentages[product.id] ?? 0.0;

    List<String> discountList = discountPercentages
        .where((d) => d > 0.0)
        .map((d) => "${d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2)}%")
        .toList();
    if (editPopupDiscount != 0.0) {
      discountList.add(
          "${editPopupDiscount.toStringAsFixed(editPopupDiscount.truncateToDouble() == editPopupDiscount ? 0 : 2)}%");
    }
    String formattedDiscounts =
        discountList.isNotEmpty ? discountList.join(" + ") : "( -)";
    bool hasDiscountReceived = discountList.isNotEmpty;
    bool hasInstallment = state.installmentMonths.containsKey(product.id) &&
        state.installmentMonths[product.id]! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailInfoRow(
            title: "Pricelist",
            value: FormatHelper.formatCurrency(product.pricelist),
            isStrikethrough: true,
            valueColor: Colors.red.shade700),
        DetailInfoRow(
            title: "Program",
            value: product.program.isNotEmpty
                ? product.program
                : "Tidak ada promo"),
        if (hasDiscountReceived)
          DetailInfoRow(
              title: "Plus Diskon",
              value: formattedDiscounts,
              valueColor: Colors.blue),
        DetailInfoRow(
            title: "Harga Net",
            value: FormatHelper.formatCurrency(netPrice),
            isBoldValue: true,
            valueColor: Colors.green),
        if (hasInstallment)
          DetailInfoRow(
              title: "Cicilan",
              value:
                  "${state.installmentMonths[product.id]} bulan x ${FormatHelper.formatCurrency(netPrice / state.installmentMonths[product.id]!)}",
              isBoldValue: true,
              valueColor: Colors.blue),
        DetailInfoRow(
            title: "Total Diskon",
            value: "- ${FormatHelper.formatCurrency(totalDiscount)}",
            valueColor: Colors.orange),
      ],
    );
  }

  Widget _buildBonusInfo(ProductState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Complimentary :",
            style: TextStyle(fontWeight: FontWeight.bold)),
        if (product.bonus.isNotEmpty)
          ...product.bonus.where((b) => b.name.isNotEmpty).map(
                (bonus) => Text("• ${bonus.quantity}x ${bonus.name}",
                    style: const TextStyle(fontSize: 14)),
              ),
        if (product.bonus.isEmpty || product.bonus.every((b) => b.name.isEmpty))
          const Text("Tidak ada bonus.",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        if (state.productNotes.containsKey(product.id) &&
            state.productNotes[product.id]!.isNotEmpty)
          Text(
            "Catatan: ${state.productNotes[product.id]}",
            style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.blueAccent),
          ),
      ],
    );
  }

  Widget _buildFooterButtons(
      BuildContext context,
      ProductState state,
      double netPrice,
      List<double> discountPercentages,
      double editPopupDiscount) {
    int? installmentMonths = state.installmentMonths[product.id];
    double? installmentPerMonth =
        installmentMonths != null && installmentMonths > 0
            ? netPrice / installmentMonths
            : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconButton(Icons.credit_card, "Credit", Colors.green, () {
          ProductActions.showCreditPopup(context, product);
        }),
        _buildIconButton(Icons.edit, "Edit", Colors.blue, () {
          ProductActions.showEditPopup(context, product);
        }),
        _buildIconButton(Icons.info_outline, "Info", Colors.orange, () {
          ProductActions.showInfoPopup(context, product);
        }),
        _buildIconButton(Icons.share, "Share", Colors.teal, () {
          ProductActions.showSharePopup(context, product);
        }),
        _buildIconButton(Icons.add_shopping_cart, "Add to Cart", Colors.purple,
            () {
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
              "${product.kasur} ditambahkan ke keranjang", ToastType.success);
        }),
      ],
    );
  }

  Widget _buildIconButton(
      IconData icon, String tooltip, Color color, VoidCallback onPressed) {
    return Flexible(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 30, color: color),
          ),
        ),
      ),
    );
  }
}
