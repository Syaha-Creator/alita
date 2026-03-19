import 'package:flutter/material.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/contact_actions.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/detail_info_row.dart';
import '../../../../core/widgets/detail_surface_card.dart';
import '../../../../core/widgets/status_chip.dart';

/// Header card showing SP number, status strip, dates, shipping method,
/// and workplace info. Mirrors the design from OrderDetailPage.
class ApprovalHeaderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  /// Root-level `orderData` map — needed to resolve `work_place_name`.
  final Map<String, dynamic> orderData;

  const ApprovalHeaderCard({
    super.key,
    required this.order,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final noSp = order['no_sp'] as String? ?? '-';
    final orderDate = order['order_date'] as String? ?? '';
    final requestDate = order['request_date'] as String? ?? '';
    final status = order['status'] as String? ?? OrderStatus.pending.apiValue;
    final noPo = order['no_po'] as String? ?? '';
    final workPlace = orderData['work_place_name']?.toString() ??
        orderData['workplace_name']?.toString() ??
        order['work_place_name'] as String? ??
        order['workplace_name'] as String? ??
        order['work_place'] as String? ??
        '';
    final isTakeAway = (order['is_take_away'] as bool?) ??
        (order['take_away']?.toString() == 'true');

    final statusEnum = OrderStatusX.fromRaw(status);
    final statusColor = statusEnum.detailForegroundColor;
    final statusBg = statusEnum.detailBackgroundColor;
    final statusIcon = statusEnum.icon;

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
                  label: status,
                  icon: statusIcon,
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
                            noSp,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (noPo.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'PO: $noPo',
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
                      onTap: () {
                        ContactActions.copyText(
                          context,
                          text: noSp,
                          successMessage: 'No SP berhasil disalin',
                          duration: const Duration(seconds: 2),
                        );
                      },
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
                  value: orderDate.isNotEmpty
                      ? AppFormatters.shortDateId(orderDate)
                      : '-',
                ),
                if (requestDate.isNotEmpty && requestDate != '-') ...[
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
                          AppFormatters.shortDateId(requestDate),
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
                      label: isTakeAway
                          ? 'Bawa Sendiri (Take Away)'
                          : 'Kurir Pabrik',
                      backgroundColor: isTakeAway
                          ? AppColors.surface
                          : AppColors.primary.withValues(alpha: 0.08),
                      foregroundColor: isTakeAway
                          ? AppColors.textPrimary
                          : AppColors.primary,
                      textStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isTakeAway
                            ? AppColors.textPrimary
                            : AppColors.primary,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                    ),
                  ],
                ),
                if (workPlace.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DetailInfoRow(label: 'Lokasi / Toko', value: workPlace),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
