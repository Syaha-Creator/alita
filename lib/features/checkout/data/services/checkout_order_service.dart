import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/services/api_client.dart';
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

  Future<int?> getLatestWorkPlaceId(int userId, String token) async {
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
          final raw = data.first['work_place_id'];
          return raw is int ? raw : int.tryParse(raw?.toString() ?? '');
        }
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'CheckoutOrderService.getLatestWorkPlaceId');
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

  Future<CreateOrderResult> createOrderLetter(
    Map<String, dynamic> headerPayload,
    String token,
  ) async {
    final response = await _api.post(
      CheckoutEndpoints.orderLetters,
      token: token,
      body: headerPayload,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Gagal membuat Surat Pesanan. '
        '(Status: ${response.statusCode})\n${response.body}',
      );
    }
    final headerData = jsonDecode(response.body) as Map<String, dynamic>;
    final parsed = OrderLetterResponseParser.parse(headerData);
    if (parsed.orderLetterId == 0) {
      throw Exception(
        'Gagal membaca ID Surat Pesanan dari server.\n'
        'Response: ${response.body}',
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
    for (final contact in contacts) {
      contact['order_letter_id'] = orderLetterId;
      await _api.post(
        CheckoutEndpoints.orderLetterContacts,
        token: token,
        body: contact,
      );
    }
  }

  // ── Step 3: Post Payment (multipart) ──────────────────────────

  Future<void> postPayment({
    required Map<String, dynamic> paymentPayload,
    required int orderLetterId,
    required File? receiptImage,
    required String token,
  }) async {
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
      throw Exception(
        'Gagal mengupload bukti pembayaran.\n'
        'Status: ${response.statusCode}\nResponse: ${response.body}',
      );
    }
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
    } catch (_) {}
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

  /// Fetches all detail IDs for an order. Used as fallback when the
  /// individual POST responses didn't include the detail ID.
  ///
  /// Returns a list ordered by backend insertion (same order as POST).
  Future<List<int>> fetchDetailIds(
    int orderLetterId,
    String token,
  ) async {
    final response = await _api.get(
      '${CheckoutEndpoints.orderLetters}/$orderLetterId',
      token: token,
    );

    if (response.statusCode != 200) {
      Log.warning(
        'GET order failed (${response.statusCode}), fallback unavailable',
        tag: 'CheckoutOrderService',
      );
      return [];
    }

    final orderBody = jsonDecode(response.body) as Map<String, dynamic>;
    final rawDetails =
        orderBody['result']?['order_letter_details'] as List? ?? [];

    // Sort by detail ID (ascending) = insertion order
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
    for (int i = 0; i < succeededDetails.length; i++) {
      final item = succeededDetails[i];
      if (item.pending.discounts.isEmpty) continue;

      int detailId = item.detailId;

      if (detailId <= 0 && i < fallbackDetailIds.length) {
        detailId = fallbackDetailIds[i];
      }

      if (detailId <= 0) continue;

      for (final disc in item.pending.discounts) {
        final levelId = disc['approver_level_id'] as int? ?? 0;
        final discPayload = Map<String, dynamic>.from(disc)
          ..['order_letter_id'] = orderLetterId
          ..['order_letter_detail_id'] = detailId;
        discPayload.removeWhere((_, v) => v == null);

        final response = await _api.post(
          CheckoutEndpoints.orderLetterDiscounts,
          token: token,
          body: discPayload,
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          Log.warning(
            'Discount POST failed: level=$levelId detailId=$detailId '
            'status=${response.statusCode}',
            tag: 'CheckoutOrderService',
          );
        }
      }
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

      // 1. MATTRESS (KASUR)
      if (hasComponent(p.kasur)) {
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
          inputPrice: p.eupKasur,
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
      }

      // 2. DIVAN
      if (p.isSet && hasComponent(p.divan)) {
        CheckoutDetailBuilderUtils.validateRequiredField(
            'desc_1 (divan)', p.divan);

        final origDivan = _pickOriginalEup(
          item.originalEupDivan,
          master?.eupDivan,
          p.eupDivan,
        );
        final divanPrices = _resolveComponentPrices(
          inputPrice: p.eupDivan,
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
      }

      // 3. HEADBOARD
      if (p.isSet && hasComponent(p.headboard)) {
        CheckoutDetailBuilderUtils.validateRequiredField(
            'desc_1 (headboard)', p.headboard);

        final origHb = _pickOriginalEup(
          item.originalEupHeadboard,
          master?.eupHeadboard,
          p.eupHeadboard,
        );
        final headboardPrices = _resolveComponentPrices(
          inputPrice: p.eupHeadboard,
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
      }

      // 4. SORONG
      if (p.isSet && hasComponent(p.sorong)) {
        CheckoutDetailBuilderUtils.validateRequiredField(
            'desc_1 (sorong)', p.sorong);

        final origSorong = _pickOriginalEup(
          item.originalEupSorong,
          master?.eupSorong,
          p.eupSorong,
        );
        final sorongPrices = _resolveComponentPrices(
          inputPrice: p.eupSorong,
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
      }

      // 5. BONUS
      final totalBonusQty =
          item.bonusSnapshots.fold<int>(0, (sum, b) => sum + b.qty);

      for (final bonus in item.bonusSnapshots) {
        final bonusPlPrice = BonusPriceResolver.resolvePlPrice(p, bonus.name);
        final int totalQty = item.quantity + totalBonusQty;
        final double adjustedUnitPrice = (totalQty > 0 && item.quantity > 0)
            ? bonusPlPrice * item.quantity / totalQty
            : bonusPlPrice;

        final int configuredTakeAway =
            globalIsTakeAway ? bonus.qty : currentTakeAwayQty(itemIndex, bonus);

        final splitSegments = TakeAwaySplitter.split(
          totalQty: bonus.qty,
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
            'unit_price': adjustedUnitPrice * segment.qty,
            'customer_price': adjustedUnitPrice * segment.qty,
            'net_price': CheckoutNetPriceCalculator.calculate(
              customerPrice: adjustedUnitPrice,
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
