import 'package:flutter/widgets.dart';

import '../../../core/utils/order_letter_date_utils.dart';
import '../data/models/payment_entry.dart';

/// Pure validation logic extracted from [CheckoutPage].
///
/// All methods are static; behavior extended for indirect (optional payment block).
abstract final class CheckoutFormValidator {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w.-]+\.\w{2,}$');

  static bool isPhoneInvalid(String value) {
    if (value.trim().isEmpty) return true;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length < 10 || digits.length > 15;
  }

  /// True jika [value] terisi tapi format email tidak valid. Kosong = tidak error.
  static bool isFilledEmailInvalid(String value) {
    final t = value.trim();
    if (t.isEmpty) return false;
    return !_emailRegex.hasMatch(t);
  }

  /// True jika [value] terisi tapi digit HP di luar 10–15. Kosong = tidak error.
  static bool isFilledPhoneInvalid(String value) {
    final t = value.trim();
    if (t.isEmpty) return false;
    return isPhoneInvalid(t);
  }

  /// Returns the first section that contains an invalid field.
  static ({GlobalKey key, String label}) findFirstFormError({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String customerAddress,
    required bool isShippingSameAsCustomer,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    /// Indirect: email & no. HP toko opsional; hanya divalidasi jika diisi.
    bool indirectStoreContactOptional = false,
    /// Indirect: nama & no. HP penerima/gudang opsional; alamat & wilayah tetap dicek di luar.
    bool indirectReceiverContactOptional = false,
    required bool isTakeAway,
    required DateTime orderDate,
    required DateTime? requestDate,
    required bool hasSelectedSpv,
    required bool requiresManager,
    required bool hasSelectedManager,
    required List<PaymentEntry> payments,
    required GlobalKey customerSectionKey,
    required GlobalKey deliverySectionKey,
    required GlobalKey approvalSectionKey,
    required GlobalKey paymentSectionKey,
    String indirectAlternateReceiverEmail = '',
    /// Indirect: lewati cek metode/bank/bukti pembayaran (blok pembayaran disembunyikan).
    bool indirectSkipPaymentValidation = false,
  }) {
    final customerInfoLabel =
        indirectStoreContactOptional ? 'Informasi Toko' : 'Informasi Pelanggan';
    final customerAddressLabel =
        indirectStoreContactOptional ? 'Alamat Toko' : 'Alamat Pelanggan';

    if (customerName.trim().isEmpty) {
      return (key: customerSectionKey, label: customerInfoLabel);
    }

    if (!indirectStoreContactOptional) {
      if (customerEmail.trim().isEmpty ||
          !_emailRegex.hasMatch(customerEmail.trim()) ||
          isPhoneInvalid(customerPhone)) {
        return (key: customerSectionKey, label: customerInfoLabel);
      }
    }
    // Indirect: email/HP ada di blok kontak penerima, bukan di data toko.

    if (customerAddress.trim().isEmpty) {
      return (key: customerSectionKey, label: customerAddressLabel);
    }

    if (!isShippingSameAsCustomer) {
      if (indirectReceiverContactOptional) {
        if (shippingAddress.trim().isEmpty ||
            isFilledPhoneInvalid(shippingPhone)) {
          return (key: customerSectionKey, label: 'Informasi Penerima');
        }
        if (isFilledEmailInvalid(indirectAlternateReceiverEmail)) {
          return (key: customerSectionKey, label: 'Informasi Penerima');
        }
      } else if (shippingName.trim().isEmpty ||
          isPhoneInvalid(shippingPhone) ||
          shippingAddress.trim().isEmpty) {
        return (key: customerSectionKey, label: 'Informasi Penerima');
      }
    }

    if (!OrderLetterDateUtils.isValidOrderLetterDate(orderDate)) {
      return (key: deliverySectionKey, label: 'Informasi Pengiriman');
    }

    if (!isTakeAway && requestDate == null) {
      return (key: deliverySectionKey, label: 'Informasi Pengiriman');
    }

    if (!hasSelectedSpv) {
      return (key: approvalSectionKey, label: 'Persetujuan');
    }
    if (requiresManager && !hasSelectedManager) {
      return (key: approvalSectionKey, label: 'Persetujuan');
    }

    if (!indirectSkipPaymentValidation) {
      for (final p in payments) {
        if (p.method == null ||
            (p.method == 'Lainnya' && p.otherChannelCtrl.text.trim().isEmpty) ||
            (p.method != 'Lainnya' && p.bank == null) ||
            p.receiptImage == null) {
          return (key: paymentSectionKey, label: 'Informasi Pembayaran');
        }
      }
    }

    return (key: customerSectionKey, label: 'Informasi Pelanggan');
  }
}
