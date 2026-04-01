import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/date_picker_field_tile.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../data/models/store_model.dart';

/// Delivery information section extracted from CheckoutPage.
///
/// Contains: store picker, request date picker, delivery method toggle
/// (Kurir Pabrik / Bawa Sendiri), postage field, order notes, and SC code.
class DeliveryInfoSection extends StatelessWidget {
  const DeliveryInfoSection({
    super.key,
    required this.requestDate,
    required this.onPickRequestDate,
    required this.isTakeAway,
    required this.onTakeAwayChanged,
    required this.postageCtrl,
    required this.notesController,
    required this.scCodeCtrl,
    this.isLoadingWorkPlace = false,
    this.attendanceWorkPlaceName = '',
    this.useAttendanceStore = true,
    this.onToggleUseAttendance,
    this.selectedStore,
    this.onPickStore,
  });

  final DateTime? requestDate;
  final VoidCallback onPickRequestDate;
  final bool isTakeAway;
  final ValueChanged<bool> onTakeAwayChanged;
  final TextEditingController postageCtrl;
  final TextEditingController notesController;
  final TextEditingController scCodeCtrl;

  final bool isLoadingWorkPlace;
  final String attendanceWorkPlaceName;
  final bool useAttendanceStore;
  final ValueChanged<bool>? onToggleUseAttendance;
  final StoreModel? selectedStore;
  final VoidCallback? onPickStore;

  static final _dateFmt = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. Lokasi Toko
        const FormFieldLabel('Lokasi Toko'),
        const SizedBox(height: 8),
        _StoreLocationBlock(
          isLoading: isLoadingWorkPlace,
          attendanceName: attendanceWorkPlaceName,
          useAttendance: useAttendanceStore,
          onToggleAttendance: onToggleUseAttendance,
          selectedStore: selectedStore,
          onPickStore: onPickStore,
        ),
        const SizedBox(height: 16),

        // 1. Tanggal Permintaan Kirim
        const FormFieldLabel('Tanggal Permintaan Kirim'),
        const SizedBox(height: 8),
        FormField<DateTime>(
          validator: (_) {
            if (!isTakeAway && requestDate == null) {
              return 'Tanggal wajib dipilih';
            }
            return null;
          },
          builder: (formState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DatePickerFieldTile(
                  text: switch (requestDate) {
                    final rd? => _dateFmt.format(rd),
                    null => '',
                  },
                  hasError: formState.hasError,
                  errorText: formState.errorText,
                  onTap: () {
                    onPickRequestDate();
                    formState.didChange(requestDate);
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // 2. Metode Pengiriman
        const FormFieldLabel('Metode Pengiriman'),
        const SizedBox(height: 8),
        SegmentedToggle(
          leftLabel: 'Kurir Pabrik',
          leftIcon: Icons.local_shipping_outlined,
          rightLabel: 'Bawa Sendiri',
          rightIcon: Icons.directions_car_outlined,
          isLeftSelected: !isTakeAway,
          onTapLeft: () => onTakeAwayChanged(false),
          onTapRight: () => onTakeAwayChanged(true),
        ),

        // Ongkos Kirim (only for factory courier)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isTakeAway
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const FormFieldLabel('Ongkos Kirim (Jika Ada)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: postageCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      style: const TextStyle(fontSize: 14),
                      decoration: CheckoutInputDecoration.form(
                        prefixText: 'Rp ',
                        hintText: '0',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 12),

        // 3. Catatan Pesanan
        const FormFieldLabel('Catatan Pesanan'),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: CheckoutInputDecoration.form(
            hintText: 'Misal: Telpon sebelum kirim, masuk gang...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            isDense: false,
          ),
        ),

        const SizedBox(height: 12),

        // 4. SC Code
        const FormFieldLabel('SC Code'),
        const SizedBox(height: 8),
        TextField(
          controller: scCodeCtrl,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 14),
          decoration: CheckoutInputDecoration.form(
            hintText: 'Masukkan SC Code (Opsional)',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ── Lokasi Toko: compact radio-selection card ────────────────────

class _StoreLocationBlock extends StatelessWidget {
  const _StoreLocationBlock({
    required this.isLoading,
    required this.attendanceName,
    required this.useAttendance,
    this.onToggleAttendance,
    this.selectedStore,
    this.onPickStore,
  });

  final bool isLoading;
  final String attendanceName;
  final bool useAttendance;
  final ValueChanged<bool>? onToggleAttendance;
  final StoreModel? selectedStore;
  final VoidCallback? onPickStore;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
        ),
      );
    }

    final hasAttendance = attendanceName.isNotEmpty;

    if (!hasAttendance) {
      return _SimplePickerField(
        store: selectedStore,
        onTap: onPickStore ?? () {},
      );
    }

    final hasStore = selectedStore != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OptionTile(
            icon: Icons.location_on_rounded,
            title: AppFormatters.titleCase(attendanceName),
            caption: 'Lokasi check-in',
            isSelected: useAttendance,
            onTap: () => onToggleAttendance?.call(true),
          ),
          const Divider(height: 0, thickness: 0.5, indent: 42),
          _OptionTile(
            icon: Icons.storefront_rounded,
            title: hasStore
                ? selectedStore!.displayLabelOrFallback
                : 'Pilih toko lain',
            caption:
                (!useAttendance && hasStore) ? 'Dipilih manual' : null,
            isSelected: !useAttendance,
            isPlaceholder: useAttendance && !hasStore,
            onTap: onPickStore,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    this.caption,
    required this.isSelected,
    this.isPlaceholder = false,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? caption;
  final bool isSelected;
  final bool isPlaceholder;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _RadioDot(isSelected: isSelected),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 17,
              color: isSelected ? AppColors.accent : AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: caption != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          caption!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: _titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Color get _titleColor {
    if (isPlaceholder) return AppColors.textTertiary;
    return isSelected ? AppColors.textPrimary : AppColors.textSecondary;
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.textTertiary,
          width: isSelected ? 5 : 1.5,
        ),
      ),
    );
  }
}

class _SimplePickerField extends StatelessWidget {
  const _SimplePickerField({required this.store, required this.onTap});

  final StoreModel? store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = store != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
      child: InputDecorator(
        decoration: CheckoutInputDecoration.form(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
          suffixIcon: const Icon(
            Icons.storefront_rounded,
            size: 20,
            color: AppColors.textTertiary,
          ),
        ),
        child: Text(
          hasValue ? store!.displayLabelOrFallback : 'Pilih toko...',
          style: TextStyle(
            fontSize: 13,
            color: hasValue ? AppColors.textPrimary : AppColors.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
