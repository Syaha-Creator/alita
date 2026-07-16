import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/store_discount_calculator.dart';

/// Kartu diskon toko (indirect) dengan toggle on/off dan tap untuk edit tier.
class IndirectStoreDiscountSection extends StatelessWidget {
  const IndirectStoreDiscountSection({
    super.key,
    required this.isLoading,
    required this.useStoreDiscount,
    required this.discounts,
    required this.onUseStoreDiscountChanged,
    required this.onEditTap,
    this.catcodeHint,
  });

  final bool isLoading;
  final bool useStoreDiscount;
  final List<double> discounts;
  final ValueChanged<bool> onUseStoreDiscountChanged;
  final VoidCallback onEditTap;
  final String? catcodeHint;

  @override
  Widget build(BuildContext context) {
    final summary = useStoreDiscount && discounts.isNotEmpty
        ? StoreDiscountCalculator.formatDisplay(discounts)
        : 'Diskon toko dimatikan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Diskon Toko',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch.adaptive(
                value: useStoreDiscount,
                onChanged: discounts.isEmpty && !useStoreDiscount
                    ? null
                    : onUseStoreDiscountChanged,
              ),
          ],
        ),
        if (catcodeHint != null && catcodeHint!.trim().isNotEmpty) ...[
          const SizedBox(height: AppLayoutTokens.space4),
          Text(
            'Cabang: ${catcodeHint!.trim()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
        const SizedBox(height: AppLayoutTokens.space8),
        Material(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
          child: InkWell(
            onTap: isLoading ? null : onEditTap,
            borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppLayoutTokens.space12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: useStoreDiscount && discounts.isNotEmpty
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppLayoutTokens.space4),
                        Text(
                          isLoading
                              ? 'Memuat diskon toko...'
                              : 'Ketuk untuk tambah, ubah, atau hapus tier',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
