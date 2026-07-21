import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/services/api_client.dart';
import '../../../../core/utils/app_telemetry.dart';
import '../../../../core/utils/store_discount_calculator.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/safe_json_list.dart';
import '../../../cart/data/cart_item.dart';
import '../../../pricelist/data/models/item_lookup.dart';
import '../../../pricelist/data/models/pricelist_custom_line.dart';
import '../../../pricelist/logic/pricelist_custom_line_builder.dart';
import '../models/approver_model.dart';
import '../models/checkout_models.dart';
import '../utils/bonus_price_resolver.dart';
import '../utils/checkout_detail_builder_utils.dart';
import '../utils/checkout_discount_builder.dart';
import '../utils/checkout_net_price_calculator.dart';
import '../utils/order_letter_response_parser.dart';
import '../utils/take_away_splitter.dart';

/// Encapsulates all HTTP calls needed by the checkout flow.
class CheckoutOrderService {
  CheckoutOrderService({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  // ── Attendance ─────────────────────────────────────────────────

  /// Returns `work_place_id` from the user's **most recent** attendance.
  ///
  /// Only checks the latest entry — if it has `work_place_id: null`
  /// (WOH/WFH/Work Outside), returns null so the checkout flow can
  /// block submission and prompt the user to check in properly.
  Future<int?> getLatestWorkPlaceId(int userId, String token) async {
    final wp = await getLatestWorkPlace(userId, token);
    return wp?.$1;
  }

  /// Returns `(work_place_id, work_place_name)` from the user's most
  /// recent attendance, or `null` if unavailable / WOH/WFH.
  Future<(int, String)?> getLatestWorkPlace(int userId, String token) async {
    try {
      final response = await _api.get(
        CheckoutEndpoints.attendanceList,
        token: token,
        queryParams: {'user_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        final data = safeMapList(
          jsonDecode(response.body),
          fieldName: 'attendanceList',
        );
        if (data.isNotEmpty) {
          data.sort((a, b) {
            final dateA =
                DateTime.tryParse(a['attendance_in']?.toString() ?? '') ??
                    DateTime(2000);
            final dateB =
                DateTime.tryParse(b['attendance_in']?.toString() ?? '') ??
                    DateTime(2000);
            return dateB.compareTo(dateA);
          });
          final latest = data.first;
          final rawId = latest['work_place_id'];
          if (rawId == null) return null;
          final id = rawId is int ? rawId : int.tryParse(rawId.toString());
          if (id == null || id <= 0) return null;
          final name = latest['office_name']?.toString() ??
              latest['work_place_name']?.toString() ??
              latest['workplace_name']?.toString() ??
              '';
          return (id, name);
        }
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'CheckoutOrderService.getLatestWorkPlace');
    }
    return null;
  }

  // ── Leader by User ────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchLeaderByUser(
    int userId,
    String token,
  ) async {
    try {
      final response = await _api.get(
        CheckoutEndpoints.leaderByUser,
        token: token,
        queryParams: {'user_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map) {
          Log.warning(
            'fetchLeaderByUser: unexpected body shape ${data.runtimeType}',
            tag: 'CheckoutOrderService',
          );
          return null;
        }
        final result = data['result'];
        if (result == null) return null;
        if (result is! Map) {
          Log.warning(
            'fetchLeaderByUser: unexpected "result" shape ${result.runtimeType}',
            tag: 'CheckoutOrderService',
          );
          return null;
        }
        return Map<String, dynamic>.from(result);
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'CheckoutOrderService.fetchLeaderByUser');
    }
    return null;
  }

  // ── Step 1: Create Order Letter (Header) ──────────────────────

  static const _checkoutTimeout = Duration(seconds: 60);

  Future<CreateOrderResult> createOrderLetter(
    Map<String, dynamic> headerPayload,
    String token,
  ) async {
    const endpoint = '/order_letters';
    final response = await _api.post(
      CheckoutEndpoints.orderLetters,
      token: token,
      body: headerPayload,
      timeout: _checkoutTimeout,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CheckoutStepException(
        step: 1,
        stepName: 'Buat Header SP',
        endpoint: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
        payloadKeys: headerPayload.keys.toList(),
      );
    }
    final decodedHeader = jsonDecode(response.body);
    if (decodedHeader is! Map) {
      Log.error(
        StateError('createOrderLetter: unexpected body shape'),
        StackTrace.current,
        reason:
            'CheckoutOrderService.createOrderLetter got ${decodedHeader.runtimeType} instead of a Map',
      );
      throw CheckoutStepException(
        step: 1,
        stepName: 'Buat Header SP',
        endpoint: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
        message: 'Format response server tidak valid',
      );
    }
    final headerData = Map<String, dynamic>.from(decodedHeader);
    final parsed = OrderLetterResponseParser.parse(headerData);
    if (parsed.orderLetterId == 0) {
      throw CheckoutStepException(
        step: 1,
        stepName: 'Buat Header SP',
        endpoint: endpoint,
        statusCode: response.statusCode,
        responseBody: response.body,
        message: 'Server tidak mengembalikan order_letter_id',
      );
    }
    return CreateOrderResult(
      orderLetterId: parsed.orderLetterId,
      noSp: parsed.noSp,
    );
  }

  // ── Step 2: Post Contacts ─────────────────────────────────────

  Future<void> postContacts(
    List<Map<String, dynamic>> contacts,
    int orderLetterId,
    String token, {
    /// Index kontak pertama yang belum berhasil dikirim (untuk retry agar tidak
    /// duplikasi kontak yang sudah berhasil di attempt sebelumnya).
    int startIndex = 0,
    /// Dipanggil setelah tiap kontak berhasil, dengan index-nya — dipakai
    /// provider untuk update retryContactStartIndex secara incremental.
    void Function(int idx)? onContactPosted,
  }) async {
    const endpoint = '/order_letter_contacts';
    for (int i = startIndex; i < contacts.length; i++) {
      final contact = Map<String, dynamic>.from(contacts[i]);
      contact['order_letter_id'] = orderLetterId;
      final response = await _api.post(
        CheckoutEndpoints.orderLetterContacts,
        token: token,
        body: contact,
        timeout: _checkoutTimeout,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw CheckoutStepException(
          step: 2,
          stepName: 'Post Kontak #${i + 1}',
          endpoint: endpoint,
          statusCode: response.statusCode,
          responseBody: response.body,
          payloadKeys: contact.keys.toList(),
        );
      }
      onContactPosted?.call(i);
    }
  }

  // ── Step 3: Post Payment (multipart) ──────────────────────────

  Future<void> postPayment({
    required Map<String, dynamic> paymentPayload,
    required int orderLetterId,
    required File? receiptImage,
    required String token,
  }) async {
    final sw = Stopwatch()..start();
    final fields = <String, String>{
      'order_letter_payment[order_letter_id]': orderLetterId.toString(),
    };

    paymentPayload.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        fields['order_letter_payment[$key]'] = value.toString();
      }
    });

    final files = <http.MultipartFile>[];
    if (receiptImage != null) {
      if (!receiptImage.existsSync()) {
        Log.warning(
          'Receipt file missing: ${receiptImage.path}',
          tag: 'CheckoutOrderService',
        );
        throw Exception(
          'File bukti pembayaran tidak ditemukan. '
          'Silakan lampirkan ulang foto bukti pembayaran.',
        );
      }
      files.add(
        await http.MultipartFile.fromPath(
          'order_letter_payment[image]',
          receiptImage.path,
        ),
      );
    }

    final response = await _api.postMultipart(
      CheckoutEndpoints.orderLetterPayments,
      token: token,
      fields: fields,
      files: files,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      sw.stop();
      AppTelemetry.error(
        'checkout_payment_upload_failed',
        data: {
          'status_code': response.statusCode,
          'duration_ms': sw.elapsedMilliseconds,
          'has_receipt': receiptImage != null,
        },
        tag: 'CheckoutUpload',
      );
      throw CheckoutStepException(
        step: 3,
        stepName: 'Upload Pembayaran',
        endpoint: '/order_letter_payments',
        statusCode: response.statusCode,
        responseBody: response.body,
        payloadKeys: fields.keys.toList(),
      );
    }
    sw.stop();
    AppTelemetry.event(
      'checkout_payment_upload_ok',
      data: {
        'duration_ms': sw.elapsedMilliseconds,
        'has_receipt': receiptImage != null,
      },
      tag: 'CheckoutUpload',
    );
  }

  // ── Step 4: Post Details (one by one) ─────────────────────────

  /// Posts all pending detail rows one-by-one.
  ///
  /// Each successful POST captures the backend-returned
  /// `order_letter_detail_id` so discounts can target the exact row
  /// without ambiguity from duplicate `item_number`s.
  Future<({List<SucceededDetail> succeeded, List<PendingDetail> failed})>
      postDetails(
    List<PendingDetail> pendingDetails,
    int orderLetterId,
    String token, {
    required String noSp,
  }) async {
    final succeeded = <SucceededDetail>[];
    final failed = <PendingDetail>[];

    for (int i = 0; i < pendingDetails.length; i++) {
      final pending = pendingDetails[i];
      final detailPayload = Map<String, dynamic>.from(pending.payload)
        ..['order_letter_id'] = orderLetterId
        ..['no_sp'] = noSp;

      try {
        final response = await _api.post(
          CheckoutEndpoints.orderLetterDetails,
          token: token,
          body: detailPayload,
          timeout: _checkoutTimeout,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final detailId = _extractDetailId(response.body);
          if (detailId > 0) {
            succeeded.add(SucceededDetail(pending: pending, detailId: detailId));
          } else {
            succeeded.add(SucceededDetail(pending: pending, detailId: 0));
          }
        } else {
          Log.warning(
            'Detail POST failed: ${pending.label} status=${response.statusCode}',
            tag: 'CheckoutOrderService',
          );
          failed.add(pending);
        }
      } catch (e, st) {
        // Network/timeout exception: anggap item ini gagal agar retryDetails
        // tetap terisi dan submit button tetap disabled, mencegah re-POST semua
        // detail ulang dari awal saat user tap submit kembali.
        Log.warning(
          'Detail POST exception: ${pending.label} — $e',
          tag: 'CheckoutOrderService',
        );
        Log.error(e, st, reason: 'CheckoutOrderService.postDetails item $i');
        failed.add(pending);
        // Item setelah ini juga belum dipost — masukkan semua ke failed.
        for (int j = i + 1; j < pendingDetails.length; j++) {
          failed.add(pendingDetails[j]);
        }
        break;
      }
    }

    return (succeeded: succeeded, failed: failed);
  }

  /// Try multiple paths to extract the detail_id from the POST response.
  static int _extractDetailId(String responseBody) {
    try {
      final body = jsonDecode(responseBody);
      if (body is Map<String, dynamic>) {
        // result.order_letter_detail_id
        final result = body['result'];
        if (result is Map<String, dynamic>) {
          final id = (result['order_letter_detail_id'] as num?)?.toInt() ??
              (result['id'] as num?)?.toInt() ??
              0;
          if (id > 0) return id;
        }
        // top-level id
        final topId = (body['order_letter_detail_id'] as num?)?.toInt() ??
            (body['id'] as num?)?.toInt() ??
            0;
        if (topId > 0) return topId;
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'CheckoutOrderService._extractDetailId');
    }
    return 0;
  }

  // ── EUP Markup / Discount resolver ──────────────────────────

  /// Resolves EUP per unit + **total baris** setelah diskon sales (belum indirect).
  ///
  /// API `order_letter_details` mengharapkan **`customer_price` dan `net_price`
  /// per unit**; total baris = nilai itu × [qty] di payload.
  ///
  /// [inputPrice] = user-configured EUP (from `product.eup*`).
  /// [originalEup] = catalog EUP before user discount (from `originalEup*`
  ///   field on CartItem, with cascading fallback to masterProduct/product).
  ///
  /// - **Markup** (inputPrice > originalEup): basis customer per unit = inputPrice.
  /// - **Discount** (inputPrice <= originalEup): basis customer per unit = originalEup.
  ///
  /// [netPriceLineTotal] = basis × qty lalu diskon sales bertingkat (internal).
  static ({double customerPricePerUnit, double netPriceLineTotal})
      _resolveComponentPrices({
    required double inputPrice,
    required double originalEup,
    required int qty,
    required double discount1,
    required double discount2,
    required double discount3,
    required double discount4,
  }) {
    final double customerPricePerUnit;
    if (inputPrice > originalEup) {
      customerPricePerUnit = inputPrice;
    } else {
      customerPricePerUnit = originalEup;
    }

    final netPriceLineTotal = CheckoutNetPriceCalculator.calculate(
      customerPrice: customerPricePerUnit,
      qty: qty,
      discount1: discount1,
      discount2: discount2,
      discount3: discount3,
      discount4: discount4,
    );

    return (
      customerPricePerUnit: customerPricePerUnit,
      netPriceLineTotal: netPriceLineTotal,
    );
  }

  /// Konversi total baris (setelah diskon sales + indirect toko) → **per unit**
  /// untuk field API `net_price`.
  static double _apiNetPricePerUnit(double netLineTotal, int qty) {
    if (qty <= 0) return double.parse(netLineTotal.toStringAsFixed(2));
    return double.parse((netLineTotal / qty).toStringAsFixed(2));
  }

  /// Menghitung nominal (Rp) per-baris untuk setiap diskon toko (indirect).
  ///
  /// **Urutan cascade indirect** (sesuai `cart_item.effectiveUnitSellingPrice`):
  ///   `customer → store1 → store2 → ... → d1 → d2 → d3 → d4`
  ///
  /// Jadi diskon toko di-apply ke `customer_price` langsung (tanpa prior sales
  /// discounts), cascading antar sesama store:
  ///   base_i = customerPerUnit × qty × Π_{k<i}(1 - storeDisc_k/100)
  ///   nominal_i = base_i × (storeDisc_i / 100)
  static List<double> _storeDiscountNominalLines({
    required double customerPricePerUnit,
    required int qty,
    required List<double> storeDiscounts,
  }) {
    if (customerPricePerUnit <= 0 || qty <= 0 || storeDiscounts.isEmpty) {
      return List<double>.filled(storeDiscounts.length, 0);
    }
    double base = customerPricePerUnit * qty;
    final result = <double>[];
    for (final sd in storeDiscounts) {
      final sc = sd.clamp(0.0, 100.0);
      if (sc <= 0) {
        result.add(0);
        continue;
      }
      final nominal = base * sc / 100;
      result.add(double.parse(nominal.toStringAsFixed(2)));
      base *= (1 - sc / 100);
    }
    return result;
  }

  /// Menghitung nominal (Rp) dari satu tingkat diskon setelah cascade prior discounts.
  ///
  /// Rumus: `customerPerUnit × qty × ∏(1 - priorDiscount_i/100) × (targetDiscount/100)`.
  ///
  /// **Priors untuk direct** (urutan cascade: customer → d1 → d2 → d3 → d4):
  ///   d1: `[]`, d2: `[d1]`, d3: `[d1, d2]`, d4: `[d1, d2, d3]`
  ///
  /// **Priors untuk indirect** (urutan: customer → store... → d1..d4):
  ///   d1: `[...stores]`, d2: `[...stores, d1]`, d3: `[...stores, d1, d2]`,
  ///   d4: `[...stores, d1, d2, d3]`
  static double _discountNominalLine({
    required double customerPricePerUnit,
    required int qty,
    required double targetDiscount,
    List<double> priorDiscounts = const [],
  }) {
    if (targetDiscount <= 0 || customerPricePerUnit <= 0 || qty <= 0) return 0;
    double base = customerPricePerUnit * qty;
    for (final d in priorDiscounts) {
      final dc = d.clamp(0.0, 100.0);
      if (dc > 0) base *= (1 - dc / 100);
    }
    final target = targetDiscount.clamp(0.0, 100.0);
    return double.parse((base * target / 100).toStringAsFixed(2));
  }

  /// Indirect: [customer_price] mengikuti direct (EUP + logika markup/original).
  /// Diskon toko diterapkan pada **net per unit setelah diskon sales** (bukan pada PL).
  static double _netLineAfterIndirectStoreDiscounts({
    required bool isIndirectLine,
    required int qty,
    required List<double> storeDiscounts,
    required double netLineAfterSalesDiscounts,
  }) {
    if (!isIndirectLine || qty <= 0) {
      return netLineAfterSalesDiscounts;
    }
    final perUnitNet = netLineAfterSalesDiscounts / qty;
    final lineNet =
        StoreDiscountCalculator.cascade(perUnitNet, storeDiscounts) * qty;
    return double.parse(lineNet.toStringAsFixed(2));
  }

  /// Pick the best available original EUP with cascading fallback:
  /// 1. CartItem.originalEup* (explicit, always correct for the selected variant)
  /// 2. masterProduct.eup* (original catalog entry, may be wrong variant)
  /// 3. product.eup* (user-modified, last resort)
  static double _pickOriginalEup(
    double stored,
    double? fromMaster,
    double fromProduct,
  ) {
    if (stored > 0) return stored;
    if (fromMaster != null && fromMaster > 0) return fromMaster;
    return fromProduct;
  }

  // ── Step 5: Fetch order → map index → detail_id (FALLBACK) ───

  /// Fetches the full order data (header + details + discounts).
  /// Used for detail-ID fallback and post-checkout notification trigger.
  Future<Map<String, dynamic>?> fetchFullOrder(
    int orderLetterId,
    String token,
  ) async {
    final response = await _api.get(
      '${CheckoutEndpoints.orderLetters}/$orderLetterId',
      token: token,
    );

    if (response.statusCode != 200) {
      Log.warning(
        'GET order failed (${response.statusCode})',
        tag: 'CheckoutOrderService',
      );
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      Log.warning(
        'fetchFullOrder: unexpected body shape ${decoded.runtimeType}',
        tag: 'CheckoutOrderService',
      );
      return null;
    }
    final result = decoded['result'];
    if (result == null) return null;
    if (result is! Map) {
      Log.warning(
        'fetchFullOrder: unexpected "result" shape ${result.runtimeType}',
        tag: 'CheckoutOrderService',
      );
      return null;
    }
    return Map<String, dynamic>.from(result);
  }

  /// Hitung jumlah `order_letter_contacts` yang sudah ada di server.
  /// Dipakai setelah error di step 2 untuk menghindari duplikasi kontak.
  Future<int> fetchExistingContactCount(
    int orderLetterId,
    String token,
  ) async {
    try {
      final orderData = await fetchFullOrder(orderLetterId, token);
      if (orderData == null) return 0;
      final contacts =
          orderData['order_letter_contacts'] as List<dynamic>? ?? [];
      return contacts.length;
    } catch (e, st) {
      Log.warning(
        'fetchExistingContactCount gagal: $e',
        tag: 'CheckoutOrderService',
      );
      Log.error(e, st, reason: 'fetchExistingContactCount');
      return 0;
    }
  }

  /// Hitung jumlah `order_letter_payments` yang sudah ada di server.
  /// Dipakai setelah error di step 3 untuk menghindari double-payment:
  /// jika server sempat menyimpan payment sebelum timeout, count-nya > 0
  /// sehingga retry tahu harus mulai dari index berapa.
  /// Mengembalikan 0 jika fetch gagal (safe fallback — retry tetap bisa jalan).
  Future<int> fetchExistingPaymentCount(
    int orderLetterId,
    String token,
  ) async {
    try {
      final orderData = await fetchFullOrder(orderLetterId, token);
      if (orderData == null) return 0;
      final payments =
          orderData['order_letter_payments'] as List<dynamic>? ?? [];
      return payments.length;
    } catch (e, st) {
      Log.warning(
        'fetchExistingPaymentCount gagal: $e',
        tag: 'CheckoutOrderService',
      );
      Log.error(e, st, reason: 'fetchExistingPaymentCount');
      return 0;
    }
  }

  /// Fetches all detail IDs for an order. Used as fallback when the
  /// individual POST responses didn't include the detail ID.
  ///
  /// Returns a list ordered by backend insertion (same order as POST).
  Future<List<int>> fetchDetailIds(
    int orderLetterId,
    String token,
  ) async {
    final orderData = await fetchFullOrder(orderLetterId, token);
    if (orderData == null) return [];

    final rawDetails = orderData['order_letter_details'] as List? ?? [];

    final sorted = List<Map<String, dynamic>>.from(
      rawDetails.whereType<Map<String, dynamic>>(),
    )..sort((a, b) {
        final idA = (a['order_letter_detail_id'] as num?)?.toInt() ?? 0;
        final idB = (b['order_letter_detail_id'] as num?)?.toInt() ?? 0;
        return idA.compareTo(idB);
      });

    return sorted
        .map((d) => (d['order_letter_detail_id'] as num?)?.toInt() ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  // ── Step 5b: Post Discounts ───────────────────────────────────

  /// Posts discounts for each succeeded detail, using the exact
  /// `detailId` captured from the POST response.
  ///
  /// If any detailId is 0 (extraction failed), uses [fallbackDetailIds]
  /// matched by positional index as a last resort.
  /// Returns details with at least one failed discount row; does not throw.
  Future<List<SucceededDetail>> postDiscountsForDetails({
    required List<SucceededDetail> succeededDetails,
    required int orderLetterId,
    required String token,
    List<int> fallbackDetailIds = const [],
  }) async {
    int totalDiscounts = 0;
    int succeededCount = 0;

    final failedDetailsList = <SucceededDetail>[];

    for (int i = 0; i < succeededDetails.length; i++) {
      final item = succeededDetails[i];
      if (item.pending.discounts.isEmpty) continue;

      int detailId = item.detailId;

      if (detailId <= 0 && i < fallbackDetailIds.length) {
        detailId = fallbackDetailIds[i];
      }

      if (detailId <= 0) {
        Log.warning(
          'Skipped ${item.pending.discounts.length} discounts for '
          '"${item.pending.label}" — detailId=0',
          tag: 'CheckoutOrderService',
        );
        failedDetailsList.add(item);
        continue;
      }

      bool detailHadFailure = false;
      // Kumulatif level_id yang berhasil di-POST untuk detail ini (termasuk dari
      // percobaan sebelumnya yang tersimpan di postedDiscountLevelIds).
      final succeededLevelIds = <int>{...item.postedDiscountLevelIds};

      for (final disc in item.pending.discounts) {
        final levelId = disc['approver_level_id'] as int? ?? 0;

        // Skip baris yang sudah ada di server dari percobaan sebelumnya.
        if (levelId > 0 && succeededLevelIds.contains(levelId)) {
          succeededCount++;
          totalDiscounts++;
          continue;
        }

        totalDiscounts++;
        final discPayload = Map<String, dynamic>.from(disc)
          ..['order_letter_id'] = orderLetterId
          ..['order_letter_detail_id'] = detailId;
        discPayload.removeWhere((_, v) => v == null);

        try {
          final response = await _api.post(
            CheckoutEndpoints.orderLetterDiscounts,
            token: token,
            body: discPayload,
            timeout: _checkoutTimeout,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            succeededCount++;
            if (levelId > 0) succeededLevelIds.add(levelId);
          } else {
            detailHadFailure = true;
            Log.warning(
              'Discount POST failed: level=$levelId detailId=$detailId '
              'status=${response.statusCode} body=${response.body}',
              tag: 'CheckoutOrderService',
            );
          }
        } catch (e, st) {
          detailHadFailure = true;
          Log.warning(
            'Discount POST exception: level=$levelId detailId=$detailId — $e',
            tag: 'CheckoutOrderService',
          );
          Log.error(e, st, reason: 'CheckoutOrderService.postDiscountsForDetails');
        }
      }

      if (detailHadFailure) {
        // Simpan level_id yang sudah berhasil agar retry berikutnya bisa skip.
        failedDetailsList.add(item.withPostedLevelIds(succeededLevelIds));
      }
    }

    final failedCount = totalDiscounts - succeededCount;
    if (failedCount > 0) {
      Log.warning(
        'postDiscountsForDetails: $failedCount dari $totalDiscounts diskon gagal. '
        '${failedDetailsList.length} detail akan di-retry.',
        tag: 'CheckoutOrderService',
      );
    }

    return failedDetailsList;
  }

  // ── Build pending details from cart ───────────────────────────

  List<PendingDetail> buildPendingDetails({
    required List<CartItem> cartItems,
    required int userId,
    required Map<String, dynamic>? leaderData,
    required Map<String, ItemLookup> lookupByItemNum,
    required Approver? selectedSpv,
    required Approver? selectedManager,
    required bool Function(int itemIndex) lineIsTakeAway,
    required bool Function(int itemIndex, CartBonusSnapshot)
        isBonusTakeAwayChecked,
    required int Function(int itemIndex, CartBonusSnapshot) currentTakeAwayQty,
    required String profileName,
  }) {
    final pending = <PendingDetail>[];

    final userLeader = leaderData?['user'] as Map<String, dynamic>?;
    final String creatorName =
        userLeader?['full_name'] as String? ?? profileName;
    final String creatorTitle = userLeader?['work_title'] as String? ?? '';

    final analystData = leaderData?['analyst'] as Map<String, dynamic>?;
    final int? analystId = (analystData?['id'] as num?)?.toInt();
    final String analystName = analystData?['full_name'] as String? ?? '';
    final String analystTitle = analystData?['work_title'] as String? ?? '';

    for (var itemIndex = 0; itemIndex < cartItems.length; itemIndex++) {
      final item = cartItems[itemIndex];
      final p = item.product;

      String? lineTakeAwayTag([bool segmentTakeAway = false]) =>
          (lineIsTakeAway(itemIndex) || segmentTakeAway) ? 'TAKE AWAY' : null;
      final master = item.masterProduct;
      final String brand = p.brand.isNotEmpty ? p.brand : 'Unknown Brand';
      final String ukuran = p.ukuran;
      final String itemDesc = p.name;
      final String plType = p.channel.trim();
      final String plArea = item.pricelistArea.trim();

      String appendSizeIfMissing(String baseName, String size) {
        final trimmedBase = baseName.trim();
        final trimmedSize = size.trim();
        if (trimmedBase.isEmpty ||
            trimmedSize.isEmpty ||
            trimmedSize.toLowerCase() == 'bonus') {
          return trimmedBase;
        }
        if (trimmedBase.toLowerCase().contains(trimmedSize.toLowerCase())) {
          return trimmedBase;
        }
        return '$trimmedBase $trimmedSize';
      }

      String cleanDesc1(String originalName, String sizeOrDesc2) {
        if (originalName.isEmpty ||
            sizeOrDesc2.isEmpty ||
            sizeOrDesc2.toLowerCase() == 'bonus') {
          return originalName.trim();
        }
        var cleaned = originalName.replaceAll(sizeOrDesc2, '').trim();
        if (cleaned.endsWith('-')) {
          cleaned = cleaned.substring(0, cleaned.length - 1).trim();
        }
        if (cleaned.endsWith(',')) {
          cleaned = cleaned.substring(0, cleaned.length - 1).trim();
        }
        return cleaned;
      }

      bool hasComponent(String value) {
        final lower = value.trim().toLowerCase();
        return lower.isNotEmpty && !lower.contains('tanpa');
      }

      // ── Program Bulanan (indirect only): setup sekali per item ──
      // Baris audit (approver_level_id 80) hanya ditempel ke SATU komponen
      // "anchor" (prioritas sama dengan markupDiff di bawah: kasur > divan >
      // headboard > sorong > fallback Produk) agar tidak terduplikasi ke
      // setiap baris detail pada produk SET. Potongan net_price riil tetap
      // diterapkan ke semua komponen relevan: proporsional untuk tipe
      // persen (matematis setara dengan memotong di agregat), atau nilai
      // penuh hanya ke komponen anchor untuk tipe nominal.
      final bool kcPresentForPb = hasComponent(p.kasur);
      final bool dvPresentForPb = p.isSet && hasComponent(p.divan);
      final bool hbPresentForPb = p.isSet && hasComponent(p.headboard);
      final bool srPresentForPb = p.isSet && hasComponent(p.sorong);
      final double presentEupSumForPb = (kcPresentForPb ? p.eupKasur : 0) +
          (dvPresentForPb ? p.eupDivan : 0) +
          (hbPresentForPb ? p.eupHeadboard : 0) +
          (srPresentForPb ? p.eupSorong : 0);
      final bool pbActive = item.isIndirectSale && item.hasProgramBulanan;
      final bool pbIsPercent = item.programBulananType == 'percent';
      final double pbPercent = item.programBulananDiscount;
      final double pbNominal = item.programBulananNominal;
      final bool pbAnchorIsKasur = pbActive && kcPresentForPb;
      final bool pbAnchorIsDivan = pbActive && !kcPresentForPb && dvPresentForPb;
      final bool pbAnchorIsHeadboard = pbActive &&
          !kcPresentForPb &&
          !dvPresentForPb &&
          hbPresentForPb;
      final bool pbAnchorIsSorong = pbActive &&
          !kcPresentForPb &&
          !dvPresentForPb &&
          !hbPresentForPb &&
          srPresentForPb;
      final bool pbAnchorIsFallback = pbActive &&
          !kcPresentForPb &&
          !dvPresentForPb &&
          !hbPresentForPb &&
          !srPresentForPb;
      // Estimasi Rp untuk audit (`discount_price`):
      // - persen: estimasi dari basis EUP × qty × %
      // - nominal: nilai input **per unit** × qty (potongan line total)
      final int pbQty = item.quantity < 1 ? 1 : item.quantity;
      final double pbNominalLineTotal = pbNominal * pbQty;
      final double pbDiscountPriceRp = !pbActive
          ? 0
          : pbIsPercent
              ? presentEupSumForPb * pbQty * (pbPercent / 100)
              : pbNominalLineTotal;

      /// Menerapkan potongan Program Bulanan ke net line SATU komponen.
      /// [isAnchor] menandai komponen yang boleh menyerap potongan nominal
      /// PENUH (line total = nominal/unit × qty) — mencegah nominal terpotong
      /// berkali-kali di tiap baris SET.
      double applyProgramBulananToNetLine(double netLine, bool isAnchor) {
        if (!pbActive || netLine <= 0) return netLine;
        if (pbIsPercent) {
          return (netLine * (1 - pbPercent / 100)).clamp(0, double.infinity);
        }
        if (!isAnchor) return netLine;
        return (netLine - pbNominalLineTotal).clamp(0, double.infinity);
      }

      List<Map<String, dynamic>> buildDiscounts({
        double? discount1NominalLine,
        double? discount2NominalLine,
        double? discount3NominalLine,
        double? discount4NominalLine,
        List<double>? storeDiscountNominals,
      }) {
        final base = CheckoutDiscountBuilder.build(
          userId: userId,
          creatorName: creatorName,
          creatorTitle: creatorTitle,
          selectedSpv: selectedSpv,
          selectedManager: selectedManager,
          analystId: analystId,
          analystName: analystName,
          analystTitle: analystTitle,
          discount1: item.discount1,
          discount2: item.discount2,
          discount3: item.discount3,
          discount4: item.discount4,
          isIndirectOrder: item.isIndirectSale,
          isBonusCustomized: item.isBonusCustomized,
          discount1NominalLine: discount1NominalLine,
          discount2NominalLine: discount2NominalLine,
          discount3NominalLine: discount3NominalLine,
          discount4NominalLine: discount4NominalLine,
        );
        final rows = <Map<String, dynamic>>[...base];

        if (item.isIndirectSale &&
            item.indirectStoreDiscounts.isNotEmpty &&
            item.indirectStoreAlphaName.isNotEmpty) {
          rows.addAll(CheckoutDiscountBuilder.buildStoreDiscountRows(
            storeDiscounts: item.indirectStoreDiscounts,
            storeAlphaName: item.indirectStoreAlphaName,
            storeDiscountNominals: storeDiscountNominals,
            codeStandart: item.indirectStoreDiscountCode.isNotEmpty
                ? item.indirectStoreDiscountCode
                : null,
          ));
        }

        return rows;
      }

      /// Baris utama (bukan bonus): FOC → hanya voucher 100%; selain itu rantai diskon biasa.
      /// [customerPricePerUnit] dipakai untuk menghitung nominal diskon per komponen.
      /// [componentProgramPrice] = plKomponen − eupKomponen (per-item, bukan total semua komponen).
      List<Map<String, dynamic>> discountRowsForDetailLine({
        double customerPricePerUnit = 0,
        double componentProgramPrice = 0,
        bool isProgramBulananAnchor = false,
      }) {
        final List<Map<String, dynamic>> rows;
        if (item.isFocVoucherActive) {
          final spv = selectedSpv;
          if (spv == null) {
            throw StateError(
              item.isIndirectSale
                  ? 'Baris FOC membutuhkan ASM yang dipilih (validasi checkout harus memastikan ini).'
                  : 'Baris FOC membutuhkan SPV yang dipilih (validasi checkout harus memastikan ini).',
            );
          }
          rows = CheckoutDiscountBuilder.buildFocVoucherRow(selectedSpv: spv);
        } else {
          final d1 = item.discount1;
          final d2 = item.discount2;
          final d3 = item.discount3;
          final d4 = item.discount4;
          final cpu = customerPricePerUnit;
          final qty = item.quantity;

          // Nominal per level dihitung untuk direct & indirect (dipakai sebagai
          // nilai `discount_price` di semua baris, dan `discount_extra_price`
          // di baris Manager/Analyst).
          //
          // Urutan cascade:
          //   Direct  : customer → d1 → d2 → d3 → d4
          //   Indirect: customer → store1 → ... → storeN → d1 → d2 → d3 → d4
          // Jadi untuk indirect, semua diskon toko jadi prior di kalkulasi d1..d4.
          final storePriors = item.isIndirectSale
              ? List<double>.unmodifiable(item.indirectStoreDiscounts)
              : const <double>[];
          final d1Nominal = _discountNominalLine(
            customerPricePerUnit: cpu,
            qty: qty,
            targetDiscount: d1,
            priorDiscounts: [...storePriors],
          );
          final d2Nominal = _discountNominalLine(
            customerPricePerUnit: cpu,
            qty: qty,
            targetDiscount: d2,
            priorDiscounts: [...storePriors, d1],
          );
          final d3Nominal = _discountNominalLine(
            customerPricePerUnit: cpu,
            qty: qty,
            targetDiscount: d3,
            priorDiscounts: [...storePriors, d1, d2],
          );
          final d4Nominal = _discountNominalLine(
            customerPricePerUnit: cpu,
            qty: qty,
            targetDiscount: d4,
            priorDiscounts: [...storePriors, d1, d2, d3],
          );
          final storeNominals = item.isIndirectSale
              ? _storeDiscountNominalLines(
                  customerPricePerUnit: cpu,
                  qty: qty,
                  storeDiscounts: item.indirectStoreDiscounts,
                )
              : null;

          rows = buildDiscounts(
            discount1NominalLine: d1Nominal > 0 ? d1Nominal : null,
            discount2NominalLine: d2Nominal > 0 ? d2Nominal : null,
            discount3NominalLine: d3Nominal > 0 ? d3Nominal : null,
            discount4NominalLine: d4Nominal > 0 ? d4Nominal : null,
            storeDiscountNominals: storeNominals,
          );
        }

        // Program Bulanan: level 80, auto-approved, hanya indirect. Hanya
        // ditempel ke komponen anchor (lihat setup di atas) agar baris
        // audit ini tidak terduplikasi ke setiap komponen produk SET.
        // Tidak berlaku untuk baris FOC (net_price sudah 0).
        if (!item.isFocVoucherActive && isProgramBulananAnchor && pbActive) {
          final pbRow = CheckoutDiscountBuilder.buildProgramBulananRow(
            userId: userId,
            creatorName: creatorName,
            creatorTitle: creatorTitle,
            programBulananType: item.programBulananType,
            programBulananDiscount: item.programBulananDiscount,
            programBulananNominal: item.programBulananNominal,
            discountPriceRp: pbDiscountPriceRp,
          );
          if (pbRow != null) rows.add(pbRow);
        }

        final program = p.program.trim();
        final hasProgram = program.isNotEmpty && program != '-';
        return rows
            .map((row) => <String, dynamic>{
                  ...row,
                  if (hasProgram) 'discount_program': program,
                  if (hasProgram && componentProgramPrice != 0)
                    'discount_program_price': componentProgramPrice,
                })
            .toList();
      }

      final isIndirectLine =
          item.isIndirectSale && item.indirectStoreDiscounts.isNotEmpty;

      // ── Effective EUP per component ──
      // When the user edits the total price upward, the markup might be
      // stored on the wrong component (e.g. eupKasur for a headboard-only
      // product). Recalculate effective EUPs from p.price to ensure the
      // markup always reaches the correct (present) component.
      final bool kcPresent = hasComponent(p.kasur);
      final bool dvPresent = p.isSet && hasComponent(p.divan);
      final bool hbPresent = p.isSet && hasComponent(p.headboard);
      final bool srPresent = p.isSet && hasComponent(p.sorong);

      double effEupKasur = kcPresent ? p.eupKasur : 0;
      double effEupDivan = dvPresent ? p.eupDivan : 0;
      double effEupHeadboard = hbPresent ? p.eupHeadboard : 0;
      double effEupSorong = srPresent ? p.eupSorong : 0;

      final presentEupSum =
          effEupKasur + effEupDivan + effEupHeadboard + effEupSorong;
      // Markup / edit total sudah terserap di `eup*` via CartItemBuilder.
      // Jangan ikutkan `product.price` saat Program Bulanan aktif: price sering
      // masih snapshot tampilan post-PB, sehingga delta = −PB lalu
      // `applyProgramBulananToNetLine` memotong PB sekali lagi (double cut).
      final markupDiff = pbActive ? 0.0 : (p.price - presentEupSum);

      if (markupDiff.abs() > 0.01) {
        if (kcPresent) {
          effEupKasur += markupDiff;
        } else if (dvPresent) {
          effEupDivan += markupDiff;
        } else if (hbPresent) {
          effEupHeadboard += markupDiff;
        } else if (srPresent) {
          effEupSorong += markupDiff;
        }
      }

      bool componentPosted = false;

      // 1. Mattress(KASUR)
      if (kcPresent) {
        final baseKasurName = appendSizeIfMissing(itemDesc, ukuran);
        CheckoutDetailBuilderUtils.validateRequiredField(
            'desc_1 (nama produk)', p.name);
        CheckoutDetailBuilderUtils.validateRequiredField(
            'desc_2 (ukuran)', ukuran);
        CheckoutDetailBuilderUtils.validateRequiredField('brand', brand);
        CheckoutDetailBuilderUtils.validateRequiredField(
            'unit_price kasur', p.plKasur);
        CheckoutDetailBuilderUtils.validateRequiredField('qty', item.quantity);

        final origKasur = _pickOriginalEup(
          item.originalEupKasur,
          master?.eupKasur,
          p.eupKasur,
        );
        final kasurPrices = _resolveComponentPrices(
          inputPrice: effEupKasur,
          originalEup: origKasur,
          qty: item.quantity,
          discount1: item.discount1,
          discount2: item.discount2,
          discount3: item.discount3,
          discount4: item.discount4,
        );
        var kasurCustomerPerUnit = kasurPrices.customerPricePerUnit;
        var kasurNetLine = _netLineAfterIndirectStoreDiscounts(
          isIndirectLine: isIndirectLine,
          qty: item.quantity,
          storeDiscounts: item.indirectStoreDiscounts,
          netLineAfterSalesDiscounts: kasurPrices.netPriceLineTotal,
        );
        kasurNetLine = applyProgramBulananToNetLine(kasurNetLine, pbAnchorIsKasur);
        if (item.isFocVoucherActive) {
          kasurCustomerPerUnit = p.plKasur;
          kasurNetLine = 0;
        } else if (item.isZeroPrice) {
          // customer_price = EUP (setelah prog. discount) sebagai referensi harga asli.
          kasurCustomerPerUnit = p.eupKasur > 0 ? p.eupKasur : p.plKasur;
          kasurNetLine = 0;
        }
        final payload = {
          'item_number':
              CheckoutDetailBuilderUtils.normalizeNullableSku(item.kasurSku),
          'item_description': CheckoutDetailBuilderUtils.buildDescription(
            baseDesc: baseKasurName,
            sku: item.kasurSku,
            lookupByItemNum: lookupByItemNum,
          ),
          'desc_1': cleanDesc1(p.name, ukuran),
          'desc_2': ukuran,
          'brand': brand,
          'unit_price': p.plKasur,
          'customer_price': kasurCustomerPerUnit,
          'net_price': _apiNetPricePerUnit(kasurNetLine, item.quantity),
          'qty': item.quantity,
          'item_type': p.isPricelistCustomCartLine
              ? (PricelistCustomLineBuilder.componentTypeFromProduct(p)
                      ?.apiItemType ??
                  'Mattress')
              : 'Mattress',
          if (lineTakeAwayTag() != null) 'take_away': lineTakeAwayTag(),
          if (plType.isNotEmpty) 'pricelist_type': plType,
          if (plArea.isNotEmpty) 'pricelist_area': plArea,
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: discountRowsForDetailLine(
            customerPricePerUnit: kasurCustomerPerUnit,
            componentProgramPrice: p.plKasur - p.eupKasur,
            isProgramBulananAnchor: pbAnchorIsKasur,
          ),
          label:
              '${p.name} (${p.isPricelistCustomCartLine ? (PricelistCustomLineBuilder.componentTypeFromProduct(p)?.shortLabel ?? 'Kasur') : 'Kasur'})',
        ));
        componentPosted = true;
      }

      // 2. DIVAN
      if (dvPresent) {
        CheckoutDetailBuilderUtils.validateRequiredField(
            'desc_1 (divan)', p.divan);

        final origDivan = _pickOriginalEup(
          item.originalEupDivan,
          master?.eupDivan,
          p.eupDivan,
        );
        final divanPrices = _resolveComponentPrices(
          inputPrice: effEupDivan,
          originalEup: origDivan,
          qty: item.quantity,
          discount1: item.discount1,
          discount2: item.discount2,
          discount3: item.discount3,
          discount4: item.discount4,
        );
        var divanCustomerPerUnit = divanPrices.customerPricePerUnit;
        var divanNetLine = _netLineAfterIndirectStoreDiscounts(
          isIndirectLine: isIndirectLine,
          qty: item.quantity,
          storeDiscounts: item.indirectStoreDiscounts,
          netLineAfterSalesDiscounts: divanPrices.netPriceLineTotal,
        );
        divanNetLine = applyProgramBulananToNetLine(divanNetLine, pbAnchorIsDivan);
        if (item.isFocVoucherActive) {
          divanCustomerPerUnit = p.plDivan;
          divanNetLine = 0;
        } else if (item.isZeroPrice) {
          divanCustomerPerUnit = p.eupDivan > 0 ? p.eupDivan : p.plDivan;
          divanNetLine = 0;
        }
        final payload = {
          'item_number':
              CheckoutDetailBuilderUtils.normalizeNullableSku(item.divanSku),
          'item_description': CheckoutDetailBuilderUtils.buildDescription(
            baseDesc: appendSizeIfMissing(p.divan, ukuran),
            sku: item.divanSku,
            lookupByItemNum: lookupByItemNum,
            storedKain: item.divanKain,
            storedWarna: item.divanWarna,
          ),
          'desc_1': cleanDesc1(p.divan, ukuran),
          'desc_2': ukuran,
          'brand': brand,
          'unit_price': p.plDivan,
          'customer_price': divanCustomerPerUnit,
          'net_price': _apiNetPricePerUnit(divanNetLine, item.quantity),
          'qty': item.quantity,
          'item_type': 'Divan',
          if (lineTakeAwayTag() != null) 'take_away': lineTakeAwayTag(),
          if (plType.isNotEmpty) 'pricelist_type': plType,
          if (plArea.isNotEmpty) 'pricelist_area': plArea,
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: p.eupDivan > 0
              ? discountRowsForDetailLine(
                  customerPricePerUnit: divanCustomerPerUnit,
                  componentProgramPrice: p.plDivan - p.eupDivan,
                  isProgramBulananAnchor: pbAnchorIsDivan,
                )
              : const [],
          label: '${p.name} (Divan)',
        ));
        componentPosted = true;
      }

      // 3. HEADBOARD
      if (hbPresent) {
        CheckoutDetailBuilderUtils.validateRequiredField(
            'desc_1 (headboard)', p.headboard);

        final origHb = _pickOriginalEup(
          item.originalEupHeadboard,
          master?.eupHeadboard,
          p.eupHeadboard,
        );
        final headboardPrices = _resolveComponentPrices(
          inputPrice: effEupHeadboard,
          originalEup: origHb,
          qty: item.quantity,
          discount1: item.discount1,
          discount2: item.discount2,
          discount3: item.discount3,
          discount4: item.discount4,
        );
        var hbCustomerPerUnit = headboardPrices.customerPricePerUnit;
        var hbNetLine = _netLineAfterIndirectStoreDiscounts(
          isIndirectLine: isIndirectLine,
          qty: item.quantity,
          storeDiscounts: item.indirectStoreDiscounts,
          netLineAfterSalesDiscounts: headboardPrices.netPriceLineTotal,
        );
        hbNetLine = applyProgramBulananToNetLine(hbNetLine, pbAnchorIsHeadboard);
        if (item.isFocVoucherActive) {
          hbCustomerPerUnit = p.plHeadboard;
          hbNetLine = 0;
        } else if (item.isZeroPrice) {
          hbCustomerPerUnit = p.eupHeadboard > 0 ? p.eupHeadboard : p.plHeadboard;
          hbNetLine = 0;
        }
        final payload = {
          'item_number':
              CheckoutDetailBuilderUtils.normalizeNullableSku(item.sandaranSku),
          'item_description': CheckoutDetailBuilderUtils.buildDescription(
            baseDesc: appendSizeIfMissing(p.headboard, ukuran),
            sku: item.sandaranSku,
            lookupByItemNum: lookupByItemNum,
            storedKain: item.sandaranKain,
            storedWarna: item.sandaranWarna,
          ),
          'desc_1': cleanDesc1(p.headboard, ukuran),
          'desc_2': ukuran,
          'brand': brand,
          'unit_price': p.plHeadboard,
          'customer_price': hbCustomerPerUnit,
          'net_price': _apiNetPricePerUnit(hbNetLine, item.quantity),
          'qty': item.quantity,
          'item_type': 'Headboard',
          if (lineTakeAwayTag() != null) 'take_away': lineTakeAwayTag(),
          if (plType.isNotEmpty) 'pricelist_type': plType,
          if (plArea.isNotEmpty) 'pricelist_area': plArea,
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: p.eupHeadboard > 0
              ? discountRowsForDetailLine(
                  customerPricePerUnit: hbCustomerPerUnit,
                  componentProgramPrice: p.plHeadboard - p.eupHeadboard,
                  isProgramBulananAnchor: pbAnchorIsHeadboard,
                )
              : const [],
          label: '${p.name} (Headboard)',
        ));
        componentPosted = true;
      }

      // 4. SORONG
      if (srPresent) {
        CheckoutDetailBuilderUtils.validateRequiredField(
            'desc_1 (sorong)', p.sorong);

        final origSorong = _pickOriginalEup(
          item.originalEupSorong,
          master?.eupSorong,
          p.eupSorong,
        );
        final sorongPrices = _resolveComponentPrices(
          inputPrice: effEupSorong,
          originalEup: origSorong,
          qty: item.quantity,
          discount1: item.discount1,
          discount2: item.discount2,
          discount3: item.discount3,
          discount4: item.discount4,
        );
        var srCustomerPerUnit = sorongPrices.customerPricePerUnit;
        var srNetLine = _netLineAfterIndirectStoreDiscounts(
          isIndirectLine: isIndirectLine,
          qty: item.quantity,
          storeDiscounts: item.indirectStoreDiscounts,
          netLineAfterSalesDiscounts: sorongPrices.netPriceLineTotal,
        );
        srNetLine = applyProgramBulananToNetLine(srNetLine, pbAnchorIsSorong);
        if (item.isFocVoucherActive) {
          srCustomerPerUnit = p.plSorong;
          srNetLine = 0;
        } else if (item.isZeroPrice) {
          srCustomerPerUnit = p.eupSorong > 0 ? p.eupSorong : p.plSorong;
          srNetLine = 0;
        }
        final payload = {
          'item_number':
              CheckoutDetailBuilderUtils.normalizeNullableSku(item.sorongSku),
          'item_description': CheckoutDetailBuilderUtils.buildDescription(
            baseDesc: appendSizeIfMissing(p.sorong, ukuran),
            sku: item.sorongSku,
            lookupByItemNum: lookupByItemNum,
            storedKain: item.sorongKain,
            storedWarna: item.sorongWarna,
          ),
          'desc_1': cleanDesc1(p.sorong, ukuran),
          'desc_2': ukuran,
          'brand': brand,
          'unit_price': p.plSorong,
          'customer_price': srCustomerPerUnit,
          'net_price': _apiNetPricePerUnit(srNetLine, item.quantity),
          'qty': item.quantity,
          'item_type': 'Sorong',
          if (lineTakeAwayTag() != null) 'take_away': lineTakeAwayTag(),
          if (plType.isNotEmpty) 'pricelist_type': plType,
          if (plArea.isNotEmpty) 'pricelist_area': plArea,
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: p.eupSorong > 0
              ? discountRowsForDetailLine(
                  customerPricePerUnit: srCustomerPerUnit,
                  componentProgramPrice: p.plSorong - p.eupSorong,
                  isProgramBulananAnchor: pbAnchorIsSorong,
                )
              : const [],
          label: '${p.name} (Sorong)',
        ));
        componentPosted = true;
      }

      // 5. Fallback: if no component was posted, post the product itself
      //    (e.g. "Tanpa Kasur" divan-only or headboard-only products).
      if (!componentPosted && p.price > 0) {
        final fallbackName = appendSizeIfMissing(itemDesc, ukuran);
        final origKasur = _pickOriginalEup(
          item.originalEupKasur,
          master?.eupKasur,
          p.eupKasur,
        );
        final effectiveOriginal = origKasur > 0 ? origKasur : p.price;
        final prices = _resolveComponentPrices(
          inputPrice: p.price,
          originalEup: effectiveOriginal,
          qty: item.quantity,
          discount1: item.discount1,
          discount2: item.discount2,
          discount3: item.discount3,
          discount4: item.discount4,
        );
        final unitPlPerUnit = p.pricelist > 0 ? p.pricelist : p.price;
        var fbCustomerPerUnit = prices.customerPricePerUnit;
        var fbNetLine = _netLineAfterIndirectStoreDiscounts(
          isIndirectLine: isIndirectLine,
          qty: item.quantity,
          storeDiscounts: item.indirectStoreDiscounts,
          netLineAfterSalesDiscounts: prices.netPriceLineTotal,
        );
        fbNetLine = applyProgramBulananToNetLine(fbNetLine, pbAnchorIsFallback);
        if (item.isFocVoucherActive) {
          fbCustomerPerUnit = unitPlPerUnit;
          fbNetLine = 0;
        } else if (item.isZeroPrice) {
          // Fallback path: gunakan eupKasur sebagai customer_price referensi harga EUP.
          final eupRef = p.eupKasur > 0 ? p.eupKasur : unitPlPerUnit;
          fbCustomerPerUnit = eupRef;
          fbNetLine = 0;
        }
        final fallbackSku = item.kasurSku.isNotEmpty
            ? item.kasurSku
            : (item.divanSku.isNotEmpty
                ? item.divanSku
                : (item.sandaranSku.isNotEmpty
                    ? item.sandaranSku
                    : item.sorongSku));
        final payload = {
          'item_number':
              CheckoutDetailBuilderUtils.normalizeNullableSku(fallbackSku),
          'item_description': fallbackName,
          'desc_1': cleanDesc1(p.name, ukuran),
          'desc_2': ukuran,
          'brand': brand,
          'unit_price': unitPlPerUnit,
          'customer_price': fbCustomerPerUnit,
          'net_price': _apiNetPricePerUnit(fbNetLine, item.quantity),
          'qty': item.quantity,
          'item_type': 'Mattress',
          if (lineTakeAwayTag() != null) 'take_away': lineTakeAwayTag(),
          if (plType.isNotEmpty) 'pricelist_type': plType,
          if (plArea.isNotEmpty) 'pricelist_area': plArea,
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: discountRowsForDetailLine(
            customerPricePerUnit: fbCustomerPerUnit,
            componentProgramPrice: unitPlPerUnit - p.price,
            isProgramBulananAnchor: pbAnchorIsFallback,
          ),
          label: '${p.name} (Produk)',
        ));
      }

      // 6. BONUS
      // bonus.qty is per-unit; multiply by item.quantity for actual total.
      // unit_price / customer_price = PL bonus per unit; qty = segmen split.
      for (final bonus in item.bonusSnapshots) {
        final bonusEffQty = bonus.qty * item.quantity;
        final resolvedPl = BonusPriceResolver.resolvePlPrice(p, bonus.name);
        final bonusPlPrice = resolvedPl > 0 ? resolvedPl : bonus.plPrice;

        final int configuredTakeAway = lineIsTakeAway(itemIndex)
            ? bonusEffQty
            : currentTakeAwayQty(itemIndex, bonus);

        final splitSegments = TakeAwaySplitter.split(
          totalQty: bonusEffQty,
          takeAwayQty: configuredTakeAway,
        );

        for (final segment in splitSegments) {
          // Bonus: net_price selalu 0; customer_price = PL bonus per unit (API).
          final bonusNet = CheckoutNetPriceCalculator.calculate(
            customerPrice: bonusPlPrice,
            qty: segment.qty,
            discount1: item.discount1,
            discount2: item.discount2,
            discount3: item.discount3,
            discount4: item.discount4,
            isBonus: true,
          );
          final payload = {
            'item_number':
                CheckoutDetailBuilderUtils.normalizeNullableSku(bonus.sku),
            'item_description':
                CheckoutDetailBuilderUtils.buildCleanItemDescription(
              bonus.name,
            ),
            'desc_1': bonus.name,
            'desc_2': 'Bonus',
            'brand': brand,
            'unit_price': bonusPlPrice,
            'customer_price': bonusPlPrice,
            'net_price': bonusNet,
            'qty': segment.qty,
            'item_type': 'Bonus',
            'notes': segment.note,
            if (lineTakeAwayTag(segment.isTakeAway) != null)
              'take_away': lineTakeAwayTag(segment.isTakeAway),
            if (plType.isNotEmpty) 'pricelist_type': plType,
            if (plArea.isNotEmpty) 'pricelist_area': plArea,
          };
          pending.add(PendingDetail(
            payload: payload,
            discounts: const [],
            label: '${bonus.name} (Bonus - ${segment.note})',
          ));
        }
      }
    }
    return pending;
  }
}
