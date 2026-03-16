import 'package:flutter/material.dart';

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
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
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
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
