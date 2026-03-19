import 'package:flutter/material.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/detail_info_row.dart';
import '../../../../core/widgets/detail_surface_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../data/models/order_history.dart';

class OrderStatusHeader extends StatelessWidget {
  const OrderStatusHeader({
    super.key,
    required this.order,
    required this.onCopySp,
  });

  final OrderHistory order;
  final VoidCallback onCopySp;

  @override
  Widget build(BuildContext context) {
    final status = OrderStatusX.fromRaw(order.status);
    final statusColor = status.detailForegroundColor;
    final statusBg = status.detailBackgroundColor;

    return DetailSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                StatusChip(
                  label: order.status,
                  icon: status.icon,
                  backgroundColor: Colors.transparent,
                  foregroundColor: statusColor,
                  padding: EdgeInsets.zero,
                  borderRadius: 0,
                  iconSize: 14,
                  iconSpacing: 6,
                  textStyle: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No. Surat Pesanan',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.noSp,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (order.noPo != null && order.noPo!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'PO: ${order.noPo}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onCopySp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Salin',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: AppColors.divider),
                const SizedBox(height: 14),
                DetailInfoRow(
                  label: 'Tanggal Pesanan',
                  value: AppFormatters.shortDateId(order.orderDate),
                ),
                if (order.requestDate != '-') ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Permintaan Kirim',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppFormatters.shortDateId(order.requestDate),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Metode Kirim',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 12),
                    ),
                    StatusChip(
                      label: order.isTakeAway
                          ? 'Bawa Sendiri (Take Away)'
                          : 'Kurir Pabrik',
                      backgroundColor: order.isTakeAway
                          ? AppColors.surface
                          : AppColors.primary.withValues(alpha: 0.08),
                      foregroundColor: order.isTakeAway
                          ? AppColors.textPrimary
                          : AppColors.primary,
                      textStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: order.isTakeAway
                            ? AppColors.textPrimary
                            : AppColors.primary,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DetailInfoRow(
                  label: 'Lokasi / Toko',
                  value: order.workPlaceName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
