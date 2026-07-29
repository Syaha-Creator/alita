import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Small pill pair for `pricelist_type` / `pricelist_area` — used on order
/// detail & approval detail item rows instead of a plain label-value line,
/// so this metadata reads as scannable tags rather than blending into text.
class DetailPricelistTags extends StatelessWidget {
  final String type;
  final String area;

  const DetailPricelistTags({
    super.key,
    this.type = '',
    this.area = '',
  });

  @override
  Widget build(BuildContext context) {
    if (type.trim().isEmpty && area.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (type.trim().isNotEmpty)
          _Tag(icon: Icons.storefront_outlined, label: type.trim()),
        if (area.trim().isNotEmpty)
          _Tag(icon: Icons.place_outlined, label: area.trim()),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
