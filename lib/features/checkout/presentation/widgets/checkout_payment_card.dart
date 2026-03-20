import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/payment_form_content.dart';
import '../../data/checkout_config.dart';
import '../../data/models/payment_entry.dart';

/// Individual payment form card used inside the checkout payment section.
///
/// Extracted from [CheckoutPage] to keep the page file focused on orchestration.
class CheckoutPaymentCard extends StatelessWidget {
  const CheckoutPaymentCard({
    super.key,
    required this.index,
    required this.entry,
    required this.isMultiPayment,
    required this.isLunas,
    required this.totalAkhir,
    required this.minimumDp,
    required this.onRemove,
    required this.onMethodChanged,
    required this.onChannelChanged,
    required this.onPickDate,
    required this.onPickReceipt,
    required this.onRemoveReceipt,
    required this.onLunasTap,
    required this.onDpTap,
    required this.onAmountChanged,
  });

  final int index;
  final PaymentEntry entry;
  final bool isMultiPayment;
  final bool isLunas;
  final double totalAkhir;
  final double minimumDp;
  final VoidCallback onRemove;
  final ValueChanged<String?> onMethodChanged;
  final ValueChanged<String?> onChannelChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickReceipt;
  final VoidCallback onRemoveReceipt;
  final VoidCallback onLunasTap;
  final VoidCallback onDpTap;
  final ValueChanged<String>? onAmountChanged;

  static String _priceFmt(num value) => AppFormatters.currencyIdr(value);

  bool get _isSingle => !isMultiPayment;
  bool get _singleLunas => _isSingle && isLunas;

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMultiPayment)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Pembayaran ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const Spacer(),
              if (!isFirst)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.error),
                  tooltip: 'Hapus pembayaran',
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        if (isMultiPayment) const SizedBox(height: 12),
        PaymentFormContent(
          showModeToggle: _isSingle,
          leftModeLabel: 'Lunas',
          rightModeLabel: 'Down Payment (DP)',
          isLeftModeSelected: isLunas,
          onTapLeftMode: onLunasTap,
          onTapRightMode: onDpTap,
          amountLabel: isMultiPayment
              ? 'Nominal Pembayaran ${index + 1} *'
              : 'Nominal Pembayaran *',
          amountController: entry.amountCtrl,
          amountReadOnly: _singleLunas,
          amountFilled: _singleLunas,
          amountSuffixIcon: _singleLunas
              ? const Tooltip(
                  message: 'Nominal otomatis = Total Pesanan',
                  child: Icon(Icons.lock_outline,
                      size: 18, color: AppColors.textTertiary),
                )
              : null,
          amountFocusedBorderSide: BorderSide(
            color: _singleLunas ? AppColors.border : AppColors.primary,
            width: _singleLunas ? 1 : 2,
          ),
          onAmountChanged: isMultiPayment ? onAmountChanged : null,
          amountStatusWidget: _isSingle
              ? (!isLunas
                  ? Text(
                      'Minimal DP (30%): ${_priceFmt(minimumDp)}',
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.error),
                    )
                  : const Text(
                      'Nominal mengikuti Total Pesanan (Subtotal + Ongkir)',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ))
              : null,
          paymentMethods: CheckoutConfig.paymentMethods,
          paymentMethod: entry.method,
          paymentChannel: entry.bank,
          customChannelController: entry.otherChannelCtrl,
          paymentChannelsMap: CheckoutConfig.paymentChannelsMap,
          onPaymentMethodChanged: onMethodChanged,
          onPaymentChannelChanged: onChannelChanged,
          referenceLabel: 'No. Referensi / Resi',
          referenceController: entry.refCtrl,
          dateLabel: 'Tanggal Bayar *',
          paymentDate: entry.date,
          onPickDate: onPickDate,
          inlineReferenceAndDate: true,
          showPaymentNote: true,
          paymentNoteController: entry.noteCtrl,
          receiptImage: entry.receiptImage,
          onPickOrEditReceipt: onPickReceipt,
          onRemoveReceipt: onRemoveReceipt,
        ),
      ],
    );
  }
}

/// Chip button for adding a new payment entry.
class AddPaymentChip extends StatelessWidget {
  const AddPaymentChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, minWidth: 72),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16, color: AppColors.accent),
                SizedBox(width: 4),
                Text(
                  'Tambah',
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
      ),
    );
  }
}

/// Multi-payment summary showing total paid vs total order.
class CheckoutPaymentSummary extends StatelessWidget {
  const CheckoutPaymentSummary({
    super.key,
    required this.totalAkhir,
    required this.totalPaid,
  });

  final double totalAkhir;
  final double totalPaid;

  static String _priceFmt(num value) => AppFormatters.currencyIdr(value);

  @override
  Widget build(BuildContext context) {
    final sisa = totalAkhir - totalPaid;
    final isLunas = sisa <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLunas
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLunas
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Total Pesanan', value: _priceFmt(totalAkhir)),
          const SizedBox(height: 6),
          _SummaryRow(label: 'Total Dibayar', value: _priceFmt(totalPaid)),
          const Divider(height: 14, color: AppColors.border),
          _SummaryRow(
            label: 'Sisa',
            value: sisa <= 0 ? 'Rp 0' : _priceFmt(sisa),
            valueColor: isLunas ? AppColors.success : AppColors.error,
            trailing: isLunas
                ? const Icon(Icons.check_circle_rounded,
                    size: 18, color: AppColors.success)
                : null,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLunas
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLunas ? 'LUNAS' : 'DOWN PAYMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isLunas ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            if (trailing case final t?) ...[
              const SizedBox(width: 4),
              t,
            ],
          ],
        ),
      ],
    );
  }
}
