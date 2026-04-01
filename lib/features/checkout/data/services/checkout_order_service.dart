import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/services/api_client.dart';
import '../../../../core/utils/app_telemetry.dart';
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
  Future<(int, String)?> getLatestWorkPlace(
      int userId, String token) async {
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

  /// Resolves the correct `customer_price` and `net_price` for a component.
  ///
  /// [inputPrice] = user-configured EUP (from `product.eup*`).
  /// [originalEup] = catalog EUP before user discount (from `originalEup*`
  ///   field on CartItem, with cascading fallback to masterProduct/product).
  ///
  /// - **Markup** (inputPrice > originalEup): customer_price = inputPrice,
  ///   net_price = calculated from inputPrice with cascading discounts.
  /// - **Discount** (inputPrice <= originalEup): customer_price = originalEup,
  ///   net_price = calculated from originalEup with cascading discounts.
  static ({double customerPrice, double netPrice}) _resolveComponentPrices({
    required double inputPrice,
    required double originalEup,
    required int qty,
    required double discount1,
    required double discount2,
    required double discount3,
    required double discount4,
  }) {
    final double customerPrice;
    if (inputPrice > originalEup) {
      customerPrice = inputPrice;
    } else {
      customerPrice = originalEup;
    }

    final netPrice = CheckoutNetPriceCalculator.calculate(
      customerPrice: customerPrice,
      qty: qty,
      discount1: discount1,
      discount2: discount2,
      discount3: discount3,
      discount4: discount4,
    );

    return (customerPrice: customerPrice * qty, netPrice: netPrice);
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

    final rawDetails =
        orderData['order_letter_details'] as List? ?? [];

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
    required bool globalIsTakeAway,
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

    String? getTakeAway([bool itemTakeAway = false]) =>
        (globalIsTakeAway || itemTakeAway) ? 'TAKE AWAY' : null;

    for (var itemIndex = 0; itemIndex < cartItems.length; itemIndex++) {
      final item = cartItems[itemIndex];
      final p = item.product;
      final master = item.masterProduct;
      final String brand = p.brand.isNotEmpty ? p.brand : 'Unknown Brand';
      final String ukuran = p.ukuran;
      final String itemDesc = p.name;

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

      List<Map<String, dynamic>> buildDiscounts() =>
          CheckoutDiscountBuilder.build(
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
          );

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
          'unit_price': p.plKasur * item.quantity,
          'customer_price': kasurPrices.customerPrice,
          'net_price': kasurPrices.netPrice,
          'qty': item.quantity,
          'item_type': 'Mattress',
          if (getTakeAway() != null) 'take_away': getTakeAway(),
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: buildDiscounts(),
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
        final payload = {
          'item_number':
              CheckoutDetailBuilderUtils.normalizeNullableSku(item.divanSku),
          'item_description': CheckoutDetailBuilderUtils.buildDescription(
            baseDesc: p.divan,
            sku: item.divanSku,
            lookupByItemNum: lookupByItemNum,
            storedKain: item.divanKain,
            storedWarna: item.divanWarna,
          ),
          'desc_1': cleanDesc1(p.divan, ukuran),
          'desc_2': ukuran,
          'brand': brand,
          'unit_price': p.plDivan * item.quantity,
          'customer_price': divanPrices.customerPrice,
          'net_price': divanPrices.netPrice,
          'qty': item.quantity,
          'item_type': 'Divan',
          if (getTakeAway() != null) 'take_away': getTakeAway(),
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: p.eupDivan > 0 ? buildDiscounts() : const [],
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
        final payload = {
          'item_number':
              CheckoutDetailBuilderUtils.normalizeNullableSku(item.sandaranSku),
          'item_description': CheckoutDetailBuilderUtils.buildDescription(
            baseDesc: p.headboard,
            sku: item.sandaranSku,
            lookupByItemNum: lookupByItemNum,
            storedKain: item.sandaranKain,
            storedWarna: item.sandaranWarna,
          ),
          'desc_1': cleanDesc1(p.headboard, ukuran),
          'desc_2': ukuran,
          'brand': brand,
          'unit_price': p.plHeadboard * item.quantity,
          'customer_price': headboardPrices.customerPrice,
          'net_price': headboardPrices.netPrice,
          'qty': item.quantity,
          'item_type': 'Headboard',
          if (getTakeAway() != null) 'take_away': getTakeAway(),
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: p.eupHeadboard > 0 ? buildDiscounts() : const [],
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
        final payload = {
          'item_number':
              CheckoutDetailBuilderUtils.normalizeNullableSku(item.sorongSku),
          'item_description': CheckoutDetailBuilderUtils.buildDescription(
            baseDesc: p.sorong,
            sku: item.sorongSku,
            lookupByItemNum: lookupByItemNum,
            storedKain: item.sorongKain,
            storedWarna: item.sorongWarna,
          ),
          'desc_1': cleanDesc1(p.sorong, ukuran),
          'desc_2': ukuran,
          'brand': brand,
          'unit_price': p.plSorong * item.quantity,
          'customer_price': sorongPrices.customerPrice,
          'net_price': sorongPrices.netPrice,
          'qty': item.quantity,
          'item_type': 'Sorong',
          if (getTakeAway() != null) 'take_away': getTakeAway(),
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: p.eupSorong > 0 ? buildDiscounts() : const [],
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
          'unit_price': p.pricelist > 0
              ? p.pricelist * item.quantity
              : p.price * item.quantity,
          'customer_price': prices.customerPrice,
          'net_price': prices.netPrice,
          'qty': item.quantity,
          'item_type': 'Mattress',
          if (getTakeAway() != null) 'take_away': getTakeAway(),
        };
        pending.add(PendingDetail(
          payload: payload,
          discounts: buildDiscounts(),
          label: '${p.name} (Produk)',
        ));
      }

      // 6. BONUS
      // bonus.qty is per-unit; multiply by item.quantity for actual total.
      // unit_price & customer_price follow the same pattern as main items:
      //   pricelist_per_unit × row_qty  (e.g. p.plKasur * item.quantity).
      for (final bonus in item.bonusSnapshots) {
        final bonusEffQty = bonus.qty * item.quantity;
        final bonusPlPrice = BonusPriceResolver.resolvePlPrice(p, bonus.name);

        final int configuredTakeAway = globalIsTakeAway
            ? bonusEffQty
            : currentTakeAwayQty(itemIndex, bonus);

        final splitSegments = TakeAwaySplitter.split(
          totalQty: bonusEffQty,
          takeAwayQty: configuredTakeAway,
        );

        for (final segment in splitSegments) {
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
            'unit_price': bonusPlPrice * segment.qty,
            'customer_price': bonusPlPrice * segment.qty,
            'net_price': CheckoutNetPriceCalculator.calculate(
              customerPrice: bonusPlPrice,
              qty: segment.qty,
              discount1: item.discount1,
              discount2: item.discount2,
              discount3: item.discount3,
              discount4: item.discount4,
              isBonus: true,
            ),
            'qty': segment.qty,
            'item_type': 'Bonus',
            'notes': segment.note,
            if (getTakeAway(segment.isTakeAway) != null)
              'take_away': getTakeAway(segment.isTakeAway),
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
