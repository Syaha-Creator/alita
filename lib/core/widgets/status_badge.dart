import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Enum untuk jenis status yang didukung
enum StatusType {
  pending,
  approved,
  rejected,
  info,
  warning,
  success,
  error,
  custom,
}

/// Widget badge/chip untuk menampilkan status dengan icon dan warna yang konsisten.
/// Digunakan di berbagai tempat seperti ApprovalCard, OrderLetterDocument, dll.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final Color? customColor;
  final IconData? customIcon;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.info,
    this.customColor,
    this.customIcon,
    this.fontSize = 11,
    this.padding,
    this.borderRadius = 12,
    this.showIcon = true,
  });

  /// Factory constructor untuk status approval
  factory StatusBadge.fromStatus(String status, {double? fontSize}) {
    final statusLower = status.toLowerCase();
    StatusType type;

    switch (statusLower) {
      case 'pending':
        type = StatusType.pending;
        break;
      case 'approved':
        type = StatusType.approved;
        break;
      case 'rejected':
        type = StatusType.rejected;
        break;
      default:
        type = StatusType.info;
    }

    return StatusBadge(
      label: status,
      type: type,
      fontSize: fontSize,
    );
  }

  Color _getColor() {
    if (customColor != null) return customColor!;

    switch (type) {
      case StatusType.pending:
        return AppColors.warning;
      case StatusType.approved:
      case StatusType.success:
        return AppColors.success;
      case StatusType.rejected:
      case StatusType.error:
        return AppColors.error;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.info:
      case StatusType.custom:
        return AppColors.info;
    }
  }

  IconData _getIcon() {
    if (customIcon != null) return customIcon!;

    switch (type) {
      case StatusType.pending:
        return Icons.pending_actions_rounded;
      case StatusType.approved:
      case StatusType.success:
        return Icons.check_circle_rounded;
      case StatusType.rejected:
      case StatusType.error:
        return Icons.cancel_rounded;
      case StatusType.warning:
        return Icons.warning_rounded;
      case StatusType.info:
      case StatusType.custom:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final theme = Theme.of(context);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getIcon(),
              color: theme.colorScheme.onPrimary,
              size: (fontSize ?? 11) + 3,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget untuk menampilkan badge dengan background transparan (outline style)
class StatusBadgeOutline extends StatelessWidget {
  final String label;
  final StatusType type;
  final Color? customColor;
  final IconData? customIcon;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool showIcon;

  const StatusBadgeOutline({
    super.key,
    required this.label,
    this.type = StatusType.info,
    this.customColor,
    this.customIcon,
    this.fontSize = 11,
    this.padding,
    this.borderRadius = 12,
    this.showIcon = true,
  });

  Color _getColor() {
    if (customColor != null) return customColor!;

    switch (type) {
      case StatusType.pending:
        return AppColors.warning;
      case StatusType.approved:
      case StatusType.success:
        return AppColors.success;
      case StatusType.rejected:
      case StatusType.error:
        return AppColors.error;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.info:
      case StatusType.custom:
        return AppColors.info;
    }
  }

  IconData _getIcon() {
    if (customIcon != null) return customIcon!;

    switch (type) {
      case StatusType.pending:
        return Icons.pending_actions_rounded;
      case StatusType.approved:
      case StatusType.success:
        return Icons.check_circle_rounded;
      case StatusType.rejected:
      case StatusType.error:
        return Icons.cancel_rounded;
      case StatusType.warning:
        return Icons.warning_rounded;
      case StatusType.info:
      case StatusType.custom:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final theme = Theme.of(context);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getIcon(),
              color: color,
              size: (fontSize ?? 11) + 3,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
