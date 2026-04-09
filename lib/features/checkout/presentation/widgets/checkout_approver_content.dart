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
  final ValueChanged<Approver?> onSpvChanged;
  final ValueChanged<Approver?> onManagerChanged;

  const CheckoutApproverContent({
    super.key,
    required this.approvers,
    required this.selectedSpv,
    required this.selectedManager,
    required this.requiresManager,
    this.isIndirectCheckout = false,
    required this.onSpvChanged,
    required this.onManagerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                child: const Text(
                  'Diskon 3 terdeteksi',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
