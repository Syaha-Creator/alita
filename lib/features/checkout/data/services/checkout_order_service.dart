import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/services/api_client.dart';
import '../../../../core/utils/app_telemetry.dart';
import '../../../../core/utils/store_discount_calculator.dart';
import '../../../../core/utils/log.dart';
import '../../../cart/data/cart_item.dart';
import '../../../pricelist/data/models/item_lookup.dart';
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
        final List<dynamic> data = jsonDecode(response.body);
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
          final latest = data.first as Map<String, dynamic>;
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
        return data['result'] as Map<String, dynamic>?;
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
    final headerData = jsonDecode(response.body) as Map<String, dynamic>;
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
    String token,
  ) async {
    const endpoint = '/order_letter_contacts';
    for (int i = 0; i < contacts.length; i++) {
      final contact = contacts[i];
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

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['result'] as Map<String, dynamic>?;
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
  Future<void> postDiscountsForDetails({
    required List<SucceededDetail> succeededDetails,
    required int orderLetterId,
    required String token,
    List<int> fallbackDetailIds = const [],
  }) async {
    int totalDiscounts = 0;
    int succeededCount = 0;
    int failedCount = 0;

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
        failedCount += item.pending.discounts.length;
        continue;
      }

      for (final disc in item.pending.discounts) {
        totalDiscounts++;
        final levelId = disc['approver_level_id'] as int? ?? 0;
        final discPayload = Map<String, dynamic>.from(disc)
          ..['order_letter_id'] = orderLetterId
          ..['order_letter_detail_id'] = detailId;
        discPayload.removeWhere((_, v) => v == null);

        final response = await _api.post(
          CheckoutEndpoints.orderLetterDiscounts,
          token: token,
          body: discPayload,
          timeout: _checkoutTimeout,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          succeededCount++;
        } else {
          failedCount++;
          Log.warning(
            'Discount POST failed: level=$levelId detailId=$detailId '
            'status=${response.statusCode} body=${response.body}',
            tag: 'CheckoutOrderService',
          );
        }
      }
    }

    if (failedCount > 0) {
      throw CheckoutStepException(
        step: 5,
        stepName: 'Post Diskon',
        endpoint: CheckoutEndpoints.orderLetterDiscounts,
        statusCode: 0,
        message: '$failedCount dari $totalDiscounts diskon gagal diupload. '
            'Berhasil: $succeededCount.',
      );
    }
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
          ));
        }

        // Program Bulanan: level 80, auto-approved, hanya indirect.
        if (item.isIndirectSale && item.hasProgramBulanan) {
          final pbRow = CheckoutDiscountBuilder.buildProgramBulananRow(
            userId: userId,
            creatorName: creatorName,
            creatorTitle: creatorTitle,
            programBulananType: item.programBulananType,
            programBulananDiscount: item.programBulananDiscount,
            programBulananNominal: item.programBulananNominal,
          );
          if (pbRow != null) rows.add(pbRow);
        }

        return rows;
      }

      /// Baris utama (bukan bonus): FOC → hanya voucher 100%; selain itu rantai diskon biasa.
      /// [customerPricePerUnit] dipakai untuk menghitung nominal diskon per komponen.
      /// [componentProgramPrice] = plKomponen − eupKomponen (per-item, bukan total semua komponen).
      List<Map<String, dynamic>> discountRowsForDetailLine({
        double customerPricePerUnit = 0,
        double componentProgramPrice = 0,
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
      final markupDiff = p.price - presentEupSum;

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
        if (item.isFocVoucherActive) {
          kasurCustomerPerUnit = p.plKasur;
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
          'item_type': 'Mattress',
          if (lineTakeAwayTag() != null) 'take_away': lineTakeAwayTag(),
          if (plType.isNotEmpty) 'pricelist_type': plType,
          if (plArea.isNotEmpty) 'pricelist_area': plArea,
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: discountRowsForDetailLine(
            customerPricePerUnit: kasurCustomerPerUnit,
            componentProgramPrice: p.plKasur - p.eupKasur,
          ),
          label: '${p.name} (Kasur)',
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
        if (item.isFocVoucherActive) {
          divanCustomerPerUnit = p.plDivan;
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
        if (item.isFocVoucherActive) {
          hbCustomerPerUnit = p.plHeadboard;
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
        if (item.isFocVoucherActive) {
          srCustomerPerUnit = p.plSorong;
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
        if (item.isFocVoucherActive) {
          fbCustomerPerUnit = unitPlPerUnit;
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
          ),
          label: '${p.name} (Produk)',
        ));
      }

      // 6. BONUS
      // bonus.qty is per-unit; multiply by item.quantity for actual total.
      // unit_price / customer_price = PL bonus per unit; qty = segmen split.
      for (final bonus in item.bonusSnapshots) {
        final bonusEffQty = bonus.qty * item.quantity;
        final bonusPlPrice = BonusPriceResolver.resolvePlPrice(p, bonus.name);

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
