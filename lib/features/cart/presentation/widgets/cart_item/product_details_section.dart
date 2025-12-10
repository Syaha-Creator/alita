import 'package:flutter/material.dart';

import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../product/domain/entities/product_entity.dart';

/// Widget untuk menampilkan detail produk di cart item
class ProductDetailsSection extends StatelessWidget {
  final ProductEntity product;
  final bool isDark;
  final void Function(String type, String currentValue) onShowOptions;
  final Future<List<String>> Function(ProductEntity product) getSorongOptions;

  static const Radius radius = Radius.circular(12);

  const ProductDetailsSection({
    super.key,
    required this.product,
    required this.isDark,
    required this.onShowOptions,
    required this.getSorongOptions,
  });

  @override
  Widget build(BuildContext context) {
    final baseTextStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final TextStyle styleLabel =
        baseTextStyle.copyWith(fontWeight: FontWeight.w600);
    final TextStyle styleValue =
        baseTextStyle.copyWith(fontWeight: FontWeight.w500);

    return Container(
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
        borderRadius: const BorderRadius.all(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detail Produk',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: AppPadding.p10 / 2),
          _buildDropdownRow(
            context,
            Icons.table_chart,
            'Divan',
            product.divan,
            styleLabel,
            styleValue,
            'divan',
          ),
          _buildDropdownRow(
            context,
            Icons.view_headline,
            'Headboard',
            product.headboard,
            styleLabel,
            styleValue,
            'headboard',
          ),
          _buildConditionalSorongDropdown(
            context,
            styleLabel,
            styleValue,
          ),
          _buildDropdownRow(
            context,
            Icons.straighten,
            'Ukuran',
            product.ukuran,
            styleLabel,
            styleValue,
            'ukuran',
          ),
          _detailRow(
              Icons.local_offer,
              'Program',
              product.program.isNotEmpty ? product.program : 'Tidak ada promo',
              styleLabel,
              styleValue),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(
    BuildContext context,
    IconData icon,
    String label,
    String currentValue,
    TextStyle labelStyle,
    TextStyle valueStyle,
    String type,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
          ),
          const SizedBox(width: AppPadding.p8),
          Expanded(
            child: Text(
              '$label ',
              style: labelStyle.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => onShowOptions(type, currentValue),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.accentDark.withValues(alpha: 0.3)
                        : AppColors.accentLight.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentValue.isNotEmpty ? currentValue : '-',
                        style: valueStyle.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionalSorongDropdown(
    BuildContext context,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return FutureBuilder<List<String>>(
      future: getSorongOptions(product),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Loading state - show nothing while loading
          return const SizedBox.shrink();
        }

        final sorongOptions = snapshot.data!;

        // Only show sorong dropdown if there are more than 1 option
        if (sorongOptions.length > 1) {
          return _buildDropdownRow(
            context,
            Icons.storage,
            'Sorong',
            product.sorong,
            labelStyle,
            valueStyle,
            'sorong',
          );
        } else {
          // Don't show sorong dropdown if only 1 option
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      TextStyle labelStyle, TextStyle valueStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
          ),
          const SizedBox(width: AppPadding.p8),
          Expanded(
            child: Text(
              '$label ',
              style: labelStyle.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Text(
            value.isNotEmpty ? value : '-',
            style: (valueStyle).copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

