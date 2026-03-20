import 'package:flutter/widgets.dart';

import '../data/models/payment_entry.dart';

/// Pure validation logic extracted from [CheckoutPage].
///
/// All methods are static and match the original validation behavior 1:1.
abstract final class CheckoutFormValidator {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w.-]+\.\w{2,}$');

  static bool isPhoneInvalid(String value) {
    if (value.trim().isEmpty) return true;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length < 10 || digits.length > 15;
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
    required bool isTakeAway,
    required DateTime? requestDate,
    required bool hasSelectedSpv,
    required bool requiresManager,
    required bool hasSelectedManager,
    required List<PaymentEntry> payments,
    required GlobalKey customerSectionKey,
    required GlobalKey deliverySectionKey,
    required GlobalKey approvalSectionKey,
    required GlobalKey paymentSectionKey,
  }) {
    if (customerName.trim().isEmpty ||
        customerEmail.trim().isEmpty ||
        !_emailRegex.hasMatch(customerEmail.trim()) ||
        isPhoneInvalid(customerPhone)) {
      return (key: customerSectionKey, label: 'Informasi Pelanggan');
    }
    if (customerAddress.trim().isEmpty) {
      return (key: customerSectionKey, label: 'Alamat Pelanggan');
    }
    if (!isShippingSameAsCustomer &&
        (shippingName.trim().isEmpty ||
            isPhoneInvalid(shippingPhone) ||
            shippingAddress.trim().isEmpty)) {
      return (key: customerSectionKey, label: 'Informasi Penerima');
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

    for (final p in payments) {
      if (p.method == null ||
          (p.method == 'Lainnya' && p.otherChannelCtrl.text.trim().isEmpty) ||
          (p.method != 'Lainnya' && p.bank == null) ||
          p.receiptImage == null) {
        return (key: paymentSectionKey, label: 'Informasi Pembayaran');
      }
    }

    return (key: customerSectionKey, label: 'Informasi Pelanggan');
  }
}
