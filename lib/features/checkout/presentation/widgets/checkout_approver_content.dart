import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../data/models/approver_model.dart';
import 'searchable_dropdown_field.dart';

/// Inner content of the Approval card: SPV (direct) atau ASM (indirect) + opsional Manager.
///
/// Extracted from [CheckoutPage] build method to reduce file size.
/// Receives all data via constructor — no implicit state access.
class CheckoutApproverContent extends StatelessWidget {
  final List<Approver> approvers;
  final Approver? selectedSpv;
  final Approver? selectedManager;
  final bool requiresManager;

  /// Sales indirect: label dropdown tingkat pertama = ASM, bukan SPV.
  final bool isIndirectCheckout;

  /// True jika ASM/SPV diperlukan untuk pesanan ini.
  ///
  /// Indirect: true untuk customer baru, FOC, Medan, ukuran custom.
  /// **Diskon tambahan (d1–d3) hanya memicu RSM**, bukan ASM.
  /// Direct: selalu true.
  /// Ketika false, seluruh section ASM disembunyikan.
  final bool requiresSpv;

  /// True jika ada item yang bonusnya diubah dari bundle default — akan menampilkan
  /// badge peringatan (RSM diperlukan).
  final bool hasBonusCustomizedItem;

  /// True jika ada item dengan ukuran custom — ASM diperlukan (indirect).
  final bool hasCustomSizeItem;

  /// True jika ada item dengan FOC voucher aktif — ASM wajib menyetujui karena
  /// harga item menjadi 0 (gratis).
  final bool hasFocVoucherItem;

  /// True jika indirect dan:
  ///   - receiver mode adalah "Customer Baru" (bukan cabang/gudang), ATAU
  ///   - toko ditandai sebagai customer baru oleh API (search_type).
  final bool isCustomerBaru;

  /// True saat aturan Klaus aktif: workplace 1937/6015 + SPV 4147/1019.
  /// Pak Klaus (5247) auto-assign sebagai RSM — ditampilkan di badge info.
  final bool isKlausManagerAutoAssigned;

  final ValueChanged<Approver?> onSpvChanged;
  final ValueChanged<Approver?> onManagerChanged;

  const CheckoutApproverContent({
    super.key,
    required this.approvers,
    required this.selectedSpv,
    required this.selectedManager,
    required this.requiresManager,
    this.isIndirectCheckout = false,
    this.requiresSpv = true,
    this.hasBonusCustomizedItem = false,
    this.hasCustomSizeItem = false,
    this.hasFocVoucherItem = false,
    this.isCustomerBaru = false,
    this.isKlausManagerAutoAssigned = false,
    required this.onSpvChanged,
    required this.onManagerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (requiresSpv) ...[
          SearchableDropdownField<Approver>(
            label: isIndirectCheckout
                ? 'Area Sales Manager (ASM)'
                : 'Supervisor (SPV)',
            hint: isIndirectCheckout ? 'Pilih ASM' : 'Pilih SPV',
            selectedValue: selectedSpv,
            items: approvers,
            itemAsString: (a) => a.displayLabel,
            onChanged: onSpvChanged,
          ),
        ],
        if (hasBonusCustomizedItem) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.reasonBonus.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.reasonBonus.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.card_giftcard_outlined,
                    size: 14, color: AppColors.reasonBonusIcon),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ada bonus yang diubah dari bundle default — RSM wajib menyetujui.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.reasonBonusText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasCustomSizeItem && isIndirectCheckout) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.reasonCustomSize.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.reasonCustomSize.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.straighten_outlined,
                    size: 14, color: AppColors.reasonCustomSizeIcon),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ada item dengan ukuran custom — ASM wajib menyetujui.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.reasonCustomSizeText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasFocVoucherItem) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_outlined,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ada item FOC (gratis) — ASM wajib menyetujui.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isCustomerBaru) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Customer baru — ASM & RSM wajib menyetujui.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.accent.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (requiresManager) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const FormFieldLabel('Manager'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isKlausManagerAutoAssigned
                      ? 'Auto RSM — Lokasi khusus'
                      : isIndirectCheckout
                          ? (isCustomerBaru
                              ? 'Customer baru terdeteksi'
                              : 'Diskon / bonus terdeteksi')
                          : 'Diskon 3 terdeteksi',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (isKlausManagerAutoAssigned) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.reasonKlaus.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.reasonKlaus.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_pin_outlined,
                      size: 14, color: AppColors.reasonKlausIcon),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lokasi toko ini memerlukan persetujuan RSM Klaus secara otomatis.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.reasonKlausText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SearchableDropdownField<Approver>(
            label: 'Manager',
            hint: 'Pilih Manager',
            selectedValue: selectedManager,
            items: approvers,
            itemAsString: (a) => a.displayLabel,
            onChanged: onManagerChanged,
          ),
        ],
      ],
    );
  }
}
