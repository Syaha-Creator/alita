import 'package:flutter/material.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/detail_section_label.dart';
import '../../../../core/widgets/detail_surface_card.dart';
import '../../data/models/order_history.dart';

class ApprovalTimelineWidget extends StatelessWidget {
  const ApprovalTimelineWidget({
    super.key,
    required this.order,
  });

  final OrderHistory order;

  @override
  Widget build(BuildContext context) {
    final approvals = _extractApprovals(order);
    if (approvals.isEmpty) return const SizedBox.shrink();

    return DetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionLabel(title: 'Approval Timeline'),
          const SizedBox(height: AppLayoutTokens.space12),
          ...approvals.asMap().entries.map((entry) {
            final idx = entry.key;
            final approval = entry.value;
            final isLast = idx == approvals.length - 1;
            final status = OrderStatusX.fromRaw(approval.status);
            final approvedAt = approval.approvedAt;
            final hasTimestamp =
                approvedAt != null && approvedAt.isNotEmpty;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status.detailForegroundColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: hasTimestamp ? 50 : 34,
                        color: AppColors.border,
                      ),
                  ],
                ),
                const SizedBox(width: AppLayoutTokens.space10),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppLayoutTokens.space10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          approval.level,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          approval.name,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          approval.status,
                          style: TextStyle(
                            fontSize: 12,
                            color: status.detailForegroundColor,
                          ),
                        ),
                        if (hasTimestamp)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              AppFormatters.dateTimeId(approvedAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<_ApprovalEntry> _extractApprovals(OrderHistory order) {
    final map = <String, _ApprovalEntry>{};
    for (final detail in order.details) {
      for (final discount in detail.discounts) {
        final key = '${discount.approverLevel}|${discount.approverName}';
        map[key] = _ApprovalEntry(
          level: discount.approverLevel,
          name: discount.approverName,
          status: discount.approvedStatus,
          approvedAt: discount.approvedAt,
        );
      }
    }
    return map.values.toList();
  }
}

class _ApprovalEntry {
  const _ApprovalEntry({
    required this.level,
    required this.name,
    required this.status,
    this.approvedAt,
  });

  final String level;
  final String name;
  final String status;
  final String? approvedAt;
}
