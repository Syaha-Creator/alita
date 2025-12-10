import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/product_entity.dart';

/// Professional specification card with clean, minimal design
/// Uses 60-30-10 color scheme for consistent branding
class SpecificationCard extends StatelessWidget {
  final ProductEntity product;
  final bool isDark;

  const SpecificationCard({
    super.key,
    required this.product,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final componentSpecs = _buildComponentSpecs();
    final itemCount = componentSpecs.length;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? AppColors.cardDark
            : AppColors.cardLight, // 30% - Secondary
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.borderLight, // 30% - Border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - minimal and professional
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary
                        .withValues(alpha: 0.1), // 10% dengan opacity
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary, // 10% - Accent
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppPadding.p12),
                Expanded(
                  child: Text(
                    "Spesifikasi Produk",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary
                        .withValues(alpha: 0.1), // 10% dengan opacity
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "$itemCount",
                    style: TextStyle(
                      color: colorScheme.primary, // 10% - Accent
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Component specs grid dengan ukuran terintegrasi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSpecsGrid(context, componentSpecs),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid(
      BuildContext context, List<Map<String, dynamic>> specs) {
    if (specs.isEmpty) {
      // Jika tidak ada specs, tampilkan hanya ukuran
      return _buildUkuranRow(context, isFullWidth: true);
    }

    // Priority order for main spec: Kasur → Divan → Headboard → Sorong
    const priorityOrder = ['Kasur', 'Divan', 'Headboard', 'Sorong'];

    // Find the first available spec based on priority
    Map<String, dynamic> mainSpec = <String, dynamic>{};
    String? mainLabel;
    for (final label in priorityOrder) {
      final found = specs.firstWhere(
        (s) => s['label'] == label,
        orElse: () => <String, dynamic>{},
      );
      if (found.isNotEmpty) {
        mainSpec = found;
        mainLabel = label;
        break;
      }
    }

    final hasMainSpec = mainSpec.isNotEmpty;
    final otherSpecs = hasMainSpec
        ? specs.where((s) => s['label'] != mainLabel).toList()
        : specs;

    // Hitung jumlah row untuk other specs
    final otherSpecsRowCount =
        otherSpecs.isEmpty ? 0 : (otherSpecs.length / 2).ceil();
    final lastRowItemCount = otherSpecs.isEmpty ? 0 : (otherSpecs.length % 2);
    final hasEmptySpaceInLastRow = lastRowItemCount == 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main spec (first in priority)
        if (hasMainSpec)
          _buildSpecRow(
            context: context,
            icon: mainSpec['icon'] as IconData,
            color: mainSpec['color'] as Color,
            label: mainSpec['label'] as String,
            value: mainSpec['value'] as String,
            isMain: true,
          ),

        if (otherSpecs.isNotEmpty) ...[
          if (hasMainSpec) const SizedBox(height: AppPadding.p10),

          // Other specs in rows of 2
          ...List.generate(
            otherSpecsRowCount,
            (rowIndex) {
              final startIndex = rowIndex * 2;
              final endIndex = (startIndex + 2).clamp(0, otherSpecs.length);
              final rowSpecs = otherSpecs.sublist(startIndex, endIndex);
              final isLastRow = rowIndex == otherSpecsRowCount - 1;

              return Padding(
                padding:
                    EdgeInsets.only(bottom: isLastRow ? 0 : AppPadding.p10),
                child: Row(
                  children: [
                    // First item
                    Expanded(
                      child: _buildSpecRow(
                        context: context,
                        icon: rowSpecs[0]['icon'] as IconData,
                        color: rowSpecs[0]['color'] as Color,
                        label: rowSpecs[0]['label'] as String,
                        value: rowSpecs[0]['value'] as String,
                        isMain: false,
                      ),
                    ),
                    const SizedBox(width: AppPadding.p10),
                    // Second item atau Ukuran (jika ada space kosong di row terakhir)
                    Expanded(
                      child: rowSpecs.length > 1
                          ? _buildSpecRow(
                              context: context,
                              icon: rowSpecs[1]['icon'] as IconData,
                              color: rowSpecs[1]['color'] as Color,
                              label: rowSpecs[1]['label'] as String,
                              value: rowSpecs[1]['value'] as String,
                              isMain: false,
                            )
                          : (isLastRow && hasEmptySpaceInLastRow
                              ? _buildUkuranRow(context, isFullWidth: false)
                              : const SizedBox.shrink()),
                    ),
                  ],
                ),
              );
            },
          ),

          // Jika row terakhir penuh (2 item), tambahkan ukuran di row baru
          if (!hasEmptySpaceInLastRow) ...[
            const SizedBox(height: AppPadding.p10),
            _buildUkuranRow(context, isFullWidth: true),
          ],
        ] else ...[
          // Jika hanya ada main spec atau tidak ada other specs, tambahkan ukuran di row baru
          const SizedBox(height: AppPadding.p10),
          _buildUkuranRow(context, isFullWidth: true),
        ],
      ],
    );
  }

  /// Build ukuran row dengan styling yang sama seperti spec row
  Widget _buildUkuranRow(BuildContext context, {required bool isFullWidth}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ukuranWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark // 30% - Secondary
            : AppColors.surfaceLight, // 30% - Secondary
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.borderLight, // 30% - Border
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary
                  .withValues(alpha: 0.1), // 10% dengan opacity
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.straighten_rounded,
              color: colorScheme.primary, // 10% - Accent
              size: 16,
            ),
          ),
          const SizedBox(width: 10),

          // Label & Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Ukuran",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppPadding.p2),
                Text(
                  product.ukuran.isNotEmpty ? product.ukuran : "-",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isFullWidth) {
      return ukuranWidget;
    } else {
      return ukuranWidget;
    }
  }

  Widget _buildSpecRow({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required bool isMain,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isMain ? 14 : 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark // 30% - Secondary
            : AppColors.surfaceLight, // 30% - Secondary
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.borderLight, // 30% - Border
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon - menggunakan accent color yang konsisten
          Container(
            padding: EdgeInsets.all(isMain ? 10 : 8),
            decoration: BoxDecoration(
              color: colorScheme.primary
                  .withValues(alpha: 0.1), // 10% dengan opacity
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color:
                  colorScheme.primary, // 10% - Accent (konsisten untuk semua)
              size: isMain ? 18 : 16,
            ),
          ),
          SizedBox(width: isMain ? 12 : 10),

          // Label & Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: isMain ? 11 : 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppPadding.p2),
                Text(
                  value.isNotEmpty ? value : "-",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: isMain ? 14 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build only actual product components (Kasur, Divan, Headboard, Sorong)
  /// Ukuran is shown separately in the header as it's a dimension, not an item
  List<Map<String, dynamic>> _buildComponentSpecs() {
    final specs = <Map<String, dynamic>>[];

    // Helper function to check if value should be displayed
    bool shouldDisplay(String value) {
      if (value.isEmpty) return false;
      if (value.trim() == '-') return false;
      if (value.trim().toLowerCase().startsWith('tanpa')) return false;
      if (value == AppStrings.noKasur) return false;
      if (value == AppStrings.noDivan) return false;
      if (value == AppStrings.noHeadboard) return false;
      if (value == AppStrings.noSorong) return false;
      return true;
    }

    // Semua menggunakan accent color yang sama untuk konsistensi
    // Menggunakan primary color dari theme (10% - Accent)
    final accentColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    // Kasur - only show if valid
    if (shouldDisplay(product.kasur)) {
      specs.add({
        'icon': Icons.king_bed_rounded,
        'color': accentColor, // Konsisten - 10% Accent
        'label': 'Kasur',
        'value': product.kasur,
      });
    }

    // Divan - optional component
    if (shouldDisplay(product.divan)) {
      specs.add({
        'icon': Icons.layers_rounded,
        'color': accentColor, // Konsisten - 10% Accent
        'label': 'Divan',
        'value': product.divan,
      });
    }

    // Headboard - optional component
    if (shouldDisplay(product.headboard)) {
      specs.add({
        'icon': Icons.view_headline_rounded,
        'color': accentColor, // Konsisten - 10% Accent
        'label': 'Headboard',
        'value': product.headboard,
      });
    }

    // Sorong - optional component
    if (shouldDisplay(product.sorong)) {
      specs.add({
        'icon': Icons.arrow_downward_rounded,
        'color': accentColor, // Konsisten - 10% Accent
        'label': 'Sorong',
        'value': product.sorong,
      });
    }

    return specs;
  }
}
