import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../core/widgets/detail_info_row.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/product_entity.dart';

/// Section showing individual item prices for a set product
class IndividualPricingSection extends StatelessWidget {
  final ProductEntity product;

  const IndividualPricingSection({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.attach_money,
                color: AppColors.success,
                size: 16,
              ),
              const SizedBox(width: AppPadding.p8),
              Text(
                "Harga per Item:",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p8),

          // Item prices
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
}

