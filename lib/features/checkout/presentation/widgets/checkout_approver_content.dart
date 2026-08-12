import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../../core/widgets/selection_bottom_sheet.dart';
import '../../data/models/approver_model.dart';
import 'checkout_payment_card.dart';
import 'searchable_dropdown_field.dart';

/// Level yang bisa ditambah manual lewat tombol + (mode Indirect).
enum ManualApproverLevel { asm, rsm }

/// Inner content of the Approval card: SPV (direct) / ASM (indirect) + RSM/Manager.
///
/// Mode Indirect: tombol + untuk menambah slot ASM atau RSM secara manual.
class CheckoutApproverContent extends StatelessWidget {
  final List<Approver> approvers;
  final Approver? selectedSpv;
  final Approver? selectedManager;
  final bool requiresManager;

  /// Sales indirect: label dropdown tingkat pertama = ASM, bukan SPV.
  final bool isIndirectCheckout;

  /// True jika ASM/SPV diperlukan untuk pesanan ini.
  final bool requiresSpv;

  /// Indirect: slot ASM ditampilkan karena tombol + (bukan karena aturan otomatis).
  final bool manualAsmRequested;

  /// Indirect: slot RSM ditampilkan karena tombol +.
  final bool manualRsmRequested;

  final bool hasBonusCustomizedItem;
  final bool hasCustomSizeItem;
  final bool hasFocVoucherItem;
  final bool isCustomerBaru;
  final bool isKlausManagerAutoAssigned;

  final ValueChanged<Approver?> onSpvChanged;
  final ValueChanged<Approver?> onManagerChanged;
  final ValueChanged<ManualApproverLevel>? onManualLevelAdded;
  final VoidCallback? onRemoveManualAsm;
  final VoidCallback? onRemoveManualRsm;

  const CheckoutApproverContent({
    super.key,
    required this.approvers,
    required this.selectedSpv,
    required this.selectedManager,
    required this.requiresManager,
    this.isIndirectCheckout = false,
    this.requiresSpv = true,
    this.manualAsmRequested = false,
    this.manualRsmRequested = false,
    this.hasBonusCustomizedItem = false,
    this.hasCustomSizeItem = false,
    this.hasFocVoucherItem = false,
    this.isCustomerBaru = false,
    this.isKlausManagerAutoAssigned = false,
    required this.onSpvChanged,
    required this.onManagerChanged,
    this.onManualLevelAdded,
    this.onRemoveManualAsm,
    this.onRemoveManualRsm,
  });

  bool get _showAsm => requiresSpv || manualAsmRequested;
  bool get _showRsm => requiresManager || manualRsmRequested;
  bool get _canRemoveAsm =>
      isIndirectCheckout && manualAsmRequested && !requiresSpv;
  bool get _canRemoveRsm =>
      isIndirectCheckout && manualRsmRequested && !requiresManager;
  bool get _canAddAsm => isIndirectCheckout && !_showAsm;
  bool get _canAddRsm => isIndirectCheckout && !_showRsm;
  bool get _showAddChip =>
      isIndirectCheckout && (_canAddAsm || _canAddRsm) && onManualLevelAdded != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_showAsm && !_showRsm && isIndirectCheckout) ...[
          Text(
            'Belum ada persetujuan. Tap Tambah untuk memilih ASM atau RSM.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppLayoutTokens.space12),
        ],
        if (_showAsm) ...[
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
          if (_canRemoveAsm) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRemoveManualAsm,
                child: const Text('Hapus ASM'),
              ),
            ),
          ],
        ],
        if (hasBonusCustomizedItem) ...[
          const SizedBox(height: 8),
          const _ReasonBanner(
            icon: Icons.card_giftcard_outlined,
            iconColor: AppColors.reasonBonusIcon,
            bg: AppColors.reasonBonus,
            textColor: AppColors.reasonBonusText,
            message:
                'Ada bonus yang diubah dari bundle default — RSM wajib menyetujui.',
          ),
        ],
        if (hasCustomSizeItem && isIndirectCheckout) ...[
          const SizedBox(height: 8),
          const _ReasonBanner(
            icon: Icons.straighten_outlined,
            iconColor: AppColors.reasonCustomSizeIcon,
            bg: AppColors.reasonCustomSize,
            textColor: AppColors.reasonCustomSizeText,
            message: 'Ada item dengan ukuran custom — ASM wajib menyetujui.',
          ),
        ],
        if (hasFocVoucherItem) ...[
          const SizedBox(height: 8),
          _ReasonBanner(
            icon: Icons.card_giftcard_outlined,
            iconColor: AppColors.success,
            bg: AppColors.success,
            textColor: AppColors.success.withValues(alpha: 0.9),
            message: 'Ada item FOC (gratis) — ASM wajib menyetujui.',
          ),
        ],
        if (isCustomerBaru) ...[
          const SizedBox(height: 8),
          _ReasonBanner(
            icon: Icons.person_outline,
            iconColor: AppColors.accent,
            bg: AppColors.accent,
            textColor: AppColors.accent.withValues(alpha: 0.85),
            message: 'Customer baru — ASM wajib menyetujui.',
          ),
        ],
        if (_showRsm) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              FormFieldLabel(isIndirectCheckout ? 'RSM' : 'Manager'),
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
                      : !requiresManager
                          ? 'Ditambahkan manual'
                          : isIndirectCheckout
                              ? 'Diskon / bonus terdeteksi'
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
            const _ReasonBanner(
              icon: Icons.person_pin_outlined,
              iconColor: AppColors.reasonKlausIcon,
              bg: AppColors.reasonKlaus,
              textColor: AppColors.reasonKlausText,
              message:
                  'Lokasi toko ini memerlukan persetujuan RSM Klaus secara otomatis.',
            ),
          ],
          const SizedBox(height: 8),
          SearchableDropdownField<Approver>(
            label: isIndirectCheckout ? 'RSM' : 'Manager',
            hint: isIndirectCheckout ? 'Pilih RSM' : 'Pilih Manager',
            selectedValue: selectedManager,
            items: approvers,
            itemAsString: (a) => a.displayLabel,
            onChanged: onManagerChanged,
          ),
          if (_canRemoveRsm) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRemoveManualRsm,
                child: const Text('Hapus RSM'),
              ),
            ),
          ],
        ],
        if (_showAddChip) ...[
          const SizedBox(height: AppLayoutTokens.space12),
          AddPaymentChip(
            onTap: () => _openAddLevelSheet(context),
          ),
        ],
      ],
    );
  }

  Future<void> _openAddLevelSheet(BuildContext context) async {
    final options = <ManualApproverLevel>[
      if (_canAddAsm) ManualApproverLevel.asm,
      if (_canAddRsm) ManualApproverLevel.rsm,
    ];
    if (options.isEmpty || onManualLevelAdded == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectionBottomSheet<ManualApproverLevel>(
        title: 'Tambah persetujuan',
        items: options,
        selectedItem: null,
        labelBuilder: (level) => switch (level) {
          ManualApproverLevel.asm => 'Area Sales Manager (ASM)',
          ManualApproverLevel.rsm => 'Regional Sales Manager (RSM)',
        },
        onItemSelected: onManualLevelAdded!,
      ),
    );
  }
}

class _ReasonBanner extends StatelessWidget {
  const _ReasonBanner({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.textColor,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color textColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
