import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/form_field_label.dart';

/// Wilayah selectors (Provinsi → Kota → Kecamatan → Kelurahan + kode pos).
///
/// Field bawah disembunyikan sampai parent-nya terisi (progressive disclosure).
/// Tapping any visible field runs [onPick] (4-step region sheet).
class CheckoutRegionFields extends StatelessWidget {
  const CheckoutRegionFields({
    super.key,
    required this.sectionLabel,
    required this.provinsi,
    required this.kota,
    required this.kecamatan,
    required this.onPick,
    this.kelurahan,
    this.kodepos,
    this.provinsiLabel = 'Provinsi *',
    this.kotaLabel = 'Kota / Kabupaten *',
    this.kecamatanLabel = 'Kecamatan *',
    this.kelurahanLabel = 'Kelurahan / Desa *',
    this.kodeposLabel = 'Kode Pos',
  });

  final String sectionLabel;
  final String? provinsi;
  final String? kota;
  final String? kecamatan;
  final String? kelurahan;
  final String? kodepos;
  final VoidCallback onPick;
  final String provinsiLabel;
  final String kotaLabel;
  final String kecamatanLabel;
  final String kelurahanLabel;
  final String kodeposLabel;

  @override
  Widget build(BuildContext context) {
    final hasProvinsi = (provinsi ?? '').trim().isNotEmpty;
    final hasKota = (kota ?? '').trim().isNotEmpty;
    final hasKecamatan = (kecamatan ?? '').trim().isNotEmpty;
    final hasKelurahan = (kelurahan ?? '').trim().isNotEmpty;
    final pos = kodepos?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(sectionLabel),
        const SizedBox(height: AppLayoutTokens.space8),
        _RegionField(
          label: provinsiLabel,
          value: provinsi,
          hint: 'Pilih Provinsi',
          onTap: onPick,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !hasProvinsi
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppLayoutTokens.space12),
                    _RegionField(
                      label: kotaLabel,
                      value: kota,
                      hint: 'Pilih Kota / Kabupaten',
                      onTap: onPick,
                    ),
                    if (hasKota) ...[
                      const SizedBox(height: AppLayoutTokens.space12),
                      _RegionField(
                        label: kecamatanLabel,
                        value: kecamatan,
                        hint: 'Pilih Kecamatan',
                        onTap: onPick,
                      ),
                    ],
                    if (hasKota && hasKecamatan) ...[
                      const SizedBox(height: AppLayoutTokens.space12),
                      _RegionField(
                        label: kelurahanLabel,
                        value: kelurahan,
                        hint: 'Pilih Kelurahan / Desa',
                        onTap: onPick,
                      ),
                    ],
                    if (hasKelurahan && pos.isNotEmpty) ...[
                      const SizedBox(height: AppLayoutTokens.space12),
                      _RegionField(
                        label: kodeposLabel,
                        value: pos,
                        hint: 'Kode Pos',
                        onTap: onPick,
                        readOnlyStyle: true,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _RegionField extends StatelessWidget {
  const _RegionField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.readOnlyStyle = false,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final bool readOnlyStyle;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    final hasValue = text.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppLayoutTokens.radius8),
      child: InputDecorator(
        // Jangan isEmpty + hintText + child hint sekaligus — itu bikin
        // label "Provinsi *" overlap dengan "Pilih Provinsi".
        decoration: CheckoutInputDecoration.form(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          suffixIcon: Icon(
            readOnlyStyle
                ? Icons.markunread_mailbox_outlined
                : Icons.location_on_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          fillColor: AppColors.surfaceLight,
        ),
        child: Text(
          hasValue ? text : hint,
          style: TextStyle(
            fontSize: 14,
            color: hasValue ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
