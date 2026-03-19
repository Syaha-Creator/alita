import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/order_list_card_frame.dart';
import '../../../../core/widgets/status_chip.dart';

/// A single approval card in the inbox list.
///
/// Receives raw [orderWrap] JSON and renders customer name, item summary,
/// amount, date, and status using the shared [OrderListCardFrame].
class ApprovalCardItem extends StatelessWidget {
  final dynamic orderWrap;
  final bool isPending;

  const ApprovalCardItem({
    super.key,
    required this.orderWrap,
    required this.isPending,
  });

  OrderStatus _statusFromPending() =>
      isPending ? OrderStatus.pending : OrderStatus.approved;

  @override
  Widget build(BuildContext context) {
    final order = orderWrap['order_letter'] as Map<String, dynamic>? ?? {};
    final details =
        orderWrap['order_letter_details'] as List<dynamic>? ?? [];

    final String toko = order['customer_name'] as String? ?? 'Pelanggan';
    final String noSp = order['no_sp'] as String? ?? '-';
    final double amount =
        double.tryParse(order['extended_amount']?.toString() ?? '0') ?? 0;

    final dateDisplay = AppFormatters.shortDateId(
      order['order_date'] as String? ?? '',
    );

    final status = _statusFromPending();
    final statusColor = status.listForegroundColor;
    final statusLabel = isPending ? 'Menunggu' : 'Selesai';

    final int itemCount = details.length;
    final String firstItemName = itemCount > 0
        ? (details[0]['desc_1'] as String? ??
            details[0]['item_description'] as String? ??
            'Item')
        : 'Detail tidak tersedia';

    return OrderListCardFrame(
      referenceNo: noSp,
      trailingStatus: StatusChip(
        label: statusLabel,
        icon: status.icon,
        backgroundColor: statusColor.withValues(alpha: 0.1),
        foregroundColor: statusColor,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accentLight,
            child: Text(
              toko.isNotEmpty ? toko[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toko,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  itemCount > 1
                      ? '$firstItemName  +${itemCount - 1} item lainnya'
                      : firstItemName,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      dateText: dateDisplay,
      totalText: AppFormatters.currencyIdr(amount),
      onTap: () => context.push('/approval_detail', extra: orderWrap),
    );
  }
}
