import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import 'document_info_widgets.dart';

/// Custom AppBar untuk halaman Order Letter Document
class DocumentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String noSp;
  final String status;
  final String createdAt;
  final String creatorName;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const DocumentAppBar({
    super.key,
    required this.noSp,
    required this.status,
    required this.createdAt,
    required this.creatorName,
    required this.onBack,
    required this.onRefresh,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(130);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: isDark ? colorScheme.surface : AppColors.surfaceLight, // 30% - Surface
      foregroundColor: isDark ? colorScheme.onSurface : AppColors.textPrimaryLight,
      elevation: 2,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.1),
      toolbarHeight: 80,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                isDark ? colorScheme.surfaceContainerHighest : AppColors.cardLight, // 30% - Card
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : AppColors.borderLight), // 30% - Border
          ),
          child: Icon(Icons.arrow_back_ios_new,
              color: isDark ? colorScheme.onSurfaceVariant : AppColors.textSecondaryLight,
              size: 18),
        ),
        onPressed: onBack,
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.primaryContainer : AppColors.accentLight.withValues(alpha: 0.1), // 10% dengan opacity
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : AppColors.accentLight.withValues(alpha: 0.3)), // 10% dengan opacity
            ),
            child: Icon(Icons.refresh,
                color:
                    isDark ? colorScheme.onPrimaryContainer : AppColors.accentLight, // 10% - Accent
                size: 20),
          ),
          onPressed: onRefresh,
        ),
      ],
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark ? colorScheme.primaryContainer : AppColors.accentLight.withValues(alpha: 0.1), // 10% dengan opacity
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.3)
                          : AppColors.accentLight.withValues(alpha: 0.3)), // 10% dengan opacity
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: isDark
                          ? colorScheme.onPrimaryContainer
                          : AppColors.accentLight, // 10% - Accent
                      size: 16,
                    ),
                    const SizedBox(width: AppPadding.p6),
                    Flexible(
                      child: Text(
                        'SURAT PESANAN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? colorScheme.onPrimaryContainer
                              : AppColors.accentLight, // 10% - Accent
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppPadding.p8),
              StatusBadge.fromStatus(status),
            ],
          ),
          const SizedBox(height: AppPadding.p4),
          Text(
            noSp,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? colorScheme.onSurface : AppColors.textPrimaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isDark ? colorScheme.surfaceContainerHighest : AppColors.dominantLight, // 60% - Background
            border: Border(
              top: BorderSide(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : AppColors.borderLight), // 30% - Border
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: DocumentInfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tanggal',
                  value: _formatDate(createdAt),
                  color: AppColors.warning, // Status color
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : AppColors.borderLight, // 30% - Border
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: DocumentInfoItem(
                  icon: Icons.person_outline,
                  label: 'Creator',
                  value: creatorName,
                  color: AppColors.success, // Status color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

