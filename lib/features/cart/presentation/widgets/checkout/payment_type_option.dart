import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';

/// Widget untuk menampilkan opsi tipe pembayaran (Transfer, Kartu Kredit, dll)
/// Pure UI widget - semua logic di-handle oleh parent melalui callbacks
class PaymentTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const PaymentTypeOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withValues(alpha: 0.1)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                : (isDark ? AppColors.borderDark : AppColors.borderLight), // 30% - Border
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppPadding.p4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: isSelected
                        ? (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withValues(alpha: 0.8)
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

