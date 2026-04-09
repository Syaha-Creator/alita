import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/form_field_label.dart';

/// Shipping address section extracted from CheckoutPage.
///
/// Includes the "Kirim ke alamat pelanggan" toggle, the address/region
/// fields for customer, and the optional receiver (dropship) sub-form.
class ShippingInfoSection extends StatelessWidget {
  const ShippingInfoSection({
    super.key,
    this.sectionTitle = 'Alamat & Pengiriman',
    this.sameAsCustomerLabel = 'Kirim ke alamat pelanggan di atas',
    this.receiverBlockTitle = 'Informasi Penerima (Dropship / Lokasi Lain)',
    this.useStoreAddressLabels = false,
    /// Indirect: nama & no. HP penerima/gudang opsional (format dicek jika diisi).
    this.receiverContactOptional = false,
    /// Indirect: sembunyikan pemilih wilayah toko; cukup detail alamat.
    this.hideCustomerRegionPicker = false,
    /// Indirect + alamat beda: email penerima (opsional).
    this.showIndirectAlternateReceiverEmail = false,
    this.shippingEmailCtrl,
    this.showIndirectSaveReceiverContact = false,
    this.isFromContactBook = false,
    this.shouldSaveReceiverContact = true,
    required this.onToggleSaveReceiverContact,
    required this.customerAddressCtrl,
    required this.regionCtrl,
    required this.isShippingSameAsCustomer,
    required this.onToggleSameAddress,
    required this.onPickCustomerRegion,
    // Receiver fields
    required this.shippingNameCtrl,
    required this.shippingPhoneCtrl,
    required this.shippingPhone2Ctrl,
    required this.showReceiverBackupPhone,
    required this.onToggleReceiverBackupPhone,
    required this.shippingAddressCtrl,
    required this.shippingRegionCtrl,
    required this.onPickShippingRegion,
  });

  final String sectionTitle;
  final String sameAsCustomerLabel;
  final String receiverBlockTitle;
  final bool useStoreAddressLabels;
  final bool hideCustomerRegionPicker;
  final bool receiverContactOptional;
  final bool showIndirectAlternateReceiverEmail;
  final TextEditingController? shippingEmailCtrl;
  final bool showIndirectSaveReceiverContact;
  final bool isFromContactBook;
  final bool shouldSaveReceiverContact;
  final ValueChanged<bool> onToggleSaveReceiverContact;

  final TextEditingController customerAddressCtrl;
  final TextEditingController regionCtrl;
  final bool isShippingSameAsCustomer;
  final ValueChanged<bool> onToggleSameAddress;
  final VoidCallback onPickCustomerRegion;

  final TextEditingController shippingNameCtrl;
  final TextEditingController shippingPhoneCtrl;
  final TextEditingController shippingPhone2Ctrl;
  final bool showReceiverBackupPhone;
  final VoidCallback onToggleReceiverBackupPhone;
  final TextEditingController shippingAddressCtrl;
  final TextEditingController shippingRegionCtrl;
  final VoidCallback onPickShippingRegion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32, color: AppColors.border),
        Text(
          sectionTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (!hideCustomerRegionPicker) ...[
          FormFieldLabel(
            useStoreAddressLabels ? 'Wilayah Toko' : 'Wilayah Pelanggan',
          ),
          const SizedBox(height: 8),
          _buildRegionSelector(
            controller: regionCtrl,
            label: 'Provinsi, Kota/Kab, Kecamatan *',
            onTap: onPickCustomerRegion,
          ),
          const SizedBox(height: 16),
        ],
        FormFieldLabel(
          useStoreAddressLabels
              ? 'Detail Alamat Toko'
              : 'Detail Alamat Pelanggan',
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: customerAddressCtrl,
          label: 'Detail Alamat (Nama Jalan, Blok, RT/RW, Patokan) *',
          maxLines: 2,
          alignLabelWithHint: true,
          isRequired: true,
        ),

        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox.adaptive(
                value: isShippingSameAsCustomer,
                onChanged: (v) => onToggleSameAddress(v ?? true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sameAsCustomerLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        // Receiver sub-form
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isShippingSameAsCustomer
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      receiverBlockTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: shippingNameCtrl,
                      label: receiverContactOptional
                          ? 'Nama Penerima'
                          : 'Nama Penerima *',
                      isRequired: !receiverContactOptional,
                    ),
                    const SizedBox(height: 16),
                    _buildReceiverPhoneRow(),
                    if (showIndirectAlternateReceiverEmail &&
                        shippingEmailCtrl != null) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: shippingEmailCtrl!,
                        label: 'Email penerima',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final t = value?.trim() ?? '';
                          if (t.isEmpty) return null;
                          if (!RegExp(r'^[\w.+-]+@[\w.-]+\.\w{2,}$')
                              .hasMatch(t)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildRegionSelector(
                      controller: shippingRegionCtrl,
                      label: 'Provinsi, Kota/Kab, Kecamatan Penerima *',
                      onTap: onPickShippingRegion,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: shippingAddressCtrl,
                      label:
                          'Detail Alamat Penerima (Jalan, Blok, Patokan) *',
                      maxLines: 2,
                      alignLabelWithHint: true,
                      isRequired: true,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
        ),
        if (showIndirectSaveReceiverContact && !isFromContactBook) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox.adaptive(
                  value: shouldSaveReceiverContact,
                  onChanged: (v) => onToggleSaveReceiverContact(v ?? true),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Simpan kontak penerima ke buku kontak',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// HP penerima utama + tambah / HP kedua (layout sama seperti blok pelanggan).
  Widget _buildReceiverPhoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: shippingPhoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14),
            validator: receiverContactOptional
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
              labelText: receiverContactOptional
                  ? 'No. HP Utama'
                  : 'No. HP Utama *',
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
        if (!showReceiverBackupPhone) ...[
          const SizedBox(width: AppLayoutTokens.space8),
          SizedBox(
            height: 44,
            width: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius:
                    BorderRadius.circular(AppLayoutTokens.radius8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add, color: AppColors.accent),
                tooltip: 'Tambah No. Kedua',
                onPressed: onToggleReceiverBackupPhone,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(width: AppLayoutTokens.space8),
          Expanded(
            child: TextField(
              controller: shippingPhone2Ctrl,
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

  Widget _buildRegionSelector({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: controller,
          decoration: CheckoutInputDecoration.form(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13),
            hintText: 'Pilih Wilayah',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            fillColor: AppColors.surfaceLight,
          ),
        ),
      ),
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
