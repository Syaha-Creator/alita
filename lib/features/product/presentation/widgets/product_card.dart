import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/format_helper.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/event/product_event.dart';
import '../bloc/product_bloc.dart';
import '../bloc/state/product_state.dart';
import 'product_action.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;

  const ProductCard({super.key, required this.product});

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
                _buildBonusInfo(),
                const SizedBox(height: 12),
                _buildPriceInfo(context, state),
                const SizedBox(height: 16),
                _buildFooterButtons(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Widget untuk menampilkan detail produk
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

  // 🔹 Widget untuk menampilkan informasi bonus
  Widget _buildBonusInfo() {
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
      ],
    );
  }

  // 🔹 Widget untuk menampilkan harga dan diskon
  Widget _buildPriceInfo(BuildContext context, ProductState state) {
    double netPrice = state.roundedPrices[product.id] ?? product.endUserPrice;
    double totalDiscount = product.pricelist - netPrice;

    bool hasDiscountReceived =
        state.priceChangePercentages.containsKey(product.id) &&
            state.priceChangePercentages[product.id]! > 0;
    bool hasInstallment = state.installmentMonths.containsKey(product.id) &&
        state.installmentMonths[product.id]! > 0;

    // Jika tidak ada diskon yang diterima dan tidak ada cicilan, tampilkan default
    if (!hasDiscountReceived && !hasInstallment) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _buildDetailRow(
            "Harga Net",
            FormatHelper.formatCurrency(netPrice),
            isBold: true,
            color: Colors.green,
          ),
        ],
      );
    }

    // Jika ada cicilan atau diskon yang diterima, tampilkan tambahan informasinya
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
      details.add(_buildDetailRow(
        "Diskon yang diterima",
        "${state.priceChangePercentages[product.id]!.toStringAsFixed(2)}%",
        color: Colors.blue,
      ));
    }

    details.add(_buildDetailRow(
      "Harga Net",
      FormatHelper.formatCurrency(netPrice),
      isBold: true,
      color: Colors.green,
    ));

    if (hasInstallment) {
      double monthlyInstallment =
          netPrice / state.installmentMonths[product.id]!;
      details.add(_buildDetailRow(
        "Cicilan",
        "${state.installmentMonths[product.id]} bulan x ${FormatHelper.formatCurrency(monthlyInstallment)}",
        isBold: true,
        color: Colors.blue,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details,
    );
  }

  // 🔹 Widget untuk menampilkan tombol di footer
  Widget _buildFooterButtons(BuildContext context, ProductState state) {
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

// 🔹 Helper untuk membuat row detail
  Widget _buildDetailRow(String title, String value,
      {bool isStrikethrough = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
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
