import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';
import '../../../data/models/approval_model.dart';

/// Widget to display approval info section with leader details
class ApprovalInfoSection extends StatelessWidget {
  final String status;
  final LeaderByUserModel? leaderData;

  const ApprovalInfoSection({
    super.key,
    required this.status,
    this.leaderData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.info),
              const SizedBox(width: AppPadding.p8),
              Text(
                'Informasi Approval',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p8),

          // Status row
          _buildInfoRow(
            icon: _getStatusIcon(status),
            iconColor: _getStatusColor(status),
            text: 'Status: $status',
            textColor: _getStatusColor(status),
            fontWeight: FontWeight.w600,
            theme: theme,
          ),
          const SizedBox(height: AppPadding.p8),

          // Leader info
          if (leaderData?.directLeader != null) ...[
            _buildInfoRow(
              icon: Icons.person_rounded,
              iconColor: colorScheme.onSurfaceVariant,
              text: 'Supervisor: ${leaderData!.directLeader!.fullName}',
              textColor: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              theme: theme,
            ),
            const SizedBox(height: AppPadding.p4),
            _buildInfoRow(
              icon: Icons.work_rounded,
              iconColor: colorScheme.onSurfaceVariant,
              text: 'Jabatan: ${leaderData!.directLeader!.workTitle}',
              textColor: colorScheme.onSurfaceVariant,
              fontSize: 10,
              theme: theme,
            ),
          ] else ...[
            _buildInfoRow(
              icon: Icons.warning_rounded,
              iconColor: AppColors.warning,
              text: 'Tidak ada atasan langsung yang ditemukan',
              textColor: AppColors.warning,
              fontWeight: FontWeight.w500,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    required ThemeData theme,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: AppPadding.p8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }
}
