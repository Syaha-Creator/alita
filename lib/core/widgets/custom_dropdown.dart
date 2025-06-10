import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../config/app_constant.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String labelText;
  final List<T> items;
  final T? selectedValue;
  final Function(T?) onChanged;
  final bool isSearchable;
  final String? hintText;

  const CustomDropdown({
    super.key,
    required this.labelText,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.isSearchable = true,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    double itemHeight = 55;
    double maxDropdownHeight = (items.length.clamp(1, 4) * itemHeight) + 10;

    return DropdownSearch<T>(
      items: items,
      selectedItem: selectedValue,
      onChanged: onChanged,
      popupProps: PopupProps.menu(
        showSearchBox: isSearchable && items.length > 4,
        constraints: BoxConstraints(maxHeight: maxDropdownHeight),
        menuProps:
            MenuProps(borderRadius: BorderRadius.circular(12), elevation: 4),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
              vertical: AppPadding.p12, horizontal: AppPadding.p10),
        ),
      ),
    );
  }
}
