import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_state.dart';
import '../widgets/product_action.dart';
import '../../../../services/approval_service.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../features/approval/presentation/bloc/approval_bloc.dart';
import '../../../../features/approval/presentation/bloc/approval_state.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ApprovalBloc, ApprovalState>(
      listener: (context, state) {
        if (state is ApprovalSuccess) {
          CustomToast.showToast(state.message, ToastType.success);
        } else if (state is ApprovalError) {
          CustomToast.showToast(state.message, ToastType.error);
        }
      },
      child: BlocBuilder<ProductBloc, ProductState>(
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

          return Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  stretch: true,
                  backgroundColor:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
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
                                  isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight,
                                  (isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight)
                                      .withOpacity(0.7)
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
                          combinedDiscounts, installmentMonths, isDark),
                      _buildDetailCard(product, isDark),
                      _buildBonusAndNotesCard(product, note, isDark),
                      const SizedBox(height: 75),
                    ],
                  ),
                ),
              ],
            ),
            bottomSheet: _buildActionButtons(context, product, state, isDark),
          );
        },
      ),
    );
  }

  Widget _buildPriceCard(
      ProductEntity product,
      double netPrice,
      double totalDiscount,
      List<String> combinedDiscounts,
      int? installmentMonths,
      bool isDark) {
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
            Text(
              "Rincian Harga",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const Divider(height: 18),
            _buildPriceRow(
              "Pricelist",
              FormatHelper.formatCurrency(product.pricelist),
              isStrikethrough: true,
              valueColor: AppColors.primaryLight,
              isDark: isDark,
            ),
            _buildPriceRow(
              "Program",
              product.program.isNotEmpty ? product.program : "Tidak ada promo",
              isDark: isDark,
            ),
            if (combinedDiscounts.isNotEmpty)
              _buildPriceRow(
                "Diskon Tambahan",
                combinedDiscounts.join(' + '),
                valueColor: AppColors.info,
                isDark: isDark,
              ),
            _buildPriceRow(
              "Total Diskon",
              "- ${FormatHelper.formatCurrency(totalDiscount)}",
              valueColor: AppColors.error,
              isDark: isDark,
            ),
            const Divider(height: 18, thickness: 1.5),
            _buildPriceRow(
              "Harga Net",
              FormatHelper.formatCurrency(netPrice),
              isBold: true,
              valueSize: 20,
              valueColor: AppColors.success,
              isDark: isDark,
            ),
            if (installmentMonths != null && installmentMonths > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Center(
                  child: Text(
                    "Cicilan: ${FormatHelper.formatCurrency(netPrice / installmentMonths)} x $installmentMonths bulan",
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.accentDark : AppColors.info,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(ProductEntity product, bool isDark) {
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
            Text(
              "Spesifikasi Set",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const Divider(height: 24),
            _buildSpecRow(Icons.king_bed, "Tipe Kasur", product.kasur, isDark),
            if (product.divan.isNotEmpty && product.divan != AppStrings.noDivan)
              _buildSpecRow(Icons.layers, "Tipe Divan", product.divan, isDark),
            if (product.headboard.isNotEmpty &&
                product.headboard != AppStrings.noHeadboard)
              _buildSpecRow(Icons.view_headline, "Tipe Headboard",
                  product.headboard, isDark),
            if (product.sorong.isNotEmpty &&
                product.sorong != AppStrings.noSorong)
              _buildSpecRow(
                  Icons.arrow_downward, "Tipe Sorong", product.sorong, isDark),
            _buildSpecRow(Icons.straighten, "Ukuran", product.ukuran, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusAndNotesCard(
      ProductEntity product, String note, bool isDark) {
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
            Text(
              "Bonus & Catatan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const Divider(height: 24),
            Text(
              "Complimentary:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            if (hasBonus)
              ...product.bonus.where((b) => b.name.isNotEmpty).map(
                    (bonus) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Text(
                        "• ${bonus.quantity}x ${bonus.name}",
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  )
            else
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Tidak ada bonus.",
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                  ),
                ),
              ),
            if (note.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                "Catatan:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(
                  note,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProductEntity product,
      ProductState state, bool isDark) {
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
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
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
              _actionIconButton(
                  context,
                  Icons.credit_card,
                  "Credit",
                  () => ProductActions.showCreditPopup(context, product),
                  isDark),
              const SizedBox(width: 16),
              _actionIconButton(context, Icons.edit, "Edit",
                  () => ProductActions.showEditPopup(context, product), isDark),
              const SizedBox(width: 16),
              _actionIconButton(context, Icons.info_outline, "Info",
                  () => ProductActions.showInfoPopup(context, product), isDark),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showApprovalDialog(context, product),
            icon: const Icon(Icons.approval),
            label: const Text('Send for Approval'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
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
      double valueSize = 16,
      bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontSize: valueSize,
                color: valueColor,
                decoration: isStrikethrough ? TextDecoration.lineThrough : null,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? AppColors.accentDark : AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            "$title:",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const Spacer(),
          Text(
            value.isNotEmpty ? value : "-",
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIconButton(BuildContext context, IconData icon, String tooltip,
      VoidCallback onPressed, bool isDark) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: CircleAvatar(
          radius: 22,
          backgroundColor:
              isDark ? AppColors.surfaceDark : Colors.grey.shade200,
          child: Icon(
            icon,
            color: isDark ? AppColors.textPrimaryDark : Colors.grey.shade800,
            size: 24,
          ),
        ),
      ),
    );
  }

  Future<void> _showApprovalDialog(
      BuildContext context, ProductEntity product) async {
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();
    final quantityController =
        TextEditingController(text: '1'); // Default quantity

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send for Approval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                hintText: 'Enter customer name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Customer Phone',
                hintText: 'Enter customer phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter quantity',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (customerNameController.text.isEmpty ||
                  customerPhoneController.text.isEmpty ||
                  quantityController.text.isEmpty) {
                CustomToast.showToast(
                    'Please fill in all fields', ToastType.error);
                return;
              }

              final quantity = int.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                CustomToast.showToast(
                    'Please enter a valid quantity', ToastType.error);
                return;
              }

              Navigator.of(dialogContext).pop();

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                // Get current product state for discount percentages
                final productState = context.read<ProductBloc>().state;
                final discountPercentages =
                    productState.productDiscountsPercentage[product.id] ?? [];
                final netPrice = productState.roundedPrices[product.id] ??
                    product.endUserPrice;
                final editPopupDiscount =
                    productState.priceChangePercentages[product.id] ?? 0.0;

                final result = await ApprovalService.createApprovalFromProduct(
                  product: product,
                  quantity: quantity,
                  netPrice: netPrice,
                  customerName: customerNameController.text,
                  customerPhone: customerPhoneController.text,
                  discountPercentages: discountPercentages,
                  editPopupDiscount: editPopupDiscount,
                );

                Navigator.of(context).pop(); // Close loading

                if (result['success']) {
                  CustomToast.showToast(
                      'Approval request sent successfully', ToastType.success);
                } else {
                  CustomToast.showToast(result['message'], ToastType.error);
                }
              } catch (e) {
                Navigator.of(context).pop(); // Close loading
                CustomToast.showToast(
                    'Error sending approval: $e', ToastType.error);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
