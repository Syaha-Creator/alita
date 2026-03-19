import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';

/// Customer information form section extracted from CheckoutPage.
///
/// Contains: name, email, phone (+ optional backup), contact book picker,
/// and "save to contact book" checkbox.
class CustomerInfoSection extends StatelessWidget {
  const CustomerInfoSection({
    super.key,
    required this.customerNameCtrl,
    required this.customerEmailCtrl,
    required this.customerPhoneCtrl,
    required this.customerPhone2Ctrl,
    required this.showBackupPhone,
    required this.onToggleBackupPhone,
    required this.isFromContactBook,
    required this.shouldSaveCustomerContact,
    required this.onToggleSaveContact,
    required this.selectedContactId,
    required this.onContactFieldCleared,
    required this.onPickContact,
  });

  final TextEditingController customerNameCtrl;
  final TextEditingController customerEmailCtrl;
  final TextEditingController customerPhoneCtrl;
  final TextEditingController customerPhone2Ctrl;
  final bool showBackupPhone;
  final VoidCallback onToggleBackupPhone;
  final bool isFromContactBook;
  final bool shouldSaveCustomerContact;
  final ValueChanged<bool> onToggleSaveContact;
  final String? selectedContactId;
  final VoidCallback onContactFieldCleared;
  final VoidCallback onPickContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Informasi Pelanggan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onPickContact,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Icon(Icons.import_contacts, size: 18, color: AppColors.accent),
                  SizedBox(width: 6),
                  Text(
                    'Pilih Kontak',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: customerNameCtrl,
          label: 'Nama Pelanggan *',
          onChanged: (value) {
            if (value.trim().isEmpty && selectedContactId != null) {
              onContactFieldCleared();
            }
          },
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: customerEmailCtrl,
          label: 'Email *',
          keyboardType: TextInputType.emailAddress,
          isRequired: true,
        ),
        const SizedBox(height: 16),

        // Phone row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: customerPhoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  final isCleared = value.trim().isEmpty;
                  if (isCleared && selectedContactId != null) {
                    onContactFieldCleared();
                  }
                },
                style: const TextStyle(fontSize: 14),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Field ini wajib diisi'
                    : null,
                decoration: CheckoutInputDecoration.form(
                  labelText: 'No. HP Utama *',
                  labelStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(
                    Icons.phone,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            if (!showBackupPhone) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                width: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add, color: AppColors.accent),
                    tooltip: 'Tambah No. Kedua',
                    onPressed: onToggleBackupPhone,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: customerPhone2Ctrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 14),
                  decoration: CheckoutInputDecoration.form(
                    labelText: 'No. HP Kedua',
                    labelStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(
                      Icons.phone_android,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        // Save contact checkbox (only when NOT from contact book)
        if (!isFromContactBook) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: shouldSaveCustomerContact,
                  onChanged: (v) => onToggleSaveContact(v ?? true),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Simpan ke buku kontak',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool alignLabelWithHint = false,
    bool isRequired = false,
    ValueChanged<String>? onChanged,
  }) {
    final resolvedKeyboardType = keyboardType ??
        (maxLines > 1 ? TextInputType.multiline : TextInputType.text);
    final resolvedInputAction =
        maxLines > 1 ? TextInputAction.newline : TextInputAction.next;

    return TextFormField(
      controller: controller,
      keyboardType: resolvedKeyboardType,
      textInputAction: resolvedInputAction,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      validator: isRequired
          ? (value) => (value == null || value.trim().isEmpty)
              ? 'Field ini wajib diisi'
              : null
          : null,
      decoration: CheckoutInputDecoration.form(
        labelText: label,
        alignLabelWithHint: alignLabelWithHint,
        labelStyle: const TextStyle(fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: maxLines == 1,
      ),
    );
  }
}
