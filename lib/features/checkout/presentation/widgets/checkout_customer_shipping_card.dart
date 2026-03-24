import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'customer_info_section.dart';
import 'shipping_info_section.dart';

/// Customer info + shipping card for checkout page.
///
/// Wraps [CustomerInfoSection] and [ShippingInfoSection] in a styled container.
class CheckoutCustomerShippingCard extends StatelessWidget {
  const CheckoutCustomerShippingCard({
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
    this.onCloudLookup,
    this.isCloudLookupLoading = false,
    required this.customerAddressCtrl,
    required this.regionCtrl,
    required this.isShippingSameAsCustomer,
    required this.onToggleSameAddress,
    required this.onPickCustomerRegion,
    required this.shippingNameCtrl,
    required this.shippingPhoneCtrl,
    required this.shippingAddressCtrl,
    required this.shippingRegionCtrl,
    required this.onPickShippingRegion,
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
  final VoidCallback? onCloudLookup;
  final bool isCloudLookupLoading;

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerInfoSection(
            customerNameCtrl: customerNameCtrl,
            customerEmailCtrl: customerEmailCtrl,
            customerPhoneCtrl: customerPhoneCtrl,
            customerPhone2Ctrl: customerPhone2Ctrl,
            showBackupPhone: showBackupPhone,
            onToggleBackupPhone: onToggleBackupPhone,
            isFromContactBook: isFromContactBook,
            shouldSaveCustomerContact: shouldSaveCustomerContact,
            onToggleSaveContact: onToggleSaveContact,
            selectedContactId: selectedContactId,
            onContactFieldCleared: onContactFieldCleared,
            onPickContact: onPickContact,
            onCloudLookup: onCloudLookup,
            isCloudLookupLoading: isCloudLookupLoading,
          ),
          ShippingInfoSection(
            customerAddressCtrl: customerAddressCtrl,
            regionCtrl: regionCtrl,
            isShippingSameAsCustomer: isShippingSameAsCustomer,
            onToggleSameAddress: onToggleSameAddress,
            onPickCustomerRegion: onPickCustomerRegion,
            shippingNameCtrl: shippingNameCtrl,
            shippingPhoneCtrl: shippingPhoneCtrl,
            shippingAddressCtrl: shippingAddressCtrl,
            shippingRegionCtrl: shippingRegionCtrl,
            onPickShippingRegion: onPickShippingRegion,
          ),
        ],
      ),
    );
  }
}
