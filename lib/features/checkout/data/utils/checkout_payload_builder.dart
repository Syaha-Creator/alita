import '../../../../core/enums/order_status.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../cart/data/cart_item.dart';

/// Centralized payload builders for checkout feature.
class CheckoutPayloadBuilder {
  const CheckoutPayloadBuilder._();

  static Map<String, dynamic> buildHeaderPayload({
    required int? workPlaceId,
    required String customerAddress,
    required String? selectedKecamatan,
    required String? selectedKota,
    required String? selectedProvinsi,
    required bool isShippingSameAsCustomer,
    required String customerName,
    required String shippingName,
    required String shippingAddress,
    required String? shippingKecamatan,
    required String? shippingKota,
    required String? shippingProvinsi,
    required String postageText,
    required int creatorId,
    required List<Map<String, dynamic>> divisions,
    required List<CartItem> cartItems,
    required double grandTotal,
    required DateTime orderDate,
    required DateTime? requestDate,
    required String customerPhone,
    required String customerEmail,
    required String note,
    required String salesCode,
    required bool isTakeAway,

    /// Indirect: alamat toko cukup dari [customerAddress] (tanpa suffix EMSIFA).
    bool useCustomerAddressDetailOnly = false,
    /// Indirect: `no_po` di POST `/order_letters` — `null` jika [indirectNoPoText] kosong.
    bool isIndirectOrder = false,
    String indirectNoPoText = '',
  }) {
    final fullCustomerAddress = useCustomerAddressDetailOnly
        ? customerAddress.trim()
        : '${customerAddress.trim()}, Kec. $selectedKecamatan, $selectedKota, $selectedProvinsi';
    final shipToName =
        isShippingSameAsCustomer ? customerName.trim() : shippingName.trim();
    final addressShipTo = isShippingSameAsCustomer
        ? fullCustomerAddress
        : '${shippingAddress.trim()}, Kec. $shippingKecamatan, $shippingKota, $shippingProvinsi';
    final finalPostage = double.tryParse(
            ThousandsSeparatorInputFormatter.digitsOnly(postageText)) ??
        0.0;

    // Channel: S1 (divisionId=25) > S0 (divisionId=24) > MM (default)
    String channel = '';
    final hasMM = divisions.any((d) => d['id'] == 26);
    final hasS1 = divisions.any((d) => d['id'] == 25);
    final hasS0 = divisions.any((d) => d['id'] == 24);
    if (hasS1) {
      channel = 'S1';
    } else if (hasS0) {
      channel = 'SO';
    } else if (hasMM) {
      channel = 'MM';
    } else {
      channel = '';
    }

    // Harga awal = total harga PL semua komponen sebelum diskon.
    double hargaAwal = 0;
    for (final item in cartItems) {
      final p = item.product;
      double itemHarga = 0;
      if (item.kasurSku.isNotEmpty) itemHarga += p.plKasur * item.quantity;
      if (p.isSet) {
        if (item.divanSku.isNotEmpty &&
            !p.divan.toLowerCase().contains('tanpa')) {
          itemHarga += p.plDivan * item.quantity;
        }
        if (item.sandaranSku.isNotEmpty &&
            !p.headboard.toLowerCase().contains('tanpa')) {
          itemHarga += p.plHeadboard * item.quantity;
        }
        if (item.sorongSku.isNotEmpty &&
            !p.sorong.toLowerCase().contains('tanpa')) {
          itemHarga += p.plSorong * item.quantity;
        }
      }
      // Fallback: if no component contributed to harga_awal (e.g. standalone
      // divan/headboard products), use the product pricelist.
      if (itemHarga == 0 && p.price > 0) {
        itemHarga = (p.pricelist > 0 ? p.pricelist : p.price) * item.quantity;
      }
      hargaAwal += itemHarga;
    }
    final discountPercentage =
        hargaAwal > 0 ? ((hargaAwal - grandTotal) / hargaAwal) * 100 : 0.0;

    final noPoTrimmed = indirectNoPoText.trim();
    final noPoValue =
        isIndirectOrder ? (noPoTrimmed.isEmpty ? null : noPoTrimmed) : null;

    return {
      'order_date': AppFormatters.apiDate(orderDate),
      'request_date':
          requestDate != null ? AppFormatters.apiDate(requestDate) : null,
      'creator': creatorId,
      'customer_name': customerName.trim(),
      'phone': customerPhone.trim(),
      'email': customerEmail.trim(),
      'address': fullCustomerAddress,
      'ship_to_name': shipToName,
      'address_ship_to': addressShipTo,
      'extended_amount': grandTotal + finalPostage,
      'harga_awal': hargaAwal,
      'discount': discountPercentage,
      'note': note.trim(),
      'status': OrderStatus.pending.apiValue,
      'sales_code': salesCode.trim().isEmpty ? null : salesCode.trim(),
      'work_place_id': workPlaceId ?? 0,
      'take_away': isTakeAway ? 'TAKE AWAY' : null,
      'postage': finalPostage,
      'channel': channel,
      if (isIndirectOrder) 'no_po': noPoValue,
    };
  }

  static Map<String, dynamic> buildNewCustomerContactPayload({
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String customerAddress,
    required String regionText,
    String? selectedKecamatan,
    String? selectedKota,
    String? selectedProvinsi,
    String? customerPhone2,
  }) {
    final wilayah = regionText.trim().isNotEmpty
        ? regionText.trim()
        : [
            if ((selectedKecamatan ?? '').isNotEmpty) 'Kec. $selectedKecamatan',
            if ((selectedKota ?? '').isNotEmpty) selectedKota,
            if ((selectedProvinsi ?? '').isNotEmpty) selectedProvinsi,
          ].join(', ');

    final payload = <String, dynamic>{
      'name': customerName.trim(),
      'phone': customerPhone.trim(),
      'email': customerEmail.trim(),
      'wilayah': wilayah,
      'alamat_detail': customerAddress.trim(),
      'address': customerAddress.trim(),
      'provinsi': selectedProvinsi ?? '',
      'kota': selectedKota ?? '',
      'kecamatan': selectedKecamatan ?? '',
    };

    final phone2 = (customerPhone2 ?? '').trim();
    if (phone2.isNotEmpty) payload['phone2'] = phone2;
    return payload;
  }

  static List<Map<String, dynamic>> buildContactsPayload({
    required String primaryPhone,
    required bool includeBackupPhone,
    String? backupPhone,
  }) {
    final contacts = <Map<String, dynamic>>[];
    final primary = primaryPhone.trim();
    if (primary.isNotEmpty) {
      contacts.add({'phone': primary});
    }
    if (includeBackupPhone && (backupPhone ?? '').trim().isNotEmpty) {
      contacts.add({'phone': (backupPhone ?? '').trim()});
    }
    return contacts;
  }

  static Map<String, dynamic> buildPaymentPayload({
    required bool isLunas,
    required double totalAkhir,
    required String paymentAmountText,
    required String? paymentMethod,
    required String? paymentBank,
    required String otherChannelText,
    required String paymentRefText,
    required DateTime paymentDate,
    required String paymentNoteText,
    required int userId,
  }) {
    final finalPaymentAmount = isLunas
        ? totalAkhir
        : (double.tryParse(
              ThousandsSeparatorInputFormatter.digitsOnly(paymentAmountText),
            ) ??
            0.0);

    return {
      'payment_method':
          paymentMethod == 'Lainnya' ? 'other' : (paymentMethod ?? ''),
      'payment_bank': paymentMethod == 'Lainnya'
          ? otherChannelText.trim()
          : (paymentBank ?? ''),
      'payment_number': paymentRefText.trim(),
      'payment_amount': finalPaymentAmount,
      'payment_date': AppFormatters.apiDate(paymentDate),
      'note': paymentNoteText.trim(),
      'created_by': userId,
    };
  }

  /// Builds a single payment payload from a [PaymentEntry].
  static Map<String, dynamic> buildPaymentEntryPayload({
    required String amountText,
    required String? method,
    required String? bank,
    required String otherChannelText,
    required String refText,
    required DateTime date,
    required String noteText,
    required int userId,
  }) {
    final amount = double.tryParse(
          ThousandsSeparatorInputFormatter.digitsOnly(amountText),
        ) ??
        0.0;

    return {
      'payment_method': method == 'Lainnya' ? 'other' : (method ?? ''),
      'payment_bank':
          method == 'Lainnya' ? otherChannelText.trim() : (bank ?? ''),
      'payment_number': refText.trim(),
      'payment_amount': amount,
      'payment_date': AppFormatters.apiDate(date),
      'note': noteText.trim(),
      'created_by': userId,
    };
  }
}
