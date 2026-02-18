import 'package:flutter/material.dart';
import '../../../../config/app_constant.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/store_model.dart';

/// Dropdown widget khusus untuk Indirect Product Page
/// Flow baru:
/// 1. Pilih Toko (Store) - primary selection
/// 2. Jika SA (Spring Air) → pilih sub-brand (European/American)
/// 3. Pilih Channel (Toko / Massindo Fair - Toko)
/// 4. Brand & Area otomatis terisi dari data toko
/// 5. Filter produk lainnya
class IndirectProductDropdown extends StatelessWidget {
  final bool isSetActive;
  final Function(bool) onSetChanged;

  // Store (Toko) - primary selection
  final List<StoreModel> stores;
  final StoreModel? selectedStore;
  final Function(StoreModel?) onStoreChanged;
  final bool isLoadingStores;
  final VoidCallback? onRefreshStores;

  // Sub-brand selection (untuk SA - Spring Air)
  final String? selectedSubBrand;
  final Function(String?) onSubBrandChanged;

  // Channel selection - user bisa pilih antara Toko / Massindo Fair - Toko
  final List<String> availableChannels;
  final String? selectedChannel;
  final Function(String?) onChannelChanged;

  // Brand & Area - auto dari store selection (read-only display)
  final String? selectedBrand;
  final String? selectedArea;

  // Product filters
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

  const IndirectProductDropdown({
    super.key,
    required this.isSetActive,
    required this.onSetChanged,
    required this.stores,
    required this.selectedStore,
    required this.onStoreChanged,
    required this.isLoadingStores,
    this.onRefreshStores,
    this.selectedSubBrand,
    required this.onSubBrandChanged,
    required this.availableChannels,
    this.selectedChannel,
    required this.onChannelChanged,
    this.selectedBrand,
    this.selectedArea,
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
  });

  /// Filter channels - hanya Toko dan Massindo Fair Toko
  List<String> get _filteredChannels {
    return availableChannels.where((channel) {
      final lowerChannel = channel.toLowerCase();
      return lowerChannel == 'toko' ||
          (lowerChannel.contains('massindo fair') &&
              lowerChannel.contains('toko'));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Set Toggle
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
                activeColor: AppColors.purple,
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

        // Store Dropdown - Primary Selection
        if (isLoadingStores)
          _buildLoadingWidget(context, "Memuat daftar toko...")
        else
          _buildStoreDropdown(context),

        SizedBox(
          height: ResponsiveHelper.getResponsiveSpacing(
            context,
            mobile: 12,
            tablet: 14,
            desktop: 16,
          ),
        ),

        // Sub-brand Dropdown (untuk SA - Spring Air)
        if (selectedStore != null && selectedStore!.needsSubBrandSelection) ...[
          _buildSubBrandDropdown(context),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
            ),
          ),
        ],

        // Channel Dropdown - tampil setelah store dipilih
        // (dan setelah sub-brand dipilih jika SA)
        if (selectedStore != null &&
            (!selectedStore!.needsSubBrandSelection ||
                selectedSubBrand != null)) ...[
          _buildChannelDropdown(context),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
            ),
          ),
        ],

        // Info badges for Brand & Area (auto from store)
        // Channel sudah ada dropdown sendiri
        if (selectedStore != null &&
            (!selectedStore!.needsSubBrandSelection ||
                selectedSubBrand != null)) ...[
          _buildStoreInfoSection(context),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
            ),
          ),
        ],

        // Product filters - hanya tampil setelah brand selection complete
        // (store dipilih DAN (tidak perlu sub-brand ATAU sub-brand sudah dipilih))
        if (selectedStore != null &&
            (!selectedStore!.needsSubBrandSelection ||
                selectedSubBrand != null)) ...[
          // Divider
          Divider(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 8,
              tablet: 10,
              desktop: 12,
            ),
          ),

          // Label filter produk
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Filter Produk",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 13,
                  tablet: 15,
                  desktop: 17,
                ),
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
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

          // Row 1: Kasur & Divan
          _buildRow(
            context,
            CustomDropdown<String>(
              labelText: "Kasur",
              items: kasurs,
              selectedValue:
                  kasurs.contains(selectedKasur) ? selectedKasur : null,
              onChanged: onKasurChanged,
              hintText: kasurs.isEmpty ? "Kasur belum tersedia" : "Pilih Kasur",
              isDynamicWidth: kasurs.length <= 3,
            ),
            CustomDropdown<String>(
              labelText: "Divan",
              items: divans,
              selectedValue:
                  divans.contains(selectedDivan) ? selectedDivan : null,
              onChanged: onDivanChanged,
              hintText: divans.isEmpty ? "Divan belum tersedia" : "Pilih Divan",
              isDynamicWidth: divans.length <= 3,
            ),
          ),

          // Row 2: Headboard & Sorong
          _buildRow(
            context,
            CustomDropdown<String>(
              labelText: "Headboard",
              items: headboards,
              selectedValue: headboards.contains(selectedHeadboard)
                  ? selectedHeadboard
                  : null,
              onChanged: onHeadboardChanged,
              hintText: headboards.isEmpty
                  ? "Headboard belum tersedia"
                  : "Pilih Headboard",
              isDynamicWidth: headboards.length <= 3,
            ),
            CustomDropdown<String>(
              labelText: "Sorong",
              items: sorongs,
              selectedValue:
                  sorongs.contains(selectedSorong) ? selectedSorong : null,
              onChanged: onSorongChanged,
              hintText:
                  sorongs.isEmpty ? "Sorong belum tersedia" : "Pilih Sorong",
              isDynamicWidth: sorongs.length <= 3,
            ),
          ),

          // Row 3: Size & Program
          _buildRow(
            context,
            CustomDropdown<String>(
              labelText: "Ukuran",
              items: sizes,
              selectedValue: sizes.contains(selectedSize) ? selectedSize : null,
              onChanged: onSizeChanged,
              hintText:
                  sizes.isEmpty ? "Ukuran belum tersedia" : "Pilih Ukuran",
              isDynamicWidth: sizes.length <= 3,
            ),
            _buildReadOnlyProgramField(context),
          ),
        ],
      ],
    );
  }

  /// Build store dropdown (primary selection)
  Widget _buildStoreDropdown(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomDropdown<StoreModel>(
            labelText: "Pilih Toko",
            items: stores,
            selectedValue: selectedStore,
            onChanged: onStoreChanged,
            hintText: stores.isEmpty ? "Tidak ada toko tersedia" : "Pilih Toko",
            isDynamicWidth: false,
            enabled: stores.isNotEmpty,
          ),
        ),
        if (onRefreshStores != null) ...[
          const SizedBox(width: AppPadding.p8),
          Tooltip(
            message: 'Refresh daftar toko',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRefreshStores,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.purple,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build sub-brand dropdown (untuk SA - Spring Air)
  Widget _buildSubBrandDropdown(BuildContext context) {
    final subBrands = selectedStore?.availableSubBrands ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label dengan info
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.p10,
            vertical: AppPadding.p6,
          ),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.purple,
              ),
              const SizedBox(width: AppPadding.p6),
              Text(
                "Spring Air memiliki 2 tipe, silakan pilih:",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppPadding.p8),
        // Sub-brand dropdown
        CustomDropdown<String>(
          labelText: "Pilih Tipe Spring Air",
          items: subBrands,
          selectedValue: selectedSubBrand,
          onChanged: onSubBrandChanged,
          hintText: "Pilih Tipe Brand",
          isDynamicWidth: false,
          enabled: subBrands.isNotEmpty,
        ),
      ],
    );
  }

  /// Build channel dropdown (Toko / Massindo Fair - Toko)
  Widget _buildChannelDropdown(BuildContext context) {
    final channels = _filteredChannels;

    return CustomDropdown<String>(
      labelText: "Pilih Channel",
      items: channels,
      selectedValue: channels.contains(selectedChannel) ? selectedChannel : null,
      onChanged: onChannelChanged,
      hintText: channels.isEmpty ? "Channel belum tersedia" : "Pilih Channel",
      isDynamicWidth: false,
      enabled: channels.isNotEmpty,
    );
  }

  /// Build info section showing Brand & Area from selected store
  Widget _buildStoreInfoSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppPadding.p12),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(
                Icons.store_rounded,
                size: 18,
                color: AppColors.purple,
              ),
              SizedBox(width: AppPadding.p8),
              Text(
                "Info Toko Terpilih",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p10),

          // Info badges in row (Brand & Area only - Channel has dropdown)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoBadge(
                context,
                icon: Icons.sell_rounded,
                label: "Brand",
                value: selectedBrand ?? "-",
                isDark: isDark,
              ),
              _buildInfoBadge(
                context,
                icon: Icons.location_on_rounded,
                label: "Area",
                value: selectedArea ?? "-",
                isDark: isDark,
              ),
            ],
          ),

          // Address info
          if (selectedStore?.address != null &&
              selectedStore!.address.isNotEmpty) ...[
            const SizedBox(height: AppPadding.p10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.place_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppPadding.p6),
                Expanded(
                  child: Text(
                    selectedStore!.address.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build single info badge
  Widget _buildInfoBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.p10,
        vertical: AppPadding.p6,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.purple),
          const SizedBox(width: AppPadding.p4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context, String text) {
    return SizedBox(
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: AppPadding.p8),
            Text(
              text,
              style: TextStyle(
                fontSize: ResponsiveHelper.isMobile(context) ? 12 : 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Program",
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: ResponsiveHelper.isMobile(context) ? 10 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedProgram ?? "Auto",
                    style: TextStyle(
                      fontSize: ResponsiveHelper.isMobile(context) ? 12 : 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
