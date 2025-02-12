import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_dropdown.dart';

class ProductDropdown extends StatelessWidget {
  final List<String> areas;
  final String? selectedArea;
  final Function(String?) onAreaChanged;

  final List<String> channels;
  final String? selectedChannel;
  final Function(String?) onChannelChanged;

  final List<String> brands;
  final String? selectedBrand;
  final Function(String?) onBrandChanged;

  final List<String> kasurs;
  final String? selectedKasur;
  final Function(String?) onKasurChanged;

  final List<String> divans;
  final String? selectedDivan;
  final Function(String?) onDivanChanged;

  final List<String> headboards;
  final String? selectedHeadboard;
  final Function(String?) onHeadboardChanged;

  final List<String> sorongs;
  final String? selectedSorong;
  final Function(String?) onSorongChanged;

  final List<String> sizes;
  final String? selectedSize;
  final Function(String?) onSizeChanged;

  const ProductDropdown({
    super.key,
    required this.areas,
    required this.selectedArea,
    required this.onAreaChanged,
    required this.channels,
    required this.selectedChannel,
    required this.onChannelChanged,
    required this.brands,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.kasurs,
    required this.selectedKasur,
    required this.onKasurChanged,
    required this.divans,
    required this.selectedDivan,
    required this.onDivanChanged,
    required this.headboards,
    required this.selectedHeadboard,
    required this.onHeadboardChanged,
    required this.sorongs,
    required this.selectedSorong,
    required this.onSorongChanged,
    required this.sizes,
    required this.selectedSize,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomDropdown<String>(
          labelText: "Area",
          items: areas,
          selectedValue: selectedArea,
          onChanged: onAreaChanged,
          hintText: "Pilih Area",
        ),
        const SizedBox(height: 10),
        CustomDropdown<String>(
          labelText: "Channel",
          items: channels,
          selectedValue: selectedChannel,
          onChanged: onChannelChanged,
          hintText: "Pilih Channel",
        ),
        const SizedBox(height: 10),
        CustomDropdown<String>(
          labelText: "Brand",
          items: brands,
          selectedValue: selectedBrand,
          onChanged: onBrandChanged,
          hintText: "Pilih Brand",
        ),
        const SizedBox(height: 10),
        CustomDropdown<String>(
          labelText: "Kasur",
          items: kasurs,
          selectedValue: selectedKasur,
          onChanged: onKasurChanged,
          hintText: "Pilih Kasur",
        ),
        const SizedBox(height: 10),
        CustomDropdown<String>(
          labelText: "Divan",
          items: divans,
          selectedValue: selectedDivan,
          onChanged: onDivanChanged,
          hintText: "Pilih Divan",
        ),
        const SizedBox(height: 10),
        CustomDropdown<String>(
          labelText: "Headboard",
          items: headboards,
          selectedValue: selectedHeadboard,
          onChanged: onHeadboardChanged,
          hintText: "Pilih Headboard",
        ),
        const SizedBox(height: 10),
        CustomDropdown<String>(
          labelText: "Sorong",
          items: sorongs,
          selectedValue: selectedSorong,
          onChanged: onSorongChanged,
          hintText: "Pilih Sorong",
        ),
        const SizedBox(height: 10),
        CustomDropdown<String>(
          labelText: "Ukuran",
          items: sizes,
          selectedValue: selectedSize,
          onChanged: onSizeChanged,
          hintText: "Pilih Ukuran",
        ),
      ],
    );
  }
}
