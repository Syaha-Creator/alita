import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/product.dart';

class ProductSpecificationsSection extends StatelessWidget {
  final Product product;
  final Map<String, dynamic>? matchedSpec;

  const ProductSpecificationsSection({
    super.key,
    required this.product,
    required this.matchedSpec,
  });

  @override
  Widget build(BuildContext context) {
    final features = List<Map<String, dynamic>>.from(
      matchedSpec?['features'] ?? [],
    );

    const blacklist = [
      'size',
      'rp',
      'budget',
      'lelap',
      'weight',
      'couple comfort',
      'headboard',
      'foundation',
      'divan',
    ];
    final cleanFeatures = features.where((f) {
      final name = (f['name'] ?? '').toString().toLowerCase();
      final note = (f['note'] ?? '').toString().toLowerCase();
      return !blacklist.any((w) => name.contains(w) || note.contains(w));
    }).toList();

    final gridFeatures = cleanFeatures
        .where((f) => (f['note']?.toString() ?? '').trim().isNotEmpty)
        .toList();
    final checklistFeatures = cleanFeatures
        .where((f) => (f['note']?.toString() ?? '').trim().isEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spesifikasi Detail',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (gridFeatures.isNotEmpty) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: gridFeatures.map((f) {
              return Container(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['name']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f['note']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        if (checklistFeatures.isNotEmpty) ...[
          Column(
            children: checklistFeatures.map((f) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f['name']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
        ],

        _buildSpecItem(
          context,
          'Brand',
          product.brand.isNotEmpty ? product.brand : 'Premium Brand',
        ),
        _buildSpecItem(
          context,
          'Channel',
          product.channel.isNotEmpty ? product.channel : '-',
        ),
        _buildSpecItem(
          context,
          'Program',
          product.program.isNotEmpty ? product.program : '-',
        ),
        _buildSpecItem(
          context,
          'Stok',
          product.isAvailable ? 'Tersedia' : 'Habis',
        ),
      ],
    );
  }

  Widget _buildSpecItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
