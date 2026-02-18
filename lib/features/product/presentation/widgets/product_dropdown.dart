import 'package:flutter/material.dart';
import '../../../../config/app_constant.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/brand_model.dart';

class ProductDropdown extends StatelessWidget {
  final bool isSetActive;
  final Function(bool) onSetChanged;

  final String? selectedArea;
  final Function(String?) onAreaChanged;
  final bool isUserAreaSet;

  final List<String> channels;
  final String? selectedChannel;
  final Function(String?) onChannelChanged;
  final List<ChannelModel> availableChannelModels;

  final bool isIndirect;

  final List<String> brands;
  final String? selectedBrand;
  final Function(String?) onBrandChanged;
  final List<BrandModel> availableBrandModels;

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

  final List<String> programs;
  final String? selectedProgram;

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
    required this.availableChannelModels,
    required this.brands,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.availableBrandModels,
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
    required this.programs,
    required this.selectedProgram,
    required this.isLoading,
    this.isIndirect = false,
  });

  /// Filter channels berdasarkan mode (Indirect/Direct)
  /// - Indirect: Hanya "Toko" dan "Massindo Fair Toko"
  /// - Direct: Tampilkan semua channel
  List<String> get _filteredChannels {
    if (isIndirect) {
      // Indirect: Hanya tampilkan channel yang mengandung "Toko"
      return channels.where((channel) {
        final lowerChannel = channel.toLowerCase();
        return lowerChannel == 'toko' ||
            lowerChannel.contains('massindo fair - toko') ||
            lowerChannel == 'massindo fair - toko';
      }).toList();
    } else {
      // Direct: Tampilkan semua channel (tidak ada filter)
      return channels;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayChannels = _filteredChannels;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 8,
              tablet: 10,
              desktop: 12,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Gunakan Set",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                ),
              ),
              Switch(
                value: isSetActive,
                onChanged: onSetChanged,
                activeThumbColor: AppColors.primaryLight,
              ),
            ],
          ),
        ),
        SizedBox(
          height: ResponsiveHelper.getResponsiveSpacing(
            context,
            mobile: 8,
            tablet: 10,
            desktop: 12,
          ),
        ),
        _buildRow(
          context,
          CustomDropdown<String>(
            labelText: "Channel",
            items: displayChannels,
            selectedValue: displayChannels.contains(selectedChannel)
                ? selectedChannel
                : null,
            onChanged: onChannelChanged,
            hintText: displayChannels.isEmpty
                ? "Channel belum tersedia"
                : "Pilih Channel",
            isDynamicWidth: displayChannels.length <= 3,
          ),
          CustomDropdown<String>(
            labelText: "Brand",
            items: brands,
            selectedValue: selectedBrand,
            onChanged: onBrandChanged,
            hintText: selectedChannel == null || selectedChannel!.isEmpty
                ? "Pilih Channel terlebih dahulu"
                : (brands.isEmpty ? "Brand belum tersedia" : "Pilih Brand"),
            isDynamicWidth: brands.length <= 3,
            enabled: selectedChannel != null && selectedChannel!.isNotEmpty,
          ),
        ),
        _buildRow(
          context,
          isLoading
              ? SizedBox(
                  height: ResponsiveHelper.isMobile(context) ? 60 : 65,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveHelper.isMobile(context) ? 8 : 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppPadding.p8),
                        Text(
                          "Loading Kasur...",
                          style: TextStyle(
                            fontSize:
                                ResponsiveHelper.isMobile(context) ? 12 : 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomDropdown<String>(
                  labelText: "Kasur/Accessories (${kasurs.length})",
                  items: kasurs,
                  selectedValue: selectedKasur,
                  onChanged: onKasurChanged,
                  hintText: kasurs.isEmpty
                      ? "Tidak ada kasur tersedia"
                      : "Pilih Kasur",
                  isDynamicWidth: kasurs.length <= 3,
                ),
          CustomDropdown<String>(
            labelText: "Divan (${divans.length})",
            items: divans,
            selectedValue: selectedDivan,
            onChanged: onDivanChanged,
            hintText:
                divans.isEmpty ? "Tidak ada divan tersedia" : "Pilih Divan",
            isDynamicWidth: divans.length <= 3,
          ),
        ),
        _buildRow(
          context,
          CustomDropdown<String>(
            labelText: "Headboard (${headboards.length})",
            items: headboards,
            selectedValue: selectedHeadboard,
            onChanged: onHeadboardChanged,
            hintText: headboards.isEmpty
                ? "Tidak ada headboard tersedia"
                : "Pilih Headboard",
            isDynamicWidth: headboards.length <= 3,
          ),
          CustomDropdown<String>(
            labelText: "Sorong (${sorongs.length})",
            items: sorongs,
            selectedValue: selectedSorong,
            onChanged: onSorongChanged,
            hintText:
                sorongs.isEmpty ? "Tidak ada sorong tersedia" : "Pilih Sorong",
            isDynamicWidth: sorongs.length <= 3,
          ),
        ),
        _buildRow(
          context,
          CustomDropdown<String>(
            labelText: "Ukuran (${sizes.length})",
            items: sizes,
            selectedValue: selectedSize,
            onChanged: onSizeChanged,
            hintText:
                sizes.isEmpty ? "Tidak ada ukuran tersedia" : "Pilih Ukuran",
            isDynamicWidth: sizes.length <= 3,
          ),
          _buildReadOnlyProgramField(context),
        ),
      ],
    );
  }

  Widget _buildRow(
      BuildContext context, Widget firstDropdown, Widget secondDropdown) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveSpacing(
          context,
          mobile: 8,
          tablet: 10,
          desktop: 12,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: firstDropdown),
          SizedBox(
            width: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          Expanded(child: secondDropdown),
        ],
      ),
    );
  }

  Widget _buildReadOnlyProgramField(BuildContext context) {
    return SizedBox(
      height: ResponsiveHelper.isMobile(context) ? 60 : 65,
      child: InputDecorator(
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
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
          contentPadding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.isMobile(context) ? 12 : 16,
            horizontal: 12,
          ),
          isDense: true,
          labelStyle: TextStyle(
            fontSize: ResponsiveHelper.isMobile(context) ? 11 : 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight,
        ),
        child: SizedBox(
          height: ResponsiveHelper.isMobile(context) ? 40 : 44,
          child: Center(
            child: Text(
              selectedProgram?.isNotEmpty == true
                  ? selectedProgram!
                  : (programs.isEmpty
                      ? "Tidak ada program tersedia"
                      : "Program akan dipilih otomatis"),
              style: TextStyle(
                fontSize: ResponsiveHelper.isMobile(context) ? 13 : 15,
                color: selectedProgram?.isNotEmpty == true
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.disabledDark
                        : AppColors.disabledLight),
                fontWeight: selectedProgram?.isNotEmpty == true
                    ? FontWeight.w500
                    : FontWeight.normal,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}
