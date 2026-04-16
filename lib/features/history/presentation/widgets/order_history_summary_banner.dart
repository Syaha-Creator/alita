import 'package:flutter/material.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/price_block.dart';
import '../../data/utils/order_history_list_summary.dart';

/// Ringkasan nominal Riwayat Pesanan — hero = **penjualan sukses** (hanya
/// approved); panel bawah tetap memecah semua status.
class OrderHistorySummaryBanner extends StatelessWidget {
  const OrderHistorySummaryBanner({
    super.key,
    required this.totals,
    required this.filterDescription,
  });

  final OrderHistoryStatusTotals totals;
  final String filterDescription;

  static String _spLabel(int n) => n == 1 ? '1 SP' : '$n SP';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = AppFormatters.currencyIdrFlooredWhole;

    final breakdownLines = <({
      String label,
      int count,
      double amount,
      Color color,
    })>[
      (
        label: 'Disetujui',
        count: totals.approvedCount,
        amount: totals.approvedTotal,
        color: OrderStatus.approved.detailForegroundColor,
      ),
      (
        label: 'Menunggu',
        count: totals.pendingCount,
        amount: totals.pendingTotal,
        color: OrderStatus.pending.detailForegroundColor,
      ),
      (
        label: 'Ditolak',
        count: totals.rejectedCount,
        amount: totals.rejectedTotal,
        color: OrderStatus.rejected.detailForegroundColor,
      ),
      (
        label: 'Lainnya',
        count: totals.unknownCount,
        amount: totals.unknownTotal,
        color: OrderStatus.unknown.detailForegroundColor,
      ),
    ].where((e) => e.count > 0).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayoutTokens.space16),
      child: Semantics(
        container: true,
        label: 'Surat Pesanan ${_spLabel(totals.approvedCount)} periode '
            '$filterDescription, ${fmt(totals.approvedTotal)}. '
            'Total volume ${_spLabel(totals.totalOrders)} ${fmt(totals.grandTotal)}.',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppLayoutTokens.radius16),
            boxShadow: [AppLayoutTokens.cardShadowSoft],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppLayoutTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppLayoutTokens.space6),
                          Expanded(
                            child: Text(
                              'SP Approved (${_spLabel(totals.approvedCount)})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: -0.15,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppLayoutTokens.space8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        filterDescription,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppLayoutTokens.space10),
                PriceBlock(
                  price: totals.approvedTotal,
                  formatPrice: fmt,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  priceStyle: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                if (breakdownLines.isNotEmpty) ...[
                  const SizedBox(height: AppLayoutTokens.space16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(AppLayoutTokens.radius10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppLayoutTokens.space12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < breakdownLines.length; i++) ...[
                            if (i > 0)
                              const SizedBox(height: AppLayoutTokens.space4),
                            _BreakdownRow(
                              label: breakdownLines[i].label,
                              count: breakdownLines[i].count,
                              amount: breakdownLines[i].amount,
                              dotColor: breakdownLines[i].color,
                              formatPrice: fmt,
                            ),
                          ],
                          const Divider(
                            height: AppLayoutTokens.space16,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                          _TotalVolumeRow(
                            label:
                                'Total Volume (${_spLabel(totals.totalOrders)})',
                            grandTotal: totals.grandTotal,
                            formatPrice: fmt,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalVolumeRow extends StatelessWidget {
  const _TotalVolumeRow({
    required this.label,
    required this.grandTotal,
    required this.formatPrice,
  });

  final String label;
  final double grandTotal;
  final String Function(num) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
          ),
        ),
        Text(
          formatPrice(grandTotal),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.amount,
    required this.dotColor,
    required this.formatPrice,
  });

  final String label;
  final int count;
  final double amount;
  final Color dotColor;
  final String Function(num) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppLayoutTokens.space8),
        Expanded(
          child: Text(
            '$label ($count)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
          ),
        ),
        Text(
          formatPrice(amount),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
        ),
      ],
    );
  }
}
