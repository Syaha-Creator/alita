import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../utils/responsive_helper.dart';
import '../../theme/app_colors.dart';

/// Dropdown custom reusable dengan pencarian dan dekorasi konsisten.
class CustomDropdown<T> extends StatelessWidget {
  final String labelText;
  final List<T> items;
  final T? selectedValue;
  final Function(T?) onChanged;
  final bool isSearchable;
  final String? hintText;
  final double? width;
  final bool isDynamicWidth;
  final IconData? emptyIcon;

  const CustomDropdown({
    super.key,
    required this.labelText,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.isSearchable = true,
    this.hintText,
    this.width,
    this.isDynamicWidth = false,
    this.emptyIcon,
  });

  // Hitung tinggi menu berdasarkan jumlah item
  double _calculateMenuHeight(BuildContext context) {
    if (items.isEmpty) return 50;

    // Tinggi per item (padding + text height) - dikurangi untuk menghilangkan space kosong
    double itemHeight = ResponsiveHelper.isMobile(context) ? 32 : 36;

    // Tinggi search box jika ada
    double searchBoxHeight = (isSearchable && items.length > 4)
        ? (ResponsiveHelper.isMobile(context) ? 50 : 56)
        : 0;

    // Untuk item sedikit (1-5), tampilkan semua tanpa scroll
    if (items.length <= 5) {
      return (items.length * itemHeight) + searchBoxHeight;
    }

    // Untuk item banyak (>5), batasi tinggi dan gunakan scroll
    double maxVisibleHeight = (5 * itemHeight) + searchBoxHeight;
    return maxVisibleHeight;
  }

  @override
  Widget build(BuildContext context) {
    // Hitung lebar dinamis berdasarkan jumlah item
    double calculatedWidth = width ?? double.infinity;
    if (isDynamicWidth && items.isNotEmpty) {
      // Hitung lebar berdasarkan panjang text terpanjang
      double maxTextWidth = 0;
      final baseFontSize = ResponsiveHelper.getResponsiveFontSize(
        context,
        mobile: 13,
        tablet: 14,
        desktop: 15,
      );

      for (T item in items) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: item.toString(),
            style: TextStyle(fontSize: baseFontSize),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        maxTextWidth = math.max(maxTextWidth, textPainter.width);
      }

      // Tambahkan padding dan margin
      calculatedWidth = math.max(
        maxTextWidth + 40, // padding kiri-kanan
        ResponsiveHelper.getResponsiveSpacingWithZoom(
          context,
          mobile: 120,
          tablet: 140,
          desktop: 160,
        ),
      );
    }

    return SizedBox(
      height: ResponsiveHelper.getResponsiveButtonHeight(
        context,
        mobile: 60,
        tablet: 65,
        desktop: 70,
      ),
      width: calculatedWidth,
      child: DropdownSearch<T>(
        items: items,
        selectedItem: selectedValue,
        onChanged: onChanged,
        dropdownButtonProps: DropdownButtonProps(
          icon: Icon(
            Icons.arrow_drop_down,
            size: ResponsiveHelper.getResponsiveIconSize(
              context,
              mobile: 20,
              tablet: 22,
              desktop: 24,
            ),
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: isSearchable && items.length > 4,
          searchFieldProps: TextFieldProps(
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
            ),
            decoration: InputDecoration(
              hintText: "Cari...",
              hintStyle: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.disabledDark
                    : AppColors.disabledLight,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: ResponsiveHelper.getResponsivePaddingWithZoom(
                context,
                mobile: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                tablet:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                desktop:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              isDense: true,
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: _calculateMenuHeight(context),
          ),
          menuProps: MenuProps(
            borderRadius: BorderRadius.circular(8),
            elevation: 1,
          ),
          itemBuilder: (context, item, isSelected) {
            return Container(
              padding: EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 12,
              ),
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.cardDark
                      : AppColors.cardLight)
                  : null,
              child: Text(
                item.toString(),
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 15,
                  ),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            );
          },
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.primaryDark
                    : AppColors.primaryLight,
                width: 2,
              ),
            ),
            contentPadding: ResponsiveHelper.getResponsivePaddingWithZoom(
              context,
              mobile: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              tablet: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              desktop: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            isDense: true,
            isCollapsed: true,
            labelStyle: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 14,
              ),
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            hintStyle: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 11,
                tablet: 13,
                desktop: 15,
              ),
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.disabledDark
                  : AppColors.disabledLight,
              height: 1.3,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
          ),
        ),
        dropdownBuilder: (context, selectedItem) {
          return Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePaddingWithZoom(
              context,
              mobile: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              tablet: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
              desktop: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            child: Align(
              alignment: Alignment.center,
              child: selectedItem != null
                  ? Text(
                      selectedItem.toString(),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    )
                  : Text(
                      hintText ?? 'Belum tersedia',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.disabledDark
                            : AppColors.disabledLight,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          );
        },
        itemAsString: (item) => item.toString(),
      ),
    );
  }
}
