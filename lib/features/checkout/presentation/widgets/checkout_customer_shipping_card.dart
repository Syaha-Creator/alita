import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/store_model.dart';
import 'customer_info_section.dart';
import 'shipping_info_section.dart';

/// Customer info + shipping card for checkout page.
///
/// Wraps [CustomerInfoSection] and [ShippingInfoSection] in a styled container.
class CheckoutCustomerShippingCard extends StatelessWidget {
  const CheckoutCustomerShippingCard({
    super.key,
    this.customerSectionTitle = 'Informasi Pelanggan',
    this.customerSectionSubtitle,
    this.shippingSectionTitle = 'Alamat & Pengiriman',
    this.sameAsCustomerLabel = 'Kirim ke alamat pelanggan di atas',
    this.receiverBlockTitle = 'Informasi Penerima (Dropship / Lokasi Lain)',
    this.storeContactOptional = false,
    this.customerNameFieldLabel = 'Nama Pelanggan *',
    this.useStoreAddressLabels = false,
    this.hideCustomerRegionPicker = false,
    this.receiverContactOptional = false,
    this.indirectStoreOnly = false,
    this.showIndirectAlternateReceiverEmail = false,
    this.shippingEmailCtrl,
    required this.customerNameCtrl,
    required this.customerEmailCtrl,
    required this.customerPhoneCtrl,
    required this.customerPhone2Ctrl,
    required this.showBackupPhone,
    required this.onToggleBackupPhone,
    required this.isFromContactBook,
    required this.onContactFieldCleared,
    required this.onPickContact,
    required this.customerProvinsi,
    required this.customerKota,
    required this.customerKecamatan,
    this.customerKelurahan,
    this.customerKodepos,
    required this.onPickCustomerRegion,
    required this.customerAddressLine1Ctrl,
    required this.customerAddressLine2Ctrl,
    required this.customerAddressLine3Ctrl,
    required this.showCustomerAddressLine3,
    required this.onShowCustomerAddressLine3,
    required this.isShippingSameAsCustomer,
    required this.onToggleSameAddress,
    required this.shippingNameCtrl,
    required this.shippingPhoneCtrl,
    required this.shippingPhone2Ctrl,
    required this.showReceiverBackupPhone,
    required this.onToggleReceiverBackupPhone,
    required this.shippingProvinsi,
    required this.shippingKota,
    required this.shippingKecamatan,
    this.shippingKelurahan,
    this.shippingKodepos,
    required this.onPickShippingRegion,
    required this.shippingAddressLine1Ctrl,
    required this.shippingAddressLine2Ctrl,
    required this.shippingAddressLine3Ctrl,
    required this.showShippingAddressLine3,
    required this.onShowShippingAddressLine3,
    this.isReceiverBranchMode = true,
    this.onToggleReceiverBranchMode,
    this.availableStores = const [],
    this.selectedReceiverStore,
    this.onReceiverStorePicked,
    this.onPickReceiverContact,
    this.isFromReceiverContactBook = false,
    this.onRefreshStores,
    this.isRefreshingStores = false,
  });

  final String customerSectionTitle;
  final String? customerSectionSubtitle;
  final String shippingSectionTitle;
  final String sameAsCustomerLabel;
  final String receiverBlockTitle;
  final bool storeContactOptional;
  final String customerNameFieldLabel;
  final bool useStoreAddressLabels;
  final bool hideCustomerRegionPicker;
  final bool receiverContactOptional;
  final bool indirectStoreOnly;
  final bool showIndirectAlternateReceiverEmail;
  final TextEditingController? shippingEmailCtrl;

  final TextEditingController customerNameCtrl;
  final TextEditingController customerEmailCtrl;
  final TextEditingController customerPhoneCtrl;
  final TextEditingController customerPhone2Ctrl;
  final bool showBackupPhone;
  final VoidCallback onToggleBackupPhone;
  final bool isFromContactBook;
  final VoidCallback onContactFieldCleared;
  final VoidCallback onPickContact;

  final String? customerProvinsi;
  final String? customerKota;
  final String? customerKecamatan;
  final String? customerKelurahan;
  final String? customerKodepos;
  final VoidCallback onPickCustomerRegion;
  final TextEditingController customerAddressLine1Ctrl;
  final TextEditingController customerAddressLine2Ctrl;
  final TextEditingController customerAddressLine3Ctrl;
  final bool showCustomerAddressLine3;
  final VoidCallback onShowCustomerAddressLine3;

  final bool isShippingSameAsCustomer;
  final ValueChanged<bool> onToggleSameAddress;

  final TextEditingController shippingNameCtrl;
  final TextEditingController shippingPhoneCtrl;
  final TextEditingController shippingPhone2Ctrl;
  final bool showReceiverBackupPhone;
  final VoidCallback onToggleReceiverBackupPhone;
  final String? shippingProvinsi;
  final String? shippingKota;
  final String? shippingKecamatan;
  final String? shippingKelurahan;
  final String? shippingKodepos;
  final VoidCallback onPickShippingRegion;
  final TextEditingController shippingAddressLine1Ctrl;
  final TextEditingController shippingAddressLine2Ctrl;
  final TextEditingController shippingAddressLine3Ctrl;
  final bool showShippingAddressLine3;
  final VoidCallback onShowShippingAddressLine3;

  final bool isReceiverBranchMode;
  final ValueChanged<bool>? onToggleReceiverBranchMode;
  final List<StoreModel> availableStores;
  final StoreModel? selectedReceiverStore;
  final ValueChanged<StoreModel>? onReceiverStorePicked;
  final VoidCallback? onPickReceiverContact;
  final bool isFromReceiverContactBook;
  final VoidCallback? onRefreshStores;
  final bool isRefreshingStores;

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
            sectionTitle: customerSectionTitle,
            sectionSubtitle: customerSectionSubtitle,
            storeContactOptional: storeContactOptional,
            indirectStoreOnly: indirectStoreOnly,
            customerNameFieldLabel: customerNameFieldLabel,
            customerNameCtrl: customerNameCtrl,
            customerEmailCtrl: customerEmailCtrl,
            customerPhoneCtrl: customerPhoneCtrl,
            customerPhone2Ctrl: customerPhone2Ctrl,
            showBackupPhone: showBackupPhone,
            onToggleBackupPhone: onToggleBackupPhone,
            isFromContactBook: isFromContactBook,
            onContactFieldCleared: onContactFieldCleared,
            onPickContact: onPickContact,
          ),
          ShippingInfoSection(
            sectionTitle: shippingSectionTitle,
            sameAsCustomerLabel: sameAsCustomerLabel,
            receiverBlockTitle: receiverBlockTitle,
            useStoreAddressLabels: useStoreAddressLabels,
            hideCustomerRegionPicker: hideCustomerRegionPicker,
            receiverContactOptional: receiverContactOptional,
            showIndirectAlternateReceiverEmail:
                showIndirectAlternateReceiverEmail,
            shippingEmailCtrl: shippingEmailCtrl,
            customerProvinsi: customerProvinsi,
            customerKota: customerKota,
            customerKecamatan: customerKecamatan,
            customerKelurahan: customerKelurahan,
            customerKodepos: customerKodepos,
            onPickCustomerRegion: onPickCustomerRegion,
            customerAddressLine1Ctrl: customerAddressLine1Ctrl,
            customerAddressLine2Ctrl: customerAddressLine2Ctrl,
            customerAddressLine3Ctrl: customerAddressLine3Ctrl,
            showCustomerAddressLine3: showCustomerAddressLine3,
            onShowCustomerAddressLine3: onShowCustomerAddressLine3,
            isShippingSameAsCustomer: isShippingSameAsCustomer,
            onToggleSameAddress: onToggleSameAddress,
            shippingNameCtrl: shippingNameCtrl,
            shippingPhoneCtrl: shippingPhoneCtrl,
            shippingPhone2Ctrl: shippingPhone2Ctrl,
            showReceiverBackupPhone: showReceiverBackupPhone,
            onToggleReceiverBackupPhone: onToggleReceiverBackupPhone,
            shippingProvinsi: shippingProvinsi,
            shippingKota: shippingKota,
            shippingKecamatan: shippingKecamatan,
            shippingKelurahan: shippingKelurahan,
            shippingKodepos: shippingKodepos,
            onPickShippingRegion: onPickShippingRegion,
            shippingAddressLine1Ctrl: shippingAddressLine1Ctrl,
            shippingAddressLine2Ctrl: shippingAddressLine2Ctrl,
            shippingAddressLine3Ctrl: shippingAddressLine3Ctrl,
            showShippingAddressLine3: showShippingAddressLine3,
            onShowShippingAddressLine3: onShowShippingAddressLine3,
            isReceiverBranchMode: isReceiverBranchMode,
            onToggleReceiverBranchMode: onToggleReceiverBranchMode,
            availableStores: availableStores,
            selectedReceiverStore: selectedReceiverStore,
            onReceiverStorePicked: onReceiverStorePicked,
            onPickReceiverContact: onPickReceiverContact,
            isFromReceiverContactBook: isFromReceiverContactBook,
            onRefreshStores: onRefreshStores,
            isRefreshingStores: isRefreshingStores,
          ),
        ],
      ),
    );
  }
}
