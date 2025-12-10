import 'package:flutter/material.dart';

import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../core/widgets/price_row.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/cart_entity.dart';

/// Widget untuk menampilkan informasi harga di cart item
class PriceInfoSection extends StatelessWidget {
  final CartEntity item;
  final bool isDark;
  final VoidCallback onShowPriceActions;

  static const Radius radius = Radius.circular(12);

  const PriceInfoSection({
    super.key,
    required this.item,
    required this.isDark,
    required this.onShowPriceActions,
  });

  Widget _priceRow(String label, String value, TextStyle valueStyle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p10 / 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netPrice = item.netPrice;
    final totalDiscount = item.product.pricelist - netPrice;

    final discounts = <double>[...item.discountPercentages];
    final formattedDiscounts = discounts
        .where((d) => d > 0)
        .map((d) => d % 1 == 0 ? '${d.toInt()}%' : '${d.toStringAsFixed(2)}%')
        .join(' + ');
    final hasInstallment = (item.installmentMonths ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.all(radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Informasi Harga',
                  style: (Theme.of(context).textTheme.titleSmall ??
                          const TextStyle())
                      .copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                icon: Icon(Icons.edit,
                    size: 20,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                onPressed: onShowPriceActions,
                tooltip: 'Edit/Info Harga',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p10 / 2),
          // Menggunakan PriceRow widget yang reusable
          PriceRow.strikethrough(
            label: 'Pricelist',
            value: item.product.pricelist,
          ),
          PriceRow.discount(
            label: 'Total Diskon',
            value: totalDiscount,
          ),
          if (formattedDiscounts.isNotEmpty)
            _priceRow(
                'Plus Diskon',
                formattedDiscounts,
                TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: isDark ? AppColors.accentDark : AppColors.info),
                isDark),
          if (hasInstallment)
            _priceRow(
                'Cicilan',
                '${item.installmentMonths} bulan x ${FormatHelper.formatCurrency(item.installmentPerMonth ?? 0)}',
                TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: isDark ? AppColors.accentDark : AppColors.info),
                isDark),
          PriceRow.total(
            label: 'Harga Net',
            value: netPrice,
          ),
        ],
      ),
    );
  }
}

