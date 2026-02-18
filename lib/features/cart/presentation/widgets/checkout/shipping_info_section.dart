import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/widgets/modern_text_field.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../region/data/models/province_model.dart';
import '../../../../region/data/models/city_model.dart';
import '../../../../region/data/models/district_model.dart';
import 'currency_input_formatter.dart';
import 'region_dropdown_section.dart';

/// Widget untuk menampilkan section informasi pengiriman
/// Pure UI widget - menerima controllers dan callbacks dari parent
class ShippingInfoSection extends StatelessWidget {
  final TextEditingController receiverController;
  final TextEditingController shippingAddressController;
  final TextEditingController customerAddressController;
  final TextEditingController deliveryDateController;
  final TextEditingController postageController;
  final TextEditingController notesController;
  final TextEditingController? emailController;
  final TextEditingController? shippingPhoneController;
  final bool isTakeAway;
  final bool shippingSameAsCustomer;
  final bool isDark;
  final GlobalKey<FormState> formKey;
  final ValueChanged<bool?> onSameAddressChanged;
  final VoidCallback onSelectDeliveryDate;
  final bool isIndirectCheckout;
  final Function(ProvinceModel?, CityModel?, DistrictModel?)? onRegionChanged;

  const ShippingInfoSection({
    super.key,
    required this.receiverController,
    required this.shippingAddressController,
    required this.customerAddressController,
    required this.deliveryDateController,
    required this.postageController,
    required this.notesController,
    this.emailController,
    this.shippingPhoneController,
    required this.isTakeAway,
    required this.shippingSameAsCustomer,
    required this.isDark,
    required this.formKey,
    required this.onSameAddressChanged,
    required this.onSelectDeliveryDate,
    this.isIndirectCheckout = false,
    this.onRegionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: AppPadding.p8),
          Text(
            'Informasi Pengiriman',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.surfaceLight : Colors.black,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!isTakeAway) ...[
            ModernTextField(
              controller: receiverController,
              label: 'Nama Penerima',
              icon: Icons.person_pin,
              validator: shippingSameAsCustomer 
                  ? null  // Skip validation when same as customer
                  : (val) => val == null || val.isEmpty 
                      ? 'Nama penerima wajib diisi' 
                      : null,
              isDark: isDark,
              enabled: !shippingSameAsCustomer,
            ),
            const SizedBox(height: AppPadding.p16),
            _buildSameAddressCheckbox(context),
            const SizedBox(height: AppPadding.p16),
            ModernTextField(
              controller: shippingAddressController,
              label: 'Alamat Pengiriman',
              icon: Icons.location_on,
              maxLines: 3,
              validator: shippingSameAsCustomer 
                  ? null  // Skip validation when same as customer
                  : (val) => val == null || val.isEmpty
                      ? 'Alamat pengiriman wajib diisi'
                      : null,
              isDark: isDark,
              enabled: !shippingSameAsCustomer,
            ),
            const SizedBox(height: AppPadding.p16),
            // Region dropdown section (Provinsi, Kota, Kecamatan)
            RegionDropdownSection(
              isDark: isDark,
              enabled: !shippingSameAsCustomer,
              onRegionChanged: onRegionChanged,
            ),
            const SizedBox(height: AppPadding.p16),
          ],
          _buildDeliveryDatePicker(context),
          const SizedBox(height: AppPadding.p16),
          // For indirect: show phone & email instead of ongkir when not same as customer
          if (isIndirectCheckout) ...[
            if (!shippingSameAsCustomer) ...[
              // Phone number field
              if (shippingPhoneController != null) ...[
                ModernTextField(
                  controller: shippingPhoneController!,
                  label: 'Nomor Telepon Penerima',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Nomor telepon wajib diisi';
                    }
                    return null;
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: AppPadding.p16),
              ],
              // Email field
              if (emailController != null) ...[
                ModernTextField(
                  controller: emailController!,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: AppPadding.p16),
              ],
            ],
          ] else ...[
            // For direct checkout: show ongkir
            ModernTextField(
              controller: postageController,
              label: 'Ongkir',
              icon: Icons.local_shipping,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              isDark: isDark,
            ),
            const SizedBox(height: AppPadding.p16),
          ],
          ModernTextField(
            controller: notesController,
            label: 'Catatan (Opsional)',
            icon: Icons.note,
            maxLines: 3,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSameAddressCheckbox(BuildContext context) {
    final checkboxLabel = isIndirectCheckout
        ? 'Samakan informasi pengiriman dengan informasi toko'
        : 'Alamat pengiriman sama dengan alamat customer';
        
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        checkboxLabel,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.surfaceLight : Colors.black,
            ),
      ),
      value: shippingSameAsCustomer,
      onChanged: onSameAddressChanged,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
    );
  }

  Widget _buildDeliveryDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: onSelectDeliveryDate,
      child: ModernTextField(
        controller: deliveryDateController,
        label: 'Tanggal Pengiriman',
        icon: Icons.calendar_today,
        enabled: false,
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Tanggal kirim wajib diisi';
          }
          return null;
        },
        isDark: isDark,
      ),
    );
  }
}

