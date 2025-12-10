import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';

import '../../../../../core/utils/responsive_helper.dart';
import '../../bloc/product_state.dart';

/// Widget untuk menampilkan tombol filter dan reset
/// Pure UI widget - semua logic di-handle oleh parent via callbacks
class FilterButtonsRow extends StatelessWidget {
  final GlobalKey filterButtonKey;
  final ProductState state;
  final VoidCallback? onApplyFilter;
  final VoidCallback? onResetFilter;

  const FilterButtonsRow({
    super.key,
    required this.filterButtonKey,
    required this.state,
    this.onApplyFilter,
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canApplyFilter =
        state.selectedKasur != null && state.selectedKasur!.isNotEmpty;
    final showResetButton =
        (state.selectedChannel != null && state.selectedChannel!.isNotEmpty) ||
            state.isFilterApplied;

    return Row(
      key: filterButtonKey,
      children: [
        // Apply Filter Button
        Expanded(
          child: Tooltip(
            message: state.isUserAreaSet
                ? "Terapkan filter yang dipilih untuk melihat produk"
                : "Tampilkan produk berdasarkan filter yang dipilih",
            child: ElevatedButton.icon(
              onPressed: canApplyFilter ? onApplyFilter : null,
              icon: Icon(
                state.isUserAreaSet ? Icons.filter_alt : Icons.search,
                size: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  mobile: 16,
                  tablet: 17,
                  desktop: 18,
                ),
              ),
              label: state.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      state.isUserAreaSet
                          ? "Terapkan Filter"
                          : "Tampilkan Produk",
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: (state.selectedBrand != null &&
                        state.selectedBrand!.isNotEmpty)
                    ? theme.colorScheme.primary
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                  vertical: ResponsiveHelper.getResponsiveSpacing(
                    context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 14,
                  ),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),

        // Reset Button (conditionally shown)
        if (showResetButton) ...[
          const SizedBox(width: AppPadding.p12),
          Tooltip(
            message: "Reset semua filter yang dipilih",
            child: ElevatedButton.icon(
              onPressed: state.isLoading ? null : onResetFilter,
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
                size: ResponsiveHelper.getResponsiveIconSize(
                  context,
                  mobile: 16,
                  tablet: 17,
                  desktop: 18,
                ),
              ),
              label: Text(
                "Reset",
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.isLoading
                    ? Colors.grey.shade400
                    : Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                  vertical: ResponsiveHelper.getResponsiveSpacing(
                    context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 14,
                  ),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
