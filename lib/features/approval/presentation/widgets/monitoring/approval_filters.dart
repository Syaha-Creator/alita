import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';

/// Widget untuk filter status approval dengan count terintegrasi
/// Menggabungkan stats dan filter dalam satu komponen
class ApprovalFilters extends StatelessWidget {
  final String selectedFilter;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  const ApprovalFilters({
    super.key,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterChanged,
    required this.fadeAnimation,
    required this.slideAnimation,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
  });

  int _getCountForFilter(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return pendingCount + approvedCount + rejectedCount;
      case 'pending':
        return pendingCount;
      case 'approved':
        return approvedCount;
      case 'rejected':
        return rejectedCount;
      default:
        return 0;
    }
  }

  Color _getFilterColor(String filter, bool isSelected) {
    if (isSelected) return Colors.white;

    switch (filter.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  Color _getBackgroundColor(
      String filter, bool isSelected, bool isDark, ColorScheme colorScheme) {
    if (!isSelected) {
      return colorScheme.surfaceContainerHighest
          .withValues(alpha: isDark ? 0.3 : 0.5);
    }

    switch (filter.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([fadeAnimation, slideAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - slideAnimation.value)),
          child: Opacity(
            opacity: fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: filterOptions.asMap().entries.map((entry) {
                  final filter = entry.value;
                  final isSelected = selectedFilter == filter;
                  final count = _getCountForFilter(filter);
                  final filterColor = _getFilterColor(filter, isSelected);
                  final bgColor = _getBackgroundColor(
                      filter, isSelected, isDark, colorScheme);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onFilterChanged(filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: !isSelected
                              ? Border.all(
                                  color: _getFilterColor(filter, false)
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: bgColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon
                            Icon(
                              _getFilterIcon(filter),
                              color: isSelected ? Colors.white : filterColor,
                              size: 18,
                            ),
                            const SizedBox(height: AppPadding.p4),
                            // Count
                            Text(
                              count.toString(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : filterColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppPadding.p2),
                            // Label
                            Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return Icons.dashboard_rounded;
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.filter_list_rounded;
    }
  }
}
