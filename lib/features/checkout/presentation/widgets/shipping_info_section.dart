import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/form_field_label.dart';

/// Shipping address section extracted from CheckoutPage.
///
/// Includes the "Kirim ke alamat pelanggan" toggle, the address/region
/// fields for customer, and the optional receiver (dropship) sub-form.
class ShippingInfoSection extends StatelessWidget {
  const ShippingInfoSection({
    super.key,
    required this.customerAddressCtrl,
    required this.regionCtrl,
    required this.isShippingSameAsCustomer,
    required this.onToggleSameAddress,
    required this.onPickCustomerRegion,
    // Receiver fields
    required this.shippingNameCtrl,
    required this.shippingPhoneCtrl,
    required this.shippingAddressCtrl,
    required this.shippingRegionCtrl,
    required this.onPickShippingRegion,
  });

  final TextEditingController customerAddressCtrl;
  final TextEditingController regionCtrl;
  final bool isShippingSameAsCustomer;
  final ValueChanged<bool> onToggleSameAddress;
  final VoidCallback onPickCustomerRegion;

  final TextEditingController shippingNameCtrl;
  final TextEditingController shippingPhoneCtrl;
  final TextEditingController shippingAddressCtrl;
  final TextEditingController shippingRegionCtrl;
  final VoidCallback onPickShippingRegion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32, color: AppColors.border),
        const Text(
          'Alamat & Pengiriman',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        const FormFieldLabel('Wilayah Pelanggan'),
        const SizedBox(height: 8),
        _buildRegionSelector(
          controller: regionCtrl,
          label: 'Provinsi, Kota/Kab, Kecamatan *',
          onTap: onPickCustomerRegion,
        ),
        const SizedBox(height: 16),
        const FormFieldLabel('Detail Alamat Pelanggan'),
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
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isShippingSameAsCustomer,
                onChanged: (v) => onToggleSameAddress(v ?? true),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Kirim ke alamat pelanggan di atas',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
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
                      'Informasi Penerima (Dropship / Lokasi Lain)',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: shippingNameCtrl,
                      label: 'Nama Penerima *',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: shippingPhoneCtrl,
                      label: 'No. HP Penerima *',
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                    ),
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
