import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart';
import '../../bloc/product_state.dart';
import 'product_helpers.dart';

/// Widget to display the area information section (compact version)
/// Shows current area and allows selection for non-national brands
class AreaInfoSection extends StatelessWidget {
  final ProductState state;
  final String Function(ProductState) getValidSelectedArea;

  const AreaInfoSection({
    super.key,
    required this.state,
    required this.getValidSelectedArea,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isNational = isNationalBrand(state.selectedBrand);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor =
        isNational ? colorScheme.primary : colorScheme.tertiary;
    final containerColor = isNational
        ? colorScheme.primaryContainer
        : colorScheme.tertiaryContainer;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            containerColor.withValues(alpha: isDark ? 0.25 : 0.12),
            containerColor.withValues(alpha: isDark ? 0.1 : 0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Compact location icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppPadding.p10),

          // Content - Area selection or display
          Expanded(
            child: isNational
                ? _buildNationalDisplay(theme, colorScheme, primaryColor)
                : _buildAreaDropdown(context, theme, primaryColor),
          ),

          const SizedBox(
              width: AppPadding.p12), // Spacing between dropdown and badge

          // Badge
          _buildCompactBadge(theme, primaryColor, containerColor, isNational),

          // Reset button for non-national
          if (!isNational &&
              state.userSelectedArea != null &&
              state.selectedBrand != null) ...[
            const SizedBox(width: AppPadding.p8),
            _buildResetButton(context, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildNationalDisplay(
      ThemeData theme, ColorScheme colorScheme, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              state.selectedArea ?? "Nasional",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppPadding.p6),
            Icon(
              Icons.public_rounded,
              size: 14,
              color: primaryColor.withValues(alpha: 0.7),
            ),
          ],
        ),
        Text(
          "Brand ${state.selectedBrand} • Area Nasional",
          style: theme.textTheme.bodySmall?.copyWith(
            color: primaryColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaDropdown(
      BuildContext context, ThemeData theme, Color primaryColor) {
    // Remove duplicates from available areas
    final uniqueAreas = state.availableAreas.toSet().toList();
    
    // Get valid selected value - must exist in uniqueAreas
    final selectedValue = getValidSelectedArea(state);
    final validValue = uniqueAreas.contains(selectedValue) 
        ? selectedValue 
        : (uniqueAreas.isNotEmpty ? uniqueAreas.first : null);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: ValueKey(validValue),
          value: validValue,
          isExpanded: true,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryColor,
            size: 20,
          ),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          dropdownColor: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          items: uniqueAreas.map((area) {
            return DropdownMenuItem<String>(
              value: area,
              child: Text(area),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              context.read<ProductBloc>().add(UpdateSelectedArea(newValue));
            }
          },
        ),
      ),
    );
  }

  Widget _buildCompactBadge(ThemeData theme, Color primaryColor,
      Color containerColor, bool isNational) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: containerColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNational ? Icons.public_rounded : Icons.map_rounded,
            size: 11,
            color: primaryColor,
          ),
          const SizedBox(width: AppPadding.p3),
          Text(
            getAreaBadgeText(state.selectedBrand),
            style: theme.textTheme.labelSmall?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => context.read<ProductBloc>().add(ResetUserSelectedArea()),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.refresh_rounded,
          size: 14,
          color: colorScheme.error,
        ),
      ),
    );
  }
}
