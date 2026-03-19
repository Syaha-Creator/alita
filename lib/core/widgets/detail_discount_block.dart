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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          leadingValue,
          Expanded(
            child: Text(
              approverName,
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
