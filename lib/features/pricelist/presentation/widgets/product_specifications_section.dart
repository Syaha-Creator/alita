import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/product.dart';

class ProductSpecificationsSection extends StatefulWidget {
  final Product product;
  final Map<String, dynamic>? matchedSpec;

  const ProductSpecificationsSection({
    super.key,
    required this.product,
    required this.matchedSpec,
  });

  @override
  State<ProductSpecificationsSection> createState() =>
      _ProductSpecificationsSectionState();
}

class _ProductSpecificationsSectionState
    extends State<ProductSpecificationsSection> {
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final matchedSpec = widget.matchedSpec;
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
            children: gridFeatures.asMap().entries.map((entry) {
              final index = entry.key;
              final f = entry.value;
              final isExpanded = _expandedIndices.contains(index);
              final name = f['name']?.toString() ?? '';
              final note = f['note']?.toString() ?? '';
              return TapScale(
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (isExpanded) {
                      _expandedIndices.remove(index);
                    } else {
                      _expandedIndices.add(index);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topLeft,
                          child: Text(
                            note,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f['name']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
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
