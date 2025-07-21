import 'package:flutter/material.dart';
import '../../../../config/app_constant.dart';
import '../../../../core/widgets/custom_dropdown.dart';

class ProductDropdown extends StatelessWidget {
  final bool isSetActive;
  final Function(bool) onSetChanged;

  final String? selectedArea;
  final Function(String?) onAreaChanged;
  final bool isUserAreaSet;

  final List<String> channels;
  final String? selectedChannel;
  final Function(String?) onChannelChanged;
  final List<ChannelEnum> availableChannelEnums;

  final List<String> brands;
  final String? selectedBrand;
  final Function(String?) onBrandChanged;
  final List<BrandEnum> availableBrandEnums;

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

  final bool isLoading;

  const ProductDropdown({
    super.key,
    required this.isSetActive,
    required this.onSetChanged,
    required this.selectedArea,
    required this.onAreaChanged,
    required this.isUserAreaSet,
    required this.channels,
    required this.selectedChannel,
    required this.onChannelChanged,
    required this.availableChannelEnums,
    required this.brands,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.availableBrandEnums,
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
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppPadding.p8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Gunakan Set",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Switch(
                value: isSetActive,
                onChanged: onSetChanged,
                activeColor: Colors.blue,
              ),
            ],
          ),
        ),
        CustomDropdown<String>(
          labelText: "Channel",
          items: channels,
          selectedValue: selectedChannel,
          onChanged: onChannelChanged,
          hintText: "Pilih Channel",
        ),
        SizedBox(height: AppPadding.p10),
        _buildRow(
          CustomDropdown<String>(
            labelText: "Brand",
            items: brands,
            selectedValue: selectedBrand,
            onChanged: onBrandChanged,
            hintText: "Pilih Brand",
          ),
          isLoading
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Loading Kasur...",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : CustomDropdown<String>(
                  labelText: "Kasur/Accessories (${kasurs.length})",
                  items: kasurs,
                  selectedValue: selectedKasur,
                  onChanged: onKasurChanged,
                  hintText: kasurs.isEmpty
                      ? "Tidak ada kasur tersedia"
                      : "Pilih Kasur/Accessories",
                ),
        ),
        _buildRow(
          CustomDropdown<String>(
            labelText: "Divan (${divans.length})",
            items: divans,
            selectedValue: selectedDivan,
            onChanged: onDivanChanged,
            hintText:
                divans.isEmpty ? "Tidak ada divan tersedia" : "Pilih Divan",
          ),
          CustomDropdown<String>(
            labelText: "Headboard (${headboards.length})",
            items: headboards,
            selectedValue: selectedHeadboard,
            onChanged: onHeadboardChanged,
            hintText: headboards.isEmpty
                ? "Tidak ada headboard tersedia"
                : "Pilih Headboard",
          ),
        ),
        _buildRow(
          CustomDropdown<String>(
            labelText: "Sorong (${sorongs.length})",
            items: sorongs,
            selectedValue: selectedSorong,
            onChanged: onSorongChanged,
            hintText:
                sorongs.isEmpty ? "Tidak ada sorong tersedia" : "Pilih Sorong",
          ),
          CustomDropdown<String>(
            labelText: "Ukuran (${sizes.length})",
            items: sizes,
            selectedValue: selectedSize,
            onChanged: onSizeChanged,
            hintText:
                sizes.isEmpty ? "Tidak ada ukuran tersedia" : "Pilih Ukuran",
          ),
        ),
      ],
    );
  }

  Widget _buildRow(Widget firstDropdown, Widget secondDropdown) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.p10),
      child: Row(
        children: [
          Expanded(child: firstDropdown),
          const SizedBox(width: 8),
          Expanded(child: secondDropdown),
        ],
      ),
    );
  }
}
