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
    /// `true` hanya jika **semua** baris checkout bawa sendiri (header API).
    /// Campur kirim + bawa → `false` (`take_away` header null; per detail tetap di payload).
    required bool headerAllLinesTakeAway,

    /// Indirect: alamat toko cukup dari [customerAddress] (tanpa suffix EMSIFA).
    bool useCustomerAddressDetailOnly = false,

    bool isIndirectOrder = false,
    /// No. PO: untuk indirect = no. PO toko, untuk direct = no. PO leasing.
    /// `null` jika kosong (tidak dikirim ke backend).
    String indirectNoPoText = '',
    /// Indirect: `address_number` toko untuk field `customer_master` di `/order_letters`.
    int? indirectCustomerMaster,

    /// Indirect: `address_number` toko untuk field `ship_to_code`.
    /// Diisi hanya saat pengiriman ke toko yang sama (bukan cabang/gudang,
    /// bukan customer baru) — nilainya sama dengan [indirectCustomerMaster].
    int? indirectShipToCode,

    /// Jika true, kirim `status: 'Approved'` langsung saat membuat order letter.
    ///
    /// Dipakai untuk indirect order tanpa Diskon Tambahan dan tanpa perubahan bonus —
    /// tidak ada row approval yang pending, sehingga backend tidak akan otomatis
    /// meng-update status ke Approved tanpa trigger dari approval flow.
    bool autoApprove = false,

    /// `address_number` milik user (bukan toko). Digunakan bersama divisions
    /// untuk menentukan channel: indirect division + punya address_number → SO;
    /// direct/indirect division + tidak punya address_number → S1.
    String? userAddressNumber,
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

    // Channel ditentukan berdasarkan division DAN kepemilikan address_number user:
    //   MM  → division id 26 (tidak berubah).
    //   S1  → division id 25 (direct) atau 24 (indirect), tapi user TIDAK punya address_number.
    //   SO  → division id 24 (indirect) DAN user punya address_number.
    String channel = '';
    final hasMM = divisions.any((d) => d['id'] == 26);
    final hasS1Division = divisions.any((d) => d['id'] == 25);
    final hasIndirectDivision = divisions.any((d) => d['id'] == 24);
    final trimmedAddr = userAddressNumber?.trim() ?? '';
    final userHasAddressNumber =
        trimmedAddr.isNotEmpty && trimmedAddr.toLowerCase() != 'null';

    if (hasIndirectDivision && userHasAddressNumber) {
      channel = 'SO';
    } else if (hasS1Division || hasIndirectDivision) {
      channel = 'S1';
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

    // `no_po` dikirim untuk indirect (no. PO toko) maupun direct (no. PO leasing).
    // Null bila kosong agar tidak menimpa nilai existing di backend.
    final noPoTrimmed = indirectNoPoText.trim();
    final noPoValue = noPoTrimmed.isEmpty ? null : noPoTrimmed;

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
      'status': autoApprove
          ? OrderStatus.approved.apiValue
          : OrderStatus.pending.apiValue,
      'sales_code': salesCode.trim().isEmpty ? null : salesCode.trim(),
      'work_place_id': workPlaceId ?? 0,
      'take_away': headerAllLinesTakeAway ? 'TAKE AWAY' : null,
      'postage': finalPostage,
      'channel': channel,
      if (noPoValue != null) 'no_po': noPoValue,
      if (isIndirectOrder && indirectCustomerMaster != null &&
          indirectCustomerMaster > 0)
        'customer_master': indirectCustomerMaster,
      if (isIndirectOrder && indirectShipToCode != null &&
          indirectShipToCode > 0)
        'ship_to_code': indirectShipToCode,
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

  /// Kontak untuk `POST /order_letter_contacts`.
  ///
  /// [ship] **false** = pemesan / pelanggan (direct).
  /// [ship] **true** = **penerima** pengiriman.
  ///
  /// **Indirect:** tidak ada input HP toko di app — hanya kirim kontak saat alamat beda
  /// (nomor **penerima** = customer / gudang, `ship: true`).
  static List<Map<String, dynamic>> buildOrderLetterContactsPayload({
    required bool isIndirectOrder,
    required bool isShippingSameAsCustomer,
    required String customerPrimaryPhone,
    required String customerBackupPhone,
    required bool includeCustomerBackupPhone,
    required String shippingPrimaryPhone,
    required String shippingBackupPhone,
    required bool includeShippingBackupPhone,
  }) {
    final out = <Map<String, dynamic>>[];

    void add(String raw, bool ship) {
      final p = raw.trim();
      if (p.isEmpty) return;
      out.add({'phone': p, 'ship': ship});
    }

    if (isIndirectOrder) {
      if (!isShippingSameAsCustomer) {
        add(shippingPrimaryPhone, true);
        if (includeShippingBackupPhone) {
          add(shippingBackupPhone, true);
        }
      }
      return out;
    }

    add(customerPrimaryPhone, false);
    if (includeCustomerBackupPhone) {
      add(customerBackupPhone, false);
    }
    if (!isShippingSameAsCustomer) {
      add(shippingPrimaryPhone, true);
      if (includeShippingBackupPhone) {
        add(shippingBackupPhone, true);
      }
    }
    return out;
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
