import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../theme/app_colors.dart';

/// Widget untuk header halaman Approval Monitoring
class ApprovalHeader extends StatelessWidget {
  final bool isStaffLevel;
  final bool isDateFilterActive;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;
  final VoidCallback onDateRangePressed;
  final VoidCallback onClearDateFilter;

  const ApprovalHeader({
    super.key,
    required this.isStaffLevel,
    required this.isDateFilterActive,
    this.dateFrom,
    this.dateTo,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.onDateRangePressed,
    required this.onClearDateFilter,
  });

  String _formatDateForDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([fadeAnimation, slideAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - slideAnimation.value)),
          child: Opacity(
            opacity: fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
              ),
              child: Column(
                children: [
                  _buildAppBar(context, theme, colorScheme),
                  if (isDateFilterActive &&
                      dateFrom != null &&
                      dateTo != null) ...[
                    const SizedBox(height: AppPadding.p12),
                    _buildActiveDateFilter(colorScheme),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primaryDark : Colors.white;
    final titleColor = isDark ? AppColors.textPrimaryDark : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primaryDark.withValues(alpha: 0.3),
                  AppColors.primaryDark.withValues(alpha: 0.1),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => context.go(RoutePaths.product),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: iconColor,
              size: 18,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(8),
            ),
          ),

          // Icon with container
          Container(
            padding: const EdgeInsets.all(AppPadding.p6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppPadding.p8),
            ),
            child: Icon(
              Icons.approval_rounded,
              color: iconColor,
              size: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
            ),
          ),

          const SizedBox(width: AppPadding.p10),

          // Title Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Approval Hub',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  isStaffLevel
                      ? 'View Only - Staff Level'
                      : 'Manage & Review Orders',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isStaffLevel
                        ? AppColors.warning
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.85)),
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // Date Range Filter Button
          Container(
            decoration: BoxDecoration(
              color: isDateFilterActive
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: isDateFilterActive
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.5), width: 1.5)
                  : null,
            ),
            child: IconButton(
              onPressed: onDateRangePressed,
              icon: Stack(
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                  if (isDateFilterActive)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Filter Rentang Waktu',
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDateFilter(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_rounded,
            color: AppColors.info,
            size: 16,
          ),
          const SizedBox(width: AppPadding.p8),
          Expanded(
            child: Text(
              '${_formatDateForDisplay(dateFrom!)} - ${_formatDateForDisplay(dateTo!)}',
              style: const TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: AppPadding.p8),
          GestureDetector(
            onTap: onClearDateFilter,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.info,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
