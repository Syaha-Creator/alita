import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/order_list_card_frame.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../history/data/models/order_history.dart';
import '../../../history/presentation/order_detail_route_args.dart';

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

  OrderStatus _resolveDisplayStatus() {
    if (isPending) return OrderStatus.pending;

    final order = orderWrap is Map
        ? Map<String, dynamic>.from(orderWrap as Map)
        : <String, dynamic>{};
    final letter = order['order_letter'] as Map<String, dynamic>? ?? {};
    final header = OrderStatusX.fromRaw(letter['status']?.toString() ?? '');
    if (header == OrderStatus.rejected) return OrderStatus.rejected;

    final details = order['order_letter_details'] as List<dynamic>? ?? [];
    for (final detail in details) {
      if (detail is! Map) continue;
      final discounts = detail['order_letter_discount'] as List<dynamic>? ?? [];
      for (final disc in discounts) {
        if (disc is! Map) continue;
        if (OrderStatusX.fromDynamic(disc['approved']) == OrderStatus.rejected) {
          return OrderStatus.rejected;
        }
      }
    }
    return OrderStatus.approved;
  }

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

    final status = _resolveDisplayStatus();
    final statusColor = status.listForegroundColor;
    final statusLabel = switch (status) {
      OrderStatus.pending => 'Menunggu',
      OrderStatus.rejected => 'Ditolak',
      _ => 'Selesai',
    };

    final int itemCount = details.length;
    final String firstItemName = itemCount > 0
        ? (() {
            final d = details[0] as Map<String, dynamic>;
            final desc = (d['item_description'] as String? ?? '').trim();
            return desc.isNotEmpty ? desc : (d['desc_1'] as String? ?? 'Item');
          })()
        : 'Detail tidak tersedia';

    return Semantics(
      button: true,
      label: 'Lihat detail approval $toko',
      child: OrderListCardFrame(
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
      onTap: () {
        hapticTap();
        final map = Map<String, dynamic>.from(orderWrap as Map);
        if (isPending) {
          context.push('/approval_detail', extra: map);
        } else {
          final orderHistory = OrderHistory.fromApiJson(map);
          context.push(
            '/order_detail',
            extra: OrderDetailRouteArgs(
              order: orderHistory,
              allowVoidFromApprovalContext: true,
            ),
          );
        }
      },
      ),
    );
  }
}
