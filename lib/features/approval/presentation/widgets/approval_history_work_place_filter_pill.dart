import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_formatters.dart';

/// Pill kompak untuk filter lokasi/toko di tab riwayat approval (Selesai).
///
/// [onTap] diserahkan ke halaman induk (mis. menampilkan bottom sheet pilihan lokasi).
class ApprovalHistoryWorkPlaceFilterPill extends StatelessWidget {
  const ApprovalHistoryWorkPlaceFilterPill({
    super.key,
    required this.selectedWorkPlace,
    required this.filteredCount,
    required this.totalCount,
    required this.onTap,
  });

  /// `null` = semua lokasi (label "Semua lokasi").
  final String? selectedWorkPlace;
  final int filteredCount;
  final int totalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedWorkPlace != null;
    final displaySelected = selectedWorkPlace == null
        ? 'Semua lokasi'
        : AppFormatters.titleCase(selectedWorkPlace!.toLowerCase());
    final countText = selectedWorkPlace == null
        ? '$totalCount riwayat ditemukan'
        : '$filteredCount dari $totalCount riwayat';

    return Semantics(
      button: true,
      label: 'Filter lokasi: $displaySelected',
      hint: 'Ketuk untuk memilih lokasi',
      child: Material(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.05)
            : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
          side: BorderSide(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.65),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayoutTokens.space16,
              vertical: AppLayoutTokens.space12,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppLayoutTokens.space8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 20,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppLayoutTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displaySelected,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppLayoutTokens.space4),
                      Text(
                        countText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppLayoutTokens.space8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color:
                      isSelected ? AppColors.accent : AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
