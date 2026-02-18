import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/app_constant.dart';
import '../../../../../core/widgets/custom_dropdown.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../region/data/models/province_model.dart';
import '../../../../region/data/models/city_model.dart';
import '../../../../region/data/models/district_model.dart';
import '../../../../region/presentation/bloc/region_cubit.dart';
import '../../../../region/presentation/bloc/region_state.dart';

/// Widget untuk dropdown cascading wilayah (Provinsi → Kota → Kecamatan)
class RegionDropdownSection extends StatefulWidget {
  final bool isDark;
  final bool enabled;
  final Function(ProvinceModel?, CityModel?, DistrictModel?)? onRegionChanged;

  const RegionDropdownSection({
    super.key,
    required this.isDark,
    this.enabled = true,
    this.onRegionChanged,
  });

  @override
  State<RegionDropdownSection> createState() => _RegionDropdownSectionState();
}

class _RegionDropdownSectionState extends State<RegionDropdownSection> {
  late RegionCubit _regionCubit;

  @override
  void initState() {
    super.initState();
    _regionCubit = RegionCubit();
    _regionCubit.loadProvinces();
  }

  @override
  void dispose() {
    _regionCubit.close();
    super.dispose();
  }

  void _notifyRegionChanged(RegionState state) {
    widget.onRegionChanged?.call(
      state.selectedProvince,
      state.selectedCity,
      state.selectedDistrict,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _regionCubit,
      child: BlocConsumer<RegionCubit, RegionState>(
        listener: (context, state) {
          // Notify parent when region selection changes
          _notifyRegionChanged(state);
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: widget.isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    size: 16,
                  ),
                  const SizedBox(width: AppPadding.p8),
                  Text(
                    'Wilayah Pengiriman',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '(Opsional)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.isDark
                              ? AppColors.textSecondaryDark.withValues(alpha: 0.6)
                              : AppColors.textSecondaryLight.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppPadding.p12),

              // Province Dropdown
              _buildProvinceDropdown(context, state),
              const SizedBox(height: AppPadding.p12),

              // City Dropdown
              _buildCityDropdown(context, state),
              const SizedBox(height: AppPadding.p12),

              // District Dropdown
              _buildDistrictDropdown(context, state),

              // Error message
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppPadding.p8),
                Text(
                  state.errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildProvinceDropdown(BuildContext context, RegionState state) {
    final bool isLoading = state.isLoadingProvinces;
    final bool hasData = state.provinces.isNotEmpty;

    return Stack(
      children: [
        CustomDropdown<ProvinceModel>(
          labelText: 'Provinsi',
          items: state.provinces,
          selectedValue: state.selectedProvince,
          onChanged: widget.enabled
              ? (province) => _regionCubit.selectProvince(province)
              : (_) {},
          hintText: isLoading
              ? 'Memuat...'
              : (hasData ? 'Pilih Provinsi' : 'Tidak ada data'),
          enabled: widget.enabled && hasData && !isLoading,
          isSearchable: true,
        ),
        if (isLoading)
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCityDropdown(BuildContext context, RegionState state) {
    final bool isLoading = state.isLoadingCities;
    final bool hasProvince = state.selectedProvince != null;
    final bool hasData = state.cities.isNotEmpty;

    String hintText;
    if (!hasProvince) {
      hintText = 'Pilih Provinsi terlebih dahulu';
    } else if (isLoading) {
      hintText = 'Memuat...';
    } else if (!hasData) {
      hintText = 'Tidak ada data';
    } else {
      hintText = 'Pilih Kota/Kabupaten';
    }

    return Stack(
      children: [
        CustomDropdown<CityModel>(
          labelText: 'Kota/Kabupaten',
          items: state.cities,
          selectedValue: state.selectedCity,
          onChanged: widget.enabled && hasProvince
              ? (city) => _regionCubit.selectCity(city)
              : (_) {},
          hintText: hintText,
          enabled: widget.enabled && hasProvince && hasData && !isLoading,
          isSearchable: true,
        ),
        if (isLoading)
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDistrictDropdown(BuildContext context, RegionState state) {
    final bool isLoading = state.isLoadingDistricts;
    final bool hasCity = state.selectedCity != null;
    final bool hasData = state.districts.isNotEmpty;

    String hintText;
    if (!hasCity) {
      hintText = 'Pilih Kota/Kabupaten terlebih dahulu';
    } else if (isLoading) {
      hintText = 'Memuat...';
    } else if (!hasData) {
      hintText = 'Tidak ada data';
    } else {
      hintText = 'Pilih Kecamatan';
    }

    return Stack(
      children: [
        CustomDropdown<DistrictModel>(
          labelText: 'Kecamatan',
          items: state.districts,
          selectedValue: state.selectedDistrict,
          onChanged: widget.enabled && hasCity
              ? (district) => _regionCubit.selectDistrict(district)
              : (_) {},
          hintText: hintText,
          enabled: widget.enabled && hasCity && hasData && !isLoading,
          isSearchable: true,
        ),
        if (isLoading)
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
