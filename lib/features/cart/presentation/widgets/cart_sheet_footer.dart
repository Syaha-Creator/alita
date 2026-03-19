import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/label_value_row.dart';
import '../../logic/cart_provider.dart';

/// Footer bawah sheet keranjang: Pilih Semua, Total, tombol Checkout.
/// Hanya tampil saat keranjang tidak kosong; total dan checkout mengikuti item terpilih.
class CartSheetFooter extends ConsumerWidget {
  const CartSheetFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAmount = ref.watch(cartSelectedTotalAmountProvider);
    final isAllSelected = ref.watch(isAllSelectedProvider);
    final selectedItems = ref.watch(selectedCartItemsProvider);
    final hasSelection = ref.watch(selectedCartItemIdsProvider).isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        minimum: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 6,
          bottom: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref
                      .read(selectedCartItemIdsProvider.notifier)
                      .toggleSelectAll(!isAllSelected);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 0,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isAllSelected,
                        onChanged: (v) {
                          ref
                              .read(selectedCartItemIdsProvider.notifier)
                              .toggleSelectAll(v ?? false);
                        },
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pilih Semua',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            LabelValueRow(
              label: 'Total',
              value: AppFormatters.currencyIdr(totalAmount),
              labelStyle: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
            ),
            const SizedBox(height: 8),
            ActionButtonBar(
              height: 50,
              borderRadius: 14,
              primaryLabel: 'Checkout',
              primaryLeading: const Icon(Icons.shopping_bag_outlined, size: 20),
              primaryLabelStyle:
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w600,
                      ),
              onPrimaryPressed: hasSelection
                  ? () {
                      Navigator.of(context).pop();
                      context.push('/checkout', extra: selectedItems);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
