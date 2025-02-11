import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final Function(T?) onChanged;
  final bool isSearchable;
  final String? hintText;

  const CustomDropdown({
    super.key,
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.isSearchable = true,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownSearch<T>(
          items: items,
          selectedItem: selectedValue,
          onChanged: onChanged,
          popupProps: PopupProps.menu(
            showSearchBox: isSearchable,
          ),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: hintText,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }
}
