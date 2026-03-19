import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/discount_formatter.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/widgets/price_block.dart';
import '../../data/models/product.dart';
import 'bonus_editor_modal.dart';

/// Displays the complete price section: breakdown per component, discount tile,
/// editable total field, installment simulation, and bonus list.
class ProductPriceSection extends StatelessWidget {
  final Product activeProduct;
  final double finalKasurPrice;
  final double finalDivanPrice;
  final double finalHeadboardPrice;
  final double finalSorongPrice;
  final List<double> appliedDiscounts;
  final double totalFinalPrice;
  final double effectiveTotal;
  final double? targetTotalEup;
  final double baseTotalEup;
  final int selectedInstallmentTenor;
  final List<int> installmentOptions;
  final ValueChanged<int> onInstallmentTenorChanged;

  /// Controller and focus node for the editable total field.
  final TextEditingController targetTotalController;
  final FocusNode totalFocusNode;
  final NumberFormat totalCurrencyFormat;

  /// Called when the user types a new total value.
  final void Function(double? newTarget, List<double> newDiscounts)
      onTargetTotalChanged;

  /// Called when the user taps the reset icon to clear discounts.
  final VoidCallback onResetDiscounts;

  /// Called when the user taps the discount tile (opens discount modal).
  final VoidCallback onDiscountTap;

  /// Bonus data
  final bool isBonusCustomized;
  final List<Map<String, dynamic>> customBonuses;
  final List<Map<String, dynamic>> defaultBonuses;
  final void Function(List<Map<String, dynamic>> newBonuses) onBonusesSaved;

  const ProductPriceSection({
    super.key,
    required this.activeProduct,
    required this.finalKasurPrice,
    required this.finalDivanPrice,
    required this.finalHeadboardPrice,
    required this.finalSorongPrice,
    required this.appliedDiscounts,
    required this.totalFinalPrice,
    required this.effectiveTotal,
    required this.targetTotalEup,
    required this.baseTotalEup,
    required this.selectedInstallmentTenor,
    required this.installmentOptions,
    required this.onInstallmentTenorChanged,
    required this.targetTotalController,
    required this.totalFocusNode,
    required this.totalCurrencyFormat,
    required this.onTargetTotalChanged,
    required this.onResetDiscounts,
    required this.onDiscountTap,
    required this.isBonusCustomized,
    required this.customBonuses,
    required this.defaultBonuses,
    required this.onBonusesSaved,
  });

  @override
  Widget build(BuildContext context) {
    if (targetTotalEup == null && !totalFocusNode.hasFocus) {
      final s = totalCurrencyFormat.format(totalFinalPrice).trim();
      if (targetTotalController.text != s) {
        targetTotalController.text = s;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rincian Harga',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (finalKasurPrice > 0)
          _buildBreakdownRow(
            '${activeProduct.kasur} ${activeProduct.ukuran}'.trim(),
            activeProduct.plKasur,
            finalKasurPrice,
          ),
        if (finalDivanPrice > 0)
          _buildBreakdownRow(
            activeProduct.divan,
            activeProduct.plDivan,
            finalDivanPrice,
          ),
        if (finalHeadboardPrice > 0)
          _buildBreakdownRow(
            activeProduct.headboard,
            activeProduct.plHeadboard,
            finalHeadboardPrice,
          ),
        if (finalSorongPrice > 0)
          _buildBreakdownRow(
            activeProduct.sorong,
            activeProduct.plSorong,
            finalSorongPrice,
          ),
        const SizedBox(height: 16),
        _buildDiscountTile(),
        const SizedBox(height: 16),
        _buildEditableTotalField(context),
        const SizedBox(height: 24),
        const Divider(height: 24),
        _buildBonusSection(context),
      ],
    );
  }

  Widget _buildBreakdownRow(String title, double pricelist, double eup) {
    if (title.toLowerCase().contains('tanpa')) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceBlock(
                price: eup,
                originalPrice: pricelist > eup ? pricelist : null,
                formatPrice: AppFormatters.currencyIdr,
                priceStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                originalPriceStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  decoration: TextDecoration.lineThrough,
                ),
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.local_offer, color: AppColors.accent),
        title: const Text(
          'Diskon Tambahan',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        subtitle: appliedDiscounts.isEmpty
            ? const Text(
                'Belum ada diskon diterapkan',
                style: TextStyle(fontSize: 12),
              )
            : Text(
                appliedDiscounts
                    .where((d) => d > 0)
                    .map(
                      (d) => DiscountFormatter.percentLabel(d * 100),
                    )
                    .join(' + '),
                style: const TextStyle(fontSize: 12),
              ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.accent),
        onTap: onDiscountTap,
      ),
    );
  }

  Widget _buildEditableTotalField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text(
            'Total akhir',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          const Text(
            'Rp ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: TextField(
              controller: targetTotalController,
              focusNode: totalFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsSeparatorInputFormatter(
                  format: (v) => totalCurrencyFormat.format(v).trim(),
                ),
              ],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: TextStyle(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onChanged: (s) {
                final digitsOnly =
                    ThousandsSeparatorInputFormatter.digitsOnly(s);
                final v =
                    digitsOnly.isEmpty ? null : double.tryParse(digitsOnly);
                if (v != null && v > 0) {
                  final newDiscounts = _computeDiscountsFromTargetTotal(
                    v,
                    baseTotalEup,
                  );
                  onTargetTotalChanged(v, newDiscounts);
                } else {
                  onTargetTotalChanged(null, []);
                }
              },
            ),
          ),
          if (targetTotalEup != null)
            Tooltip(
              message: 'Hapus semua diskon tambahan',
              child: GestureDetector(
                onTap: onResetDiscounts,
                child: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<double> _computeDiscountsFromTargetTotal(
    double targetTotal,
    double baseEup,
  ) {
    if (targetTotal >= baseEup || targetTotal <= 0) return [];
    final maxLimits = [
      activeProduct.disc1,
      activeProduct.disc2,
      activeProduct.disc3,
      activeProduct.disc4,
      activeProduct.disc5,
      activeProduct.disc6,
      activeProduct.disc7,
      activeProduct.disc8,
    ].where((d) => d > 0).toList();
    if (maxLimits.isEmpty) return [];
    final result = <double>[];
    double base = baseEup;
    for (final limit in maxLimits) {
      final d = (1 - targetTotal / base).clamp(0.0, limit);
      result.add(d);
      base = base * (1 - d);
    }
    return result;
  }

  Widget _buildBonusSection(BuildContext context) {
    final displayBonuses = isBonusCustomized ? customBonuses : defaultBonuses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Bonus Spesial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            InkWell(
              onTap: () => showBonusEditorModal(
                context,
                defaultBonuses: defaultBonuses,
                isBonusCustomized: isBonusCustomized,
                customBonuses: customBonuses,
                onSave: onBonusesSaved,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: AppColors.accent,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Tukar Bonus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayBonuses.isEmpty)
          const Text(
            'Tidak ada bonus tambahan.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: displayBonuses.map((b) {
              final name = cleanBonusDisplayName(b['name'] as String);
              final qty = b['qty'] as int;
              final pl = (b['pl'] as num?)?.toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${qty}x $name',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (pl != null && pl > 0)
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(pl),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
