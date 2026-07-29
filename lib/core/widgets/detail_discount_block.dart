import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable discount approval container for detail pages.
class DetailDiscountBlock extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const DetailDiscountBlock({
    super.key,
    this.title = 'Approval Diskon',
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }
}

/// Reusable discount approval row (icon + value + approver name).
class DetailDiscountRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Widget leadingValue;
  final String approverName;

  const DetailDiscountRow({
    super.key,
    required this.icon,
    required this.color,
    required this.leadingValue,
    required this.approverName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          leadingValue,
          Expanded(
            child: Text(
              approverName,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
