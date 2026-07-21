import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/quotation/data/quotation_model.dart';

void main() {
  group('QuotationStatus', () {
    test('label returns correct string', () {
      expect(QuotationStatus.draft.label, 'Draft');
      expect(QuotationStatus.sent.label, 'Dibagikan');
      expect(QuotationStatus.converted.label, 'Jadi SP');
    });
  });

  group('QuotationModel', () {
    test('isExpired returns true when validUntil is in the past', () {
      final q = _makeQuotation(
        validUntil: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(q.isExpired, true);
    });

    test('isExpired returns false when validUntil is in the future', () {
      final q = _makeQuotation(
        validUntil: DateTime.now().add(const Duration(days: 7)),
      );
      expect(q.isExpired, false);
    });

    test('isExpired returns false when validUntil is null', () {
      final q = _makeQuotation();
      expect(q.isExpired, false);
    });

    test('daysRemaining returns positive for future date', () {
      final q = _makeQuotation(
        validUntil: DateTime.now().add(const Duration(days: 5)),
      );
      expect(q.daysRemaining, greaterThanOrEqualTo(4));
    });

    test('daysRemaining returns -1 when validUntil is null', () {
      final q = _makeQuotation();
      expect(q.daysRemaining, -1);
    });

    test('copyWith preserves unchanged fields', () {
      final q = _makeQuotation(customerName: 'Alice');
      final copy = q.copyWith(customerName: 'Bob');

      expect(copy.customerName, 'Bob');
      expect(copy.id, q.id);
      expect(copy.totalPrice, q.totalPrice);
      expect(copy.createdAt, q.createdAt);
    });

    test('copyWith updates status', () {
      final q = _makeQuotation();
      final copy = q.copyWith(status: QuotationStatus.converted);
      expect(copy.status, QuotationStatus.converted);
    });

    test('toJson produces correct keys', () {
      final q = _makeQuotation(
        customerName: 'Test',
        customerEmail: 'test@example.com',
        isTakeAway: true,
      );
      final json = q.toJson();

      expect(json['customerName'], 'Test');
      expect(json['customerEmail'], 'test@example.com');
      expect(json['isTakeAway'], true);
      expect(json['createdAt'], isA<String>());
      expect(json['status'], 'draft');
    });

    test('fromJson roundtrip preserves data', () {
      final original = _makeQuotation(
        customerName: 'Roundtrip',
        customerPhone: '081234567890',
        status: QuotationStatus.sent,
      );
      final json = original.toJson();
      final restored = QuotationModel.fromJson(json);

      expect(restored.customerName, 'Roundtrip');
      expect(restored.customerPhone, '081234567890');
      expect(restored.status, QuotationStatus.sent);
      expect(restored.id, original.id);
    });

    test('shippingPhone2 roundtrips in JSON', () {
      final original = QuotationModel(
        id: 's2',
        customerName: 'Toko',
        isShippingSameAsCustomer: false,
        shippingPhone: '081111111111',
        shippingPhone2: '082222222222',
        items: const [],
        subtotal: 0,
        totalPrice: 0,
        createdAt: DateTime(2026, 3, 1),
      );
      final restored = QuotationModel.fromJson(original.toJson());
      expect(restored.shippingPhone2, '082222222222');
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'test-id',
        'customerName': 'Minimal',
        'items': <dynamic>[],
        'subtotal': 0,
        'totalPrice': 0,
        'createdAt': '2026-03-01T00:00:00.000Z',
      };

      final q = QuotationModel.fromJson(json);
      expect(q.customerName, 'Minimal');
      expect(q.customerEmail, '');
      expect(q.isTakeAway, false);
      expect(q.isShippingSameAsCustomer, true);
      expect(q.status, QuotationStatus.draft);
      expect(q.validUntil, isNull);
      expect(q.receiverEmail, '');
      expect(q.indirectNoPo, '');
      expect(q.bonusTakeAwayCheckedKeys, isEmpty);
      expect(q.bonusTakeAwayQtyByKey, isEmpty);
    });

    test('receiverEmail indirectNoPo bonusTakeAway roundtrip in JSON', () {
      final original = QuotationModel(
        id: 'draft-1',
        customerName: 'Toko',
        receiverEmail: 'gudang@toko.id',
        indirectNoPo: 'PO-99',
        bonusTakeAwayCheckedKeys: const ['0_SKU1', '1_SKU2'],
        bonusTakeAwayQtyByKey: const {'0_SKU1': 2, '1_SKU2': 1},
        items: const [],
        subtotal: 0,
        totalPrice: 0,
        createdAt: DateTime(2026, 3, 1),
      );
      final restored = QuotationModel.fromJson(original.toJson());
      expect(restored.receiverEmail, 'gudang@toko.id');
      expect(restored.indirectNoPo, 'PO-99');
      expect(restored.bonusTakeAwayCheckedKeys, ['0_SKU1', '1_SKU2']);
      expect(restored.bonusTakeAwayQtyByKey, {'0_SKU1': 2, '1_SKU2': 1});
    });

    test('lineTakeAway falls back to legacy flag when entry is not a bool', () {
      final items = [
        CartItem(product: _product(id: '1'), quantity: 1),
        CartItem(product: _product(id: '2'), quantity: 1),
        CartItem(product: _product(id: '3'), quantity: 1),
      ];
      final json = <String, dynamic>{
        'id': 'x',
        'customerName': 'A',
        'isTakeAway': true,
        'lineTakeAway': [true, 'not-a-bool', false],
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': 0,
        'totalPrice': 0,
        'createdAt': '2026-01-01T00:00:00Z',
      };
      // Round-trip through an actual JSON string (like decodeList does) so
      // nested Product objects are converted to plain Maps, matching what
      // CartItem.fromJson expects.
      final decodedJson =
          jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

      final q = QuotationModel.fromJson(decodedJson);
      // Index 1 has a malformed (non-bool) entry — falls back to the
      // legacy top-level isTakeAway flag instead of throwing.
      expect(q.lineTakeAway, [true, true, false]);
    });

    test('_parseStatus defaults to draft for unknown value', () {
      final json = <String, dynamic>{
        'id': 'x',
        'customerName': 'A',
        'items': <dynamic>[],
        'subtotal': 0,
        'totalPrice': 0,
        'createdAt': '2026-01-01T00:00:00Z',
        'status': 'unknown_status',
      };

      final q = QuotationModel.fromJson(json);
      expect(q.status, QuotationStatus.draft);
    });
  });

  group('QuotationModel.encodeList / decodeList', () {
    test('roundtrip encode-decode preserves list', () {
      final list = [
        _makeQuotation(customerName: 'A'),
        _makeQuotation(customerName: 'B'),
      ];

      final encoded = QuotationModel.encodeList(list);
      final decoded = QuotationModel.decodeList(encoded);

      expect(decoded, hasLength(2));
      expect(decoded[0].customerName, 'A');
      expect(decoded[1].customerName, 'B');
    });

    test('decodeList returns empty for empty string', () {
      expect(QuotationModel.decodeList(''), isEmpty);
    });

    test('decodeList returns empty for invalid json', () {
      expect(QuotationModel.decodeList('not json'), isEmpty);
    });

    test('decodeList skips corrupt items', () {
      final encoded = '[{"id":"good","customerName":"OK","items":[],"subtotal":0,"totalPrice":0,"createdAt":"2026-01-01T00:00:00Z"}, "bad_item"]';
      final decoded = QuotationModel.decodeList(encoded);
      expect(decoded, hasLength(1));
      expect(decoded[0].customerName, 'OK');
    });
  });
}

Product _product({String id = '1', double price = 1000}) => Product(
      id: id,
      name: 'Test $id',
      price: price,
      imageUrl: '',
      category: 'C',
      kasur: 'K',
      ukuran: '160x200',
      divan: '',
      headboard: '',
      sorong: '',
      isSet: false,
      pricelist: price,
      eupKasur: price,
      eupDivan: 0,
      eupHeadboard: 0,
      eupSorong: 0,
      plKasur: price,
      plDivan: 0,
      plHeadboard: 0,
      plSorong: 0,
    );

QuotationModel _makeQuotation({
  String customerName = 'Test Customer',
  String customerEmail = '',
  String customerPhone = '',
  bool isTakeAway = false,
  QuotationStatus status = QuotationStatus.draft,
  DateTime? validUntil,
}) =>
    QuotationModel(
      id: 'q-${DateTime.now().microsecondsSinceEpoch}',
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      isTakeAway: isTakeAway,
      items: const [],
      subtotal: 1000000,
      totalPrice: 1000000,
      createdAt: DateTime(2026, 3, 1),
      status: status,
      validUntil: validUntil,
    );
