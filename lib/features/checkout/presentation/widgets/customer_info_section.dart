import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import 'pick_contact_pill.dart';

/// Customer information form section extracted from CheckoutPage.
///
/// Contains: name, email, phone (+ optional backup), and a server-side
/// contact book picker (see `ContactPickerBottomSheet` / `/address_books`).
class CustomerInfoSection extends StatelessWidget {
  const CustomerInfoSection({
    super.key,
    this.sectionTitle = 'Informasi Pelanggan',
    this.sectionSubtitle,

    /// Indirect: email & HP utama tidak wajib; hanya format jika diisi.
    this.storeContactOptional = false,

    /// Indirect: hanya nama toko — tanpa email/HP (nomor penerima hanya saat alamat beda).
    this.indirectStoreOnly = false,
    this.customerNameFieldLabel = 'Nama Pelanggan *',
    required this.customerNameCtrl,
    required this.customerEmailCtrl,
    required this.customerPhoneCtrl,
    required this.customerPhone2Ctrl,
    required this.showBackupPhone,
    required this.onToggleBackupPhone,
    required this.isFromContactBook,
    required this.onContactFieldCleared,
    required this.onPickContact,
  });

  /// Judul blok (mis. "Informasi Pelanggan (Toko)" untuk indirect).
  final String sectionTitle;

  /// Teks penjelas singkat di bawah judul (opsional).
  final String? sectionSubtitle;

  final bool storeContactOptional;
  final bool indirectStoreOnly;
  final String customerNameFieldLabel;

  final TextEditingController customerNameCtrl;
  final TextEditingController customerEmailCtrl;
  final TextEditingController customerPhoneCtrl;
  final TextEditingController customerPhone2Ctrl;
  final bool showBackupPhone;
  final VoidCallback onToggleBackupPhone;
  final bool isFromContactBook;
  final VoidCallback onContactFieldCleared;
  final VoidCallback onPickContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (indirectStoreOnly)
          Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              PickContactPill(onTap: onPickContact),
            ],
          ),
        if (sectionSubtitle != null && sectionSubtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: AppLayoutTokens.space8),
          Text(
            sectionSubtitle!.trim(),
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          controller: customerNameCtrl,
          label: customerNameFieldLabel,
          onChanged: (value) {
            if (value.trim().isEmpty && isFromContactBook) {
              onContactFieldCleared();
            }
          },
          isRequired: true,
        ),
        if (!indirectStoreOnly) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: customerEmailCtrl,
            label: storeContactOptional ? 'Email' : 'Email *',
            keyboardType: TextInputType.emailAddress,
            validator: storeContactOptional
                ? (value) {
                    final t = value?.trim() ?? '';
                    if (t.isEmpty) return null;
                    if (!RegExp(r'^[\w.+-]+@[\w.-]+\.\w{2,}$').hasMatch(t)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  }
                : (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Field ini wajib diisi';
                    }
                    if (!RegExp(r'^[\w.+-]+@[\w.-]+\.\w{2,}$')
                        .hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
          ),
          const SizedBox(height: 16),
          _buildCustomerPhoneRow(contactOptional: storeContactOptional),
        ],
      ],
    );
  }

  /// Shared HP utama + tombol tambah / HP kedua (sama layout direct & indirect toko).
  Widget _buildCustomerPhoneRow({required bool contactOptional}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: customerPhoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              final isCleared = value.trim().isEmpty;
              if (isCleared && isFromContactBook) {
                onContactFieldCleared();
              }
            },
            style: const TextStyle(fontSize: 14),
            validator: contactOptional
                ? (value) {
                    final t = value?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final digits = t.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10 || digits.length > 15) {
                      return 'No. HP harus 10–15 digit';
                    }
                    return null;
                  }
                : (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Field ini wajib diisi';
                    }
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10 || digits.length > 15) {
                      return 'No. HP harus 10–15 digit';
                    }
                    return null;
                  },
            decoration: CheckoutInputDecoration.form(
              labelText: contactOptional ? 'No. HP Utama' : 'No. HP Utama *',
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
          const SizedBox(width: AppLayoutTokens.space8),
          SizedBox(
            height: 44,
            width: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppLayoutTokens.radius8),
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
          const SizedBox(width: AppLayoutTokens.space8),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool alignLabelWithHint = false,
    bool isRequired = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    final resolvedKeyboardType = keyboardType ??
        (maxLines > 1 ? TextInputType.multiline : TextInputType.text);
    final resolvedInputAction =
        maxLines > 1 ? TextInputAction.newline : TextInputAction.next;

    final effectiveValidator = validator ??
        (isRequired
            ? (String? value) => (value == null || value.trim().isEmpty)
                ? 'Field ini wajib diisi'
                : null
            : null);

    return TextFormField(
      controller: controller,
      keyboardType: resolvedKeyboardType,
      textInputAction: resolvedInputAction,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      validator: effectiveValidator,
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
