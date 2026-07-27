// Tests for CheckoutOrderService.buildPendingDetails — verifies the exact
// per-component detail payload (item_type, unit_price, qty, brand, etc.)
// that is sent to /order_letter_details for every cart item.
//
// These are payload-contract tests for the ORCHESTRATION layer.
// They complement the builder-level tests (checkout_payload_builder_test,
// checkout_discount_builder_test) by ensuring the service correctly routes
// each CartItem component into the right PendingDetail rows.
//
// Safe to run without network: buildPendingDetails is pure computation.

import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/checkout/data/models/checkout_models.dart';
import 'package:alitapricelist/features/checkout/data/services/checkout_order_service.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/core/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fakes ──────────────────────────────────────────────────────────────────

// buildPendingDetails never calls _api, so a Fake is sufficient.
class _FakeApiClient extends Fake implements ApiClient {}

// ─── Helpers ────────────────────────────────────────────────────────────────

Product _product({
  String id = 'P1',
  String name = 'Spring Bed Foam X 160',
  String brand = 'Brand ABC',
  String kasur = 'Foam X',
  String divan = 'Tanpa Divan',
  String headboard = 'Tanpa Headboard',
  String sorong = 'Tanpa Sorong',
  String ukuran = '160',
  bool isSet = false,
  double price = 1_000_000,
  double pricelist = 0,
  double eupKasur = 900_000,
  double eupDivan = 0,
  double eupHeadboard = 0,
  double eupSorong = 0,
  double plKasur = 1_000_000,
  double plDivan = 0,
  double plHeadboard = 0,
  double plSorong = 0,
  String channel = '',
}) =>
    Product(
      id: id,
      name: name,
      price: price,
      imageUrl: '',
      category: 'Kasur',
      brand: brand,
      kasur: kasur,
      ukuran: ukuran,
      divan: divan,
      headboard: headboard,
      sorong: sorong,
      isSet: isSet,
      pricelist: pricelist,
      eupKasur: eupKasur,
      eupDivan: eupDivan,
      eupHeadboard: eupHeadboard,
      eupSorong: eupSorong,
      plKasur: plKasur,
      plDivan: plDivan,
      plHeadboard: plHeadboard,
      plSorong: plSorong,
      channel: channel,
    );

CartItem _item({
  required Product product,
  int quantity = 1,
  String kasurSku = 'KC001',
  String divanSku = '',
  String sandaranSku = '',
  String sorongSku = '',
  double discount1 = 0,
  String pricelistArea = '',
  int? indirectStoreAddressNumber,
  List<double> indirectStoreDiscounts = const [],
  String programBulananType = '',
  double programBulananDiscount = 0,
  double programBulananNominal = 0,
}) =>
    CartItem(
      product: product,
      quantity: quantity,
      kasurSku: kasurSku,
      divanSku: divanSku,
      sandaranSku: sandaranSku,
      sorongSku: sorongSku,
      discount1: discount1,
      pricelistArea: pricelistArea,
      indirectStoreAddressNumber: indirectStoreAddressNumber,
      indirectStoreDiscounts: indirectStoreDiscounts,
      programBulananType: programBulananType,
      programBulananDiscount: programBulananDiscount,
      programBulananNominal: programBulananNominal,
    );

// ─── Service factory ─────────────────────────────────────────────────────────

CheckoutOrderService _service() =>
    CheckoutOrderService(client: _FakeApiClient());

List<PendingDetail> _build({
  required List<CartItem> items,
  bool Function(int)? lineIsTakeAway,
}) {
  return _service().buildPendingDetails(
    cartItems: items,
    userId: 9,
    leaderData: null,
    lookupByItemNum: {},
    selectedSpv: null,
    selectedManager: null,
    lineIsTakeAway: lineIsTakeAway ?? (_) => false,
    isBonusTakeAwayChecked: (_, __) => false,
    currentTakeAwayQty: (_, __) => 0,
    profileName: 'Sales Test',
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── Component count ─────────────────────────────────────────────────────
  group('component row count', () {
    test('kasur-only product produces 1 detail row', () {
      final details = _build(items: [_item(product: _product())]);
      expect(details, hasLength(1));
    });

    test('set with kasur + divan produces 2 detail rows', () {
      final product = _product(
        isSet: true,
        divan: 'Divan Kayu',
        plDivan: 500_000,
        eupDivan: 450_000,
      );
      final details = _build(items: [
        _item(product: product, divanSku: 'DV001'),
      ]);
      // kasur + divan = 2
      expect(details, hasLength(2));
    });

    test('full set (kasur+divan+headboard+sorong) produces 4 rows', () {
      final product = _product(
        name: 'Set Utama 160',
        isSet: true,
        divan: 'Divan Kayu 160',
        headboard: 'Sandaran X 160',
        sorong: 'Sorong Y 160',
        plDivan: 500_000,
        eupDivan: 450_000,
        plHeadboard: 300_000,
        eupHeadboard: 270_000,
        plSorong: 200_000,
        eupSorong: 180_000,
      );
      final details = _build(items: [
        _item(
          product: product,
          divanSku: 'DV001',
          sandaranSku: 'HB001',
          sorongSku: 'SR001',
        ),
      ]);
      expect(details, hasLength(4));
    });

    test('tanpa divan/headboard/sorong excluded even when sku provided', () {
      // Product has Tanpa Divan — divan component should be skipped
      // regardless of divanSku value
      final product = _product(isSet: true, divan: 'Tanpa Divan');
      final details = _build(items: [
        _item(product: product, divanSku: 'DV001'),
      ]);
      // Only kasur
      expect(details, hasLength(1));
    });

    test('two cart items produce combined detail rows', () {
      final p1 = _product(id: 'P1', name: 'Item 1');
      final p2 = _product(id: 'P2', name: 'Item 2');
      final details = _build(items: [
        _item(product: p1),
        _item(product: p2),
      ]);
      expect(details, hasLength(2));
    });
  });

  // ── item_type per component ──────────────────────────────────────────────
  group('item_type field per component', () {
    test('kasur row has item_type = Mattress', () {
      final details = _build(items: [_item(product: _product())]);
      expect(details.first.payload['item_type'], 'Mattress');
    });

    test('divan row has item_type = Divan', () {
      final product = _product(
        isSet: true,
        divan: 'Divan Kayu',
        plDivan: 500_000,
        eupDivan: 450_000,
      );
      final details = _build(items: [_item(product: product, divanSku: 'DV1')]);
      final divanRow = details.firstWhere((d) => d.payload['item_type'] == 'Divan');
      expect(divanRow.payload['item_type'], 'Divan');
    });

    test('headboard row has item_type = Headboard', () {
      final product = _product(
        isSet: true,
        headboard: 'Sandaran A',
        plHeadboard: 300_000,
        eupHeadboard: 270_000,
      );
      final details =
          _build(items: [_item(product: product, sandaranSku: 'HB1')]);
      final hbRow =
          details.firstWhere((d) => d.payload['item_type'] == 'Headboard');
      expect(hbRow.payload['item_type'], 'Headboard');
    });

    test('sorong row has item_type = Sorong', () {
      final product = _product(
        isSet: true,
        sorong: 'Sorong B',
        plSorong: 200_000,
        eupSorong: 180_000,
      );
      final details =
          _build(items: [_item(product: product, sorongSku: 'SR1')]);
      final srRow =
          details.firstWhere((d) => d.payload['item_type'] == 'Sorong');
      expect(srRow.payload['item_type'], 'Sorong');
    });
  });

  // ── Field values for kasur component ────────────────────────────────────
  group('kasur detail payload field values', () {
    late Map<String, dynamic> payload;

    setUp(() {
      final product = _product(
        name: 'Spring Bed Foam X 160',
        brand: 'Airland',
        ukuran: '160',
        plKasur: 1_200_000,
        eupKasur: 1_000_000,
        channel: 'MM',
      );
      final details = _build(items: [
        _item(product: product, kasurSku: 'SKU-K160', pricelistArea: 'Jawa'),
      ]);
      payload = details.first.payload;
    });

    test('item_number = kasurSku', () {
      expect(payload['item_number'], 'SKU-K160');
    });

    test('desc_2 = ukuran', () {
      expect(payload['desc_2'], '160');
    });

    test('brand matches product.brand', () {
      expect(payload['brand'], 'Airland');
    });

    test('unit_price = plKasur', () {
      expect(payload['unit_price'], 1_200_000.0);
    });

    test('qty matches item quantity', () {
      final product = _product(plKasur: 1_000_000, eupKasur: 1_000_000);
      final details = _build(
        items: [_item(product: product, quantity: 3)],
      );
      expect(details.first.payload['qty'], 3);
    });

    test('pricelist_type = channel when not empty', () {
      expect(payload['pricelist_type'], 'MM');
    });

    test('pricelist_area = pricelistArea when not empty', () {
      expect(payload['pricelist_area'], 'Jawa');
    });
  });

  // ── Conditional fields ───────────────────────────────────────────────────
  group('conditional fields', () {
    test('pricelist_type NOT present when channel is empty', () {
      final product = _product(channel: '');
      final details = _build(items: [_item(product: product)]);
      expect(details.first.payload.containsKey('pricelist_type'), isFalse);
    });

    test('pricelist_area NOT present when pricelistArea is empty', () {
      final product = _product();
      final details = _build(items: [_item(product: product, pricelistArea: '')]);
      expect(details.first.payload.containsKey('pricelist_area'), isFalse);
    });

    test('take_away = TAKE AWAY when lineIsTakeAway returns true', () {
      final details = _build(
        items: [_item(product: _product())],
        lineIsTakeAway: (_) => true,
      );
      expect(details.first.payload['take_away'], 'TAKE AWAY');
    });

    test('take_away NOT present when lineIsTakeAway returns false', () {
      final details = _build(
        items: [_item(product: _product())],
        lineIsTakeAway: (_) => false,
      );
      expect(details.first.payload.containsKey('take_away'), isFalse);
    });

    test('item_number is null for empty SKU', () {
      // normalizeNullableSku('') = null
      final details = _build(items: [_item(product: _product(), kasurSku: '')]);
      // kasurSku empty → item_number null → no kasur row posted
      // The item would still post via fallback if no component matches...
      // Actually kasurSku empty = kcPresent still depends on hasComponent(p.kasur)
      // so kasur row IS present but item_number = null
      expect(details.first.payload['item_number'], isNull);
    });
  });

  // ── Component ordering ───────────────────────────────────────────────────
  group('component row ordering', () {
    test('full set rows appear in order: Mattress, Divan, Headboard, Sorong', () {
      final product = _product(
        isSet: true,
        divan: 'Divan Kayu',
        headboard: 'Sandaran A',
        sorong: 'Sorong B',
        plDivan: 400_000,
        eupDivan: 360_000,
        plHeadboard: 300_000,
        eupHeadboard: 270_000,
        plSorong: 200_000,
        eupSorong: 180_000,
      );
      final details = _build(items: [
        _item(
          product: product,
          divanSku: 'DV1',
          sandaranSku: 'HB1',
          sorongSku: 'SR1',
        ),
      ]);
      final types =
          details.map((d) => d.payload['item_type'] as String).toList();
      expect(types, ['Mattress', 'Divan', 'Headboard', 'Sorong']);
    });

    test('multiple cart items: all rows of item1 precede rows of item2', () {
      final p1 = _product(
        id: 'P1',
        name: 'Item 1 160',
        isSet: true,
        divan: 'Divan A',
        plDivan: 400_000,
        eupDivan: 360_000,
      );
      final p2 = _product(id: 'P2', name: 'Item 2 160');
      final details = _build(items: [
        _item(product: p1, divanSku: 'DV1'),
        _item(product: p2),
      ]);
      // p1 produces 2 rows (Mattress + Divan), p2 produces 1 row (Mattress)
      expect(details, hasLength(3));
      expect(details[0].payload['item_type'], 'Mattress'); // p1 kasur
      expect(details[1].payload['item_type'], 'Divan');    // p1 divan
      expect(details[2].payload['item_type'], 'Mattress'); // p2 kasur
    });
  });

  // ── Discount rows per detail ─────────────────────────────────────────────
  group('discount rows attached to each detail', () {
    test('kasur detail has non-empty discounts (at least Level 1)', () {
      final details = _build(items: [_item(product: _product())]);
      expect(details.first.discounts, isNotEmpty);
    });

    test('Level 1 discount row always present in detail discounts', () {
      final details = _build(items: [_item(product: _product())]);
      final l1 = details.first.discounts
          .where((d) => d['approver_level_id'] == 1)
          .toList();
      expect(l1, hasLength(1));
    });

    test('label describes the component', () {
      final product = _product(name: 'Foam X 160');
      final details = _build(items: [_item(product: product)]);
      expect(details.first.label, contains('Kasur'));
    });

    test('full set: each component has own discount list', () {
      final product = _product(
        name: 'Set A 160',
        isSet: true,
        divan: 'Divan B',
        plDivan: 400_000,
        eupDivan: 360_000,
      );
      final details =
          _build(items: [_item(product: product, divanSku: 'DV1')]);
      // Both kasur and divan must carry their own discount list
      for (final d in details) {
        // At minimum Level 1 is always auto-approved
        expect(
          d.discounts.any((disc) => disc['approver_level_id'] == 1),
          isTrue,
          reason: '${d.label} missing Level 1 discount',
        );
      }
    });
  });

  // ── Program Bulanan (indirect only) ─────────────────────────────────────
  //
  // Regression tests for two bugs fixed together:
  // 1. Duplication: the level-80 audit row used to be attached to EVERY
  //    component of a SET product, multiplying the recorded discount.
  // 2. net_price ignored the reduction entirely (only the audit row existed,
  //    the actual uploaded price never reflected the discount).
  group('program bulanan (indirect)', () {
    test('nominal type reduces net_price on a kasur-only item', () {
      final product = _product(
        price: 900_000,
        plKasur: 1_000_000,
        eupKasur: 900_000,
      );
      final details = _build(items: [
        _item(
          product: product,
          indirectStoreAddressNumber: 100,
          programBulananType: 'nominal',
          programBulananNominal: 50_000,
        ),
      ]);
      expect(details, hasLength(1));
      expect(details.first.payload['net_price'], 850_000.0);
    });

    test('nominal type scales with quantity (per-unit × qty on line total)', () {
      final product = _product(
        price: 900_000,
        plKasur: 1_000_000,
        eupKasur: 900_000,
      );
      final details = _build(items: [
        _item(
          product: product,
          quantity: 4,
          indirectStoreAddressNumber: 100,
          programBulananType: 'nominal',
          programBulananNominal: 100_000,
        ),
      ]);
      expect(details, hasLength(1));
      // Line: 900_000×4 − 100_000×4 = 3_200_000 → per-unit net_price 800_000
      expect(details.first.payload['net_price'], 800_000.0);
      expect(details.first.payload['qty'], 4);

      final pbRows = details.first.discounts
          .where((r) => r['approver_level_id'] == 80)
          .toList();
      expect(pbRows, hasLength(1));
      expect(pbRows.first['discount_price'], 400_000.0);
    });

    test(
        'nominal type is applied BEFORE diskon tambahan (d1), not after: '
        'order is EUP → diskon toko → Program Bulanan → diskon tambahan', () {
      // EUP 1_000_000, PB nominal 100_000/unit, diskon tambahan (d1) 10%.
      // Correct order: (1_000_000 − 100_000) × 0.9 = 810_000.
      // Wrong order (PB after d1): 1_000_000 × 0.9 − 100_000 = 800_000.
      final product = _product(
        price: 900_000,
        plKasur: 1_000_000,
        eupKasur: 1_000_000,
      );
      final details = _build(items: [
        _item(
          product: product,
          indirectStoreAddressNumber: 100,
          discount1: 10,
          programBulananType: 'nominal',
          programBulananNominal: 100_000,
        ),
      ]);
      expect(details, hasLength(1));
      expect(details.first.payload['net_price'], 810_000.0);

      final pbRows = details.first.discounts
          .where((r) => r['approver_level_id'] == 80)
          .toList();
      expect(pbRows, hasLength(1));
      // Audit row reflects the same order-adjusted amount actually deducted.
      expect(pbRows.first['discount_price'], 90_000.0);
    });

    test('does not double-cut when product.price is legacy post-PB snapshot', () {
      // Real cart path used to bake displayTotal into product.price while
      // eup* stayed pre-PB. markupDiff must not re-apply that delta.
      final product = _product(
        price: 850_000, // 900_000 − 50_000 (legacy display bake)
        plKasur: 1_000_000,
        eupKasur: 900_000,
      );
      final details = _build(items: [
        _item(
          product: product,
          quantity: 2,
          indirectStoreAddressNumber: 100,
          programBulananType: 'nominal',
          programBulananNominal: 50_000,
        ),
      ]);
      expect(details, hasLength(1));
      // One cut only: 900_000 − 50_000 = 850_000 per unit (not 800_000)
      expect(details.first.payload['net_price'], 850_000.0);
      final pbRows = details.first.discounts
          .where((r) => r['approver_level_id'] == 80)
          .toList();
      expect(pbRows.first['discount_price'], 100_000.0);
    });

    test('nominal type: audit row appears exactly once for a SET product '
        '(no duplication across kasur + divan)', () {
      final product = _product(
        price: 1_350_000, // eupKasur + eupDivan, no markup
        isSet: true,
        divan: 'Divan Kayu',
        plKasur: 1_000_000,
        eupKasur: 900_000,
        plDivan: 500_000,
        eupDivan: 450_000,
      );
      final details = _build(items: [
        _item(
          product: product,
          divanSku: 'DV001',
          indirectStoreAddressNumber: 100,
          programBulananType: 'nominal',
          programBulananNominal: 50_000,
        ),
      ]);
      expect(details, hasLength(2));

      final pbRows = details
          .expand((d) => d.discounts)
          .where((r) => r['approver_level_id'] == 80)
          .toList();
      expect(pbRows, hasLength(1), reason: 'level-80 row must not repeat');
      expect(pbRows.first['discount_price'], 50_000.0);

      // Nominal reduction fully absorbed by the anchor (kasur) component;
      // divan's net_price is untouched by program bulanan.
      final kasur = details.firstWhere((d) => d.payload['item_type'] == 'Mattress');
      final divan = details.firstWhere((d) => d.payload['item_type'] == 'Divan');
      expect(kasur.payload['net_price'], 850_000.0);
      expect(divan.payload['net_price'], 450_000.0);
      expect(
        divan.discounts.where((r) => r['approver_level_id'] == 80),
        isEmpty,
        reason: 'audit row must live on the anchor (kasur) only',
      );
    });

    test('percent type reduces net_price proportionally on every component '
        'of a SET, with a single audit row', () {
      final product = _product(
        price: 1_350_000,
        isSet: true,
        divan: 'Divan Kayu',
        plKasur: 1_000_000,
        eupKasur: 900_000,
        plDivan: 500_000,
        eupDivan: 450_000,
      );
      final details = _build(items: [
        _item(
          product: product,
          divanSku: 'DV001',
          indirectStoreAddressNumber: 100,
          programBulananType: 'percent',
          programBulananDiscount: 10,
        ),
      ]);

      final pbRows = details
          .expand((d) => d.discounts)
          .where((r) => r['approver_level_id'] == 80)
          .toList();
      expect(pbRows, hasLength(1));
      expect(pbRows.first['discount'], '10.0');

      final kasur = details.firstWhere((d) => d.payload['item_type'] == 'Mattress');
      final divan = details.firstWhere((d) => d.payload['item_type'] == 'Divan');
      expect(kasur.payload['net_price'], 810_000.0); // 900_000 * 0.9
      expect(divan.payload['net_price'], 405_000.0); // 450_000 * 0.9
    });

    test('no level-80 row and no net_price reduction when program bulanan '
        'is not set', () {
      final product = _product(
        price: 900_000,
        plKasur: 1_000_000,
        eupKasur: 900_000,
      );
      final details = _build(items: [
        _item(product: product, indirectStoreAddressNumber: 100),
      ]);
      expect(
        details.first.discounts.where((r) => r['approver_level_id'] == 80),
        isEmpty,
      );
      expect(details.first.payload['net_price'], 900_000.0);
    });

    test('program bulanan ignored for direct (non-indirect) sales', () {
      final product = _product(
        price: 900_000,
        plKasur: 1_000_000,
        eupKasur: 900_000,
      );
      final details = _build(items: [
        _item(
          product: product,
          // No indirectStoreAddressNumber => isIndirectSale = false.
          programBulananType: 'nominal',
          programBulananNominal: 50_000,
        ),
      ]);
      expect(
        details.first.discounts.where((r) => r['approver_level_id'] == 80),
        isEmpty,
      );
      expect(details.first.payload['net_price'], 900_000.0);
    });
  });

  // ── Required payload fields present ─────────────────────────────────────
  group('required payload fields always present', () {
    test('kasur payload has all mandatory keys', () {
      final details = _build(items: [_item(product: _product())]);
      final payload = details.first.payload;
      for (final key in [
        'item_description',
        'desc_1',
        'desc_2',
        'brand',
        'unit_price',
        'customer_price',
        'net_price',
        'qty',
        'item_type',
      ]) {
        expect(
          payload.containsKey(key),
          isTrue,
          reason: 'Kasur payload missing: $key',
        );
      }
    });
  });
}
