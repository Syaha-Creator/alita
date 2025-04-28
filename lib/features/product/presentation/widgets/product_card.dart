import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/event/cart_event.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/event/product_event.dart';
import '../bloc/product_bloc.dart';
import '../bloc/state/product_state.dart';
import 'product_action.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final bool hideButtons;

  const ProductCard(
      {super.key, required this.product, this.hideButtons = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
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
                _buildBonusInfo(state),
                const SizedBox(height: 12),
                _buildPriceInfo(context, state),
                if (!hideButtons) const SizedBox(height: 16),
                if (!hideButtons) _buildFooterButtons(context, state),
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
        _buildDetailRow("Kasur", product.kasur),
        _buildDetailRow("Divan", product.divan),
        _buildDetailRow("Headboard", product.headboard),
        _buildDetailRow("Sorong", product.sorong),
        _buildDetailRow("Ukuran", product.ukuran),
        _buildDetailRow("Program",
            product.program.isNotEmpty ? product.program : "Tidak ada promo"),
      ],
    );
  }

  Widget _buildBonusInfo(ProductState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Bonus:", style: TextStyle(fontWeight: FontWeight.bold)),
        if (product.bonus.isNotEmpty)
          ...product.bonus.map(
            (bonus) => Text("• ${bonus.quantity}x ${bonus.name}",
                style: const TextStyle(fontSize: 14)),
          ),
        if (product.bonus.isEmpty)
          const Text("Tidak ada bonus.",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        if (state.productNotes.containsKey(product.id) &&
            state.productNotes[product.id]!.isNotEmpty)
          Text(
            "Catatan: ${state.productNotes[product.id]}",
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context, ProductState state) {
    double netPrice = state.roundedPrices[product.id] ?? product.endUserPrice;
    double totalDiscount = product.pricelist - netPrice;

    List<double> discountPercentages =
        state.productDiscountsPercentage[product.id] ?? [];
    double editPopupDiscount = state.priceChangePercentages[product.id] ?? 0.0;

    List<String> discountList = discountPercentages
        .where((d) => d > 0.0)
        .map((d) => d % 1 == 0 ? "${d.toInt()}%" : "${d.toStringAsFixed(2)}%")
        .toList();

    if (editPopupDiscount != 0.0) {
      discountList.add(editPopupDiscount % 1 == 0
          ? "${editPopupDiscount.toInt()}%"
          : "${editPopupDiscount.toStringAsFixed(2)}%");
    }
    String formattedDiscounts =
        discountList.isNotEmpty ? discountList.join(" + ") : "( -)";

    bool hasDiscountReceived = discountList.isNotEmpty;
    bool hasInstallment = state.installmentMonths.containsKey(product.id) &&
        state.installmentMonths[product.id]! > 0;

    List<Widget> details = [
      _buildDetailRow(
        "Pricelist",
        FormatHelper.formatCurrency(product.pricelist),
        isStrikethrough: true,
        color: Colors.red.shade700,
      ),
      _buildDetailRow(
        "Total Diskon",
        "- ${FormatHelper.formatCurrency(totalDiscount)}",
        color: Colors.orange,
      ),
    ];

    if (hasDiscountReceived) {
      details.add(
        _buildDetailRow(
          "Plus Diskon",
          formattedDiscounts,
          color: Colors.blue,
        ),
      );
    }
    details.add(
      _buildDetailRow(
        "Harga Net",
        FormatHelper.formatCurrency(netPrice),
        isBold: true,
        color: Colors.green,
      ),
    );

    if (hasInstallment) {
      double monthlyInstallment =
          netPrice / state.installmentMonths[product.id]!;
      details.add(
        _buildDetailRow(
          "Cicilan",
          "${state.installmentMonths[product.id]} bulan x ${FormatHelper.formatCurrency(monthlyInstallment)}",
          isBold: true,
          color: Colors.blue,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details,
    );
  }

  Widget _buildFooterButtons(BuildContext context, ProductState state) {
    double netPrice = state.roundedPrices[product.id] ?? product.endUserPrice;
    List<double> discountPercentages =
        state.productDiscountsPercentage[product.id] ?? [];
    double editPopupDiscount = state.priceChangePercentages[product.id] ?? 0.0;
    int? installmentMonths = state.installmentMonths[product.id];
    double? installmentPerMonth =
        installmentMonths != null && installmentMonths > 0
            ? netPrice / installmentMonths
            : null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconButton(Icons.credit_card, "Credit", Colors.green, () {
          context.read<ProductBloc>().add(SelectProduct(product));
          ProductActions.showCreditPopup(context, product);
        }),
        _buildIconButton(Icons.edit, "Edit", Colors.blue, () {
          context.read<ProductBloc>().add(SelectProduct(product));
          ProductActions.showEditPopup(context, product);
        }),
        _buildIconButton(Icons.help_outline, "Info", Colors.orange, () {
          context.read<ProductBloc>().add(SelectProduct(product));
          ProductActions.showInfoPopup(context, product);
        }),
        _buildIconButton(Icons.share, "Share", Colors.teal, () {
          context.read<ProductBloc>().add(SelectProduct(product));
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

  Widget _buildDetailRow(String title, String value,
      {bool isStrikethrough = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
          ),
          Text(
            ": ",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: GoogleFonts.montserrat().fontFamily),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  color: color,
                  decoration:
                      isStrikethrough ? TextDecoration.lineThrough : null),
            ),
          ),
        ],
      ),
    );
  }
}
