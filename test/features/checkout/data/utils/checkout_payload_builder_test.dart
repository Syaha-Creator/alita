// Tests for CheckoutPayloadBuilder — verifies every JSON field sent to the server.
//
// These are payload-contract tests: if a field name, value, or conditional
// inclusion rule ever changes during a refactor, these tests will fail
// and alert the developer before the bad payload reaches the backend.

import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/checkout/data/utils/checkout_payload_builder.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

Product _product({
  String id = 'P1',
  bool isSet = false,
  double price = 1_000_000,
  double pricelist = 0,
  double plKasur = 0,
  double plDivan = 0,
  double plHeadboard = 0,
  double plSorong = 0,
  String divan = 'Tanpa Divan',
  String headboard = 'Tanpa Headboard',
  String sorong = 'Tanpa Sorong',
}) =>
    Product(
      id: id,
      name: 'Test Kasur $id',
      price: price,
      imageUrl: '',
      category: 'Kasur',
      kasur: 'Foam X',
      ukuran: '160',
      divan: divan,
      headboard: headboard,
      sorong: sorong,
      isSet: isSet,
      pricelist: pricelist,
      eupKasur: price,
      eupDivan: 0,
      eupHeadboard: 0,
      eupSorong: 0,
      plKasur: plKasur,
      plDivan: plDivan,
      plHeadboard: plHeadboard,
      plSorong: plSorong,
    );

CartItem _cartItem({
  required Product product,
  int quantity = 1,
  String kasurSku = 'SKU-K1',
  String divanSku = '',
  String sandaranSku = '',
  String sorongSku = '',
}) =>
    CartItem(
      product: product,
      quantity: quantity,
      kasurSku: kasurSku,
      divanSku: divanSku,
      sandaranSku: sandaranSku,
      sorongSku: sorongSku,
    );

final _orderDate = DateTime(2025, 6, 15);
final _requestDate = DateTime(2025, 6, 20);

Map<String, dynamic> _defaultHeader({
  List<CartItem>? cartItems,
  double grandTotal = 800_000,
  bool isShippingSameAsCustomer = true,
  bool headerAllLinesTakeAway = false,
  bool autoApprove = false,
  bool isIndirectOrder = false,
  bool useCustomerAddressDetailOnly = false,
  String postageText = '',
  String? salesCode,
  String indirectNoPoText = '',
  int? indirectCustomerMaster,
  DateTime? requestDate,
  List<Map<String, dynamic>>? divisions,
}) {
  final items = cartItems ??
      [
        _cartItem(
          product: _product(price: 1_000_000, plKasur: 1_000_000),
        ),
      ];
  return CheckoutPayloadBuilder.buildHeaderPayload(
    workPlaceId: 1,
    customerAddress: 'Jl. Mawar No.1',
    selectedKecamatan: 'Kec. A',
    selectedKota: 'Kota B',
    selectedProvinsi: 'Prov C',
    isShippingSameAsCustomer: isShippingSameAsCustomer,
    customerName: 'Budi',
    shippingName: 'Siti',
    shippingAddress: 'Jl. Anggrek No.2',
    shippingKecamatan: 'Kec. X',
    shippingKota: 'Kota Y',
    shippingProvinsi: 'Prov Z',
    postageText: postageText,
    creatorId: 9,
    divisions: divisions ??
        [
          {'id': 26, 'name': 'MM'}
        ],
    cartItems: items,
    grandTotal: grandTotal,
    orderDate: _orderDate,
    requestDate: requestDate,
    customerPhone: '081234567890',
    customerEmail: 'budi@mail.com',
    note: 'Catatan',
    salesCode: salesCode ?? '',
    headerAllLinesTakeAway: headerAllLinesTakeAway,
    useCustomerAddressDetailOnly: useCustomerAddressDetailOnly,
    isIndirectOrder: isIndirectOrder,
    indirectNoPoText: indirectNoPoText,
    indirectCustomerMaster: indirectCustomerMaster,
    autoApprove: autoApprove,
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── buildHeaderPayload ────────────────────────────────────────────────────
  group('CheckoutPayloadBuilder.buildHeaderPayload', () {
    group('required fields always present', () {
      test('contains all mandatory keys', () {
        final p = _defaultHeader();
        for (final key in [
          'order_date',
          'creator',
          'customer_name',
          'phone',
          'email',
          'address',
          'ship_to_name',
          'address_ship_to',
          'extended_amount',
          'harga_awal',
          'discount',
          'note',
          'status',
          'work_place_id',
          'take_away',
          'postage',
          'channel',
        ]) {
          expect(p.containsKey(key), isTrue, reason: 'Missing key: $key');
        }
      });

      test('creator is integer user id', () {
        final p = _defaultHeader();
        expect(p['creator'], 9);
      });

      test('order_date formatted as yyyy-MM-dd', () {
        final p = _defaultHeader();
        expect(p['order_date'], '2025-06-15');
      });

      test('request_date formatted as yyyy-MM-dd when provided', () {
        final p = _defaultHeader(requestDate: _requestDate);
        expect(p['request_date'], '2025-06-20');
      });

      test('request_date is null when not provided', () {
        final p = _defaultHeader(requestDate: null);
        expect(p['request_date'], isNull);
      });
    });

    group('address construction', () {
      test('address appends kecamatan, kota, provinsi for direct order', () {
        final p = _defaultHeader();
        expect(
          p['address'],
          'Jl. Mawar No.1, Kec. Kec. A, Kota B, Prov C',
        );
      });

      test('address is raw when useCustomerAddressDetailOnly = true', () {
        final p = _defaultHeader(useCustomerAddressDetailOnly: true);
        expect(p['address'], 'Jl. Mawar No.1');
      });

      test('ship_to_name = customerName when isShippingSameAsCustomer', () {
        final p = _defaultHeader(isShippingSameAsCustomer: true);
        expect(p['ship_to_name'], 'Budi');
      });

      test('ship_to_name = shippingName when different address', () {
        final p = _defaultHeader(isShippingSameAsCustomer: false);
        expect(p['ship_to_name'], 'Siti');
      });

      test('address_ship_to = fullCustomerAddress when same', () {
        final p = _defaultHeader(isShippingSameAsCustomer: true);
        expect(
          p['address_ship_to'],
          'Jl. Mawar No.1, Kec. Kec. A, Kota B, Prov C',
        );
      });

      test('address_ship_to = separate shipping address when different', () {
        final p = _defaultHeader(isShippingSameAsCustomer: false);
        expect(
          p['address_ship_to'],
          'Jl. Anggrek No.2, Kec. Kec. X, Kota Y, Prov Z',
        );
      });
    });

    group('channel selection (S1 > S0 > MM > empty)', () {
      test('S1 when divisionId 25 present', () {
        final p = _defaultHeader(
          divisions: [
            {'id': 25},
            {'id': 24},
            {'id': 26},
          ],
        );
        expect(p['channel'], 'S1');
      });

      test('SO when divisionId 24 present but no S1', () {
        final p = _defaultHeader(
          divisions: [
            {'id': 24},
            {'id': 26},
          ],
        );
        expect(p['channel'], 'SO');
      });

      test('MM when divisionId 26 present but no S1/SO', () {
        final p = _defaultHeader(
          divisions: [
            {'id': 26}
          ],
        );
        expect(p['channel'], 'MM');
      });

      test('empty when no known division id', () {
        final p = _defaultHeader(divisions: [
          {'id': 99}
        ]);
        expect(p['channel'], '');
      });
    });

    group('harga_awal calculation', () {
      test('uses plKasur * qty when kasurSku not empty', () {
        final product = _product(plKasur: 1_500_000);
        final p = _defaultHeader(
          cartItems: [_cartItem(product: product, quantity: 2, kasurSku: 'K1')],
          grandTotal: 2_500_000,
        );
        expect(p['harga_awal'], 3_000_000.0);
      });

      test('includes plDivan * qty when divanSku not empty and not tanpa', () {
        final product = _product(
          isSet: true,
          plKasur: 1_000_000,
          plDivan: 500_000,
          divan: 'Divan Kayu',
        );
        final p = _defaultHeader(
          cartItems: [
            _cartItem(
              product: product,
              quantity: 1,
              kasurSku: 'K1',
              divanSku: 'D1',
            ),
          ],
          grandTotal: 1_200_000,
        );
        expect(p['harga_awal'], 1_500_000.0);
      });

      test('excludes plDivan when divan contains tanpa', () {
        final product = _product(
          isSet: true,
          plKasur: 1_000_000,
          plDivan: 500_000,
          divan: 'Tanpa Divan',
        );
        final p = _defaultHeader(
          cartItems: [
            _cartItem(
              product: product,
              quantity: 1,
              kasurSku: 'K1',
              divanSku: 'D1',
            ),
          ],
          grandTotal: 800_000,
        );
        expect(p['harga_awal'], 1_000_000.0);
      });

      test('fallback to pricelist when no component contributed', () {
        final product = _product(
          price: 2_000_000,
          pricelist: 1_800_000,
          plKasur: 0,
        );
        final p = _defaultHeader(
          cartItems: [_cartItem(product: product, kasurSku: '')],
          grandTotal: 1_500_000,
        );
        expect(p['harga_awal'], 1_800_000.0);
      });

      test('fallback to price when pricelist is 0', () {
        final product = _product(price: 2_000_000, pricelist: 0, plKasur: 0);
        final p = _defaultHeader(
          cartItems: [_cartItem(product: product, kasurSku: '')],
          grandTotal: 1_000_000,
        );
        expect(p['harga_awal'], 2_000_000.0);
      });
    });

    group('discount percentage', () {
      test('correct percentage = (hargaAwal - grandTotal) / hargaAwal * 100',
          () {
        final product = _product(plKasur: 1_000_000);
        final p = _defaultHeader(
          cartItems: [_cartItem(product: product, kasurSku: 'K1')],
          grandTotal: 800_000,
        );
        expect(p['discount'], closeTo(20.0, 0.001));
      });

      test('discount = 0.0 when harga_awal is 0', () {
        final product = _product(price: 0, pricelist: 0, plKasur: 0);
        final p = _defaultHeader(
          cartItems: [_cartItem(product: product, kasurSku: '')],
          grandTotal: 0,
        );
        expect(p['discount'], 0.0);
      });
    });

    group('extended_amount', () {
      test('extended_amount = grandTotal + postage', () {
        final p = _defaultHeader(
          grandTotal: 1_000_000,
          postageText: '50.000',
        );
        expect(p['extended_amount'], 1_050_000.0);
        expect(p['postage'], 50_000.0);
      });

      test('postage = 0 when postageText empty', () {
        final p = _defaultHeader(postageText: '');
        expect(p['postage'], 0.0);
      });

      test('postage strips thousands separator', () {
        final p = _defaultHeader(postageText: '1.500.000');
        expect(p['postage'], 1_500_000.0);
      });
    });

    group('take_away field', () {
      test('take_away = TAKE AWAY when headerAllLinesTakeAway = true', () {
        final p = _defaultHeader(headerAllLinesTakeAway: true);
        expect(p['take_away'], 'TAKE AWAY');
      });

      test('take_away = null when headerAllLinesTakeAway = false', () {
        final p = _defaultHeader(headerAllLinesTakeAway: false);
        expect(p['take_away'], isNull);
      });
    });

    group('status field', () {
      test('status = Pending (Pending Approval) when autoApprove = false', () {
        final p = _defaultHeader(autoApprove: false);
        expect((p['status'] as String).toLowerCase(), contains('pending'));
      });

      test('status = Approved when autoApprove = true', () {
        final p = _defaultHeader(autoApprove: true);
        expect((p['status'] as String).toLowerCase(), contains('approved'));
      });
    });

    group('sales_code', () {
      test('sales_code is null when empty string', () {
        final p = _defaultHeader(salesCode: '');
        expect(p['sales_code'], isNull);
      });

      test('sales_code is null when whitespace only', () {
        final p = _defaultHeader(salesCode: '   ');
        expect(p['sales_code'], isNull);
      });

      test('sales_code is trimmed value when provided', () {
        final p = _defaultHeader(salesCode: '  SL001  ');
        expect(p['sales_code'], 'SL001');
      });
    });

    group('no_po conditional field', () {
      test('no_po NOT included when indirectNoPoText is empty', () {
        final p = _defaultHeader(indirectNoPoText: '');
        expect(p.containsKey('no_po'), isFalse);
      });

      test('no_po included and trimmed when provided', () {
        final p = _defaultHeader(indirectNoPoText: '  PO-999  ');
        expect(p['no_po'], 'PO-999');
      });
    });

    group('customer_master conditional field (indirect)', () {
      test('customer_master included for indirect with valid id', () {
        final p = _defaultHeader(
          isIndirectOrder: true,
          indirectCustomerMaster: 42,
        );
        expect(p['customer_master'], 42);
      });

      test('customer_master NOT included when id is 0', () {
        final p = _defaultHeader(
          isIndirectOrder: true,
          indirectCustomerMaster: 0,
        );
        expect(p.containsKey('customer_master'), isFalse);
      });

      test('customer_master NOT included when id is null', () {
        final p = _defaultHeader(
          isIndirectOrder: true,
          indirectCustomerMaster: null,
        );
        expect(p.containsKey('customer_master'), isFalse);
      });

      test('customer_master NOT included for direct order', () {
        final p = _defaultHeader(
          isIndirectOrder: false,
          indirectCustomerMaster: 42,
        );
        expect(p.containsKey('customer_master'), isFalse);
      });
    });
  });

  // ── buildNewCustomerContactPayload ────────────────────────────────────────
  group('CheckoutPayloadBuilder.buildNewCustomerContactPayload', () {
    test('wilayah comes from regionText when not empty', () {
      final p = CheckoutPayloadBuilder.buildNewCustomerContactPayload(
        customerName: 'Ani',
        customerPhone: '081111',
        customerEmail: 'ani@mail.com',
        customerAddress: 'Jl. A',
        regionText: 'Wilayah Utara',
        selectedKecamatan: 'Kec. Tes',
        selectedKota: 'Kota Tes',
        selectedProvinsi: 'Prov Tes',
      );
      expect(p['wilayah'], 'Wilayah Utara');
    });

    test('wilayah constructed from kec+kota+prov when regionText empty', () {
      final p = CheckoutPayloadBuilder.buildNewCustomerContactPayload(
        customerName: 'Ani',
        customerPhone: '081111',
        customerEmail: 'ani@mail.com',
        customerAddress: 'Jl. A',
        regionText: '',
        selectedKecamatan: 'Kec. Maju',
        selectedKota: 'Kota Jaya',
        selectedProvinsi: 'Prov Baik',
      );
      expect(p['wilayah'], 'Kec. Kec. Maju, Kota Jaya, Prov Baik');
    });

    test('phone2 included when not empty', () {
      final p = CheckoutPayloadBuilder.buildNewCustomerContactPayload(
        customerName: 'Ani',
        customerPhone: '081111',
        customerEmail: 'ani@mail.com',
        customerAddress: 'Jl. A',
        regionText: '',
        customerPhone2: '082222',
      );
      expect(p['phone2'], '082222');
    });

    test('phone2 NOT included when empty', () {
      final p = CheckoutPayloadBuilder.buildNewCustomerContactPayload(
        customerName: 'Ani',
        customerPhone: '081111',
        customerEmail: 'ani@mail.com',
        customerAddress: 'Jl. A',
        regionText: '',
        customerPhone2: '',
      );
      expect(p.containsKey('phone2'), isFalse);
    });

    test('contains all required fields', () {
      final p = CheckoutPayloadBuilder.buildNewCustomerContactPayload(
        customerName: 'Ani',
        customerPhone: '081111',
        customerEmail: 'ani@mail.com',
        customerAddress: 'Jl. A',
        regionText: 'X',
      );
      for (final key in [
        'name',
        'phone',
        'email',
        'wilayah',
        'alamat_detail',
        'address',
        'provinsi',
        'kota',
        'kecamatan',
      ]) {
        expect(p.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });
  });

  // ── buildOrderLetterContactsPayload ───────────────────────────────────────
  group('CheckoutPayloadBuilder.buildOrderLetterContactsPayload', () {
    Map<String, dynamic> call({
      bool isIndirect = false,
      bool isSameAddress = true,
      String custPrimary = '081111',
      String custBackup = '082222',
      bool includeBackup = false,
      String shipPrimary = '083333',
      String shipBackup = '084444',
      bool includeShipBackup = false,
    }) =>
        {
          'contacts': CheckoutPayloadBuilder.buildOrderLetterContactsPayload(
            isIndirectOrder: isIndirect,
            isShippingSameAsCustomer: isSameAddress,
            customerPrimaryPhone: custPrimary,
            customerBackupPhone: custBackup,
            includeCustomerBackupPhone: includeBackup,
            shippingPrimaryPhone: shipPrimary,
            shippingBackupPhone: shipBackup,
            includeShippingBackupPhone: includeShipBackup,
          ),
        };

    test('direct same-address: only customer primary phone', () {
      final result =
          call(isIndirect: false, isSameAddress: true, includeBackup: false);
      final contacts = result['contacts'] as List<Map<String, dynamic>>;
      expect(contacts, hasLength(1));
      expect(contacts[0]['phone'], '081111');
      expect(contacts[0]['ship'], false);
    });

    test('direct same-address: includes customer backup when flag true', () {
      final result =
          call(isIndirect: false, isSameAddress: true, includeBackup: true);
      final contacts = result['contacts'] as List<Map<String, dynamic>>;
      expect(contacts, hasLength(2));
      expect(contacts[1]['phone'], '082222');
      expect(contacts[1]['ship'], false);
    });

    test('direct different-address: customer + shipping contacts', () {
      final result = call(
        isIndirect: false,
        isSameAddress: false,
        includeBackup: false,
        includeShipBackup: false,
      );
      final contacts = result['contacts'] as List<Map<String, dynamic>>;
      expect(contacts, hasLength(2));
      expect(contacts[0]['ship'], false);
      expect(contacts[1]['ship'], true);
      expect(contacts[1]['phone'], '083333');
    });

    test('direct different-address: all 4 phones when both backups included',
        () {
      final result = call(
        isIndirect: false,
        isSameAddress: false,
        includeBackup: true,
        includeShipBackup: true,
      );
      final contacts = result['contacts'] as List<Map<String, dynamic>>;
      expect(contacts, hasLength(4));
    });

    test('indirect same-address: returns empty list', () {
      final result = call(isIndirect: true, isSameAddress: true);
      final contacts = result['contacts'] as List<Map<String, dynamic>>;
      expect(contacts, isEmpty);
    });

    test('indirect different-address: only shipping phone', () {
      final result = call(
          isIndirect: true, isSameAddress: false, includeShipBackup: false);
      final contacts = result['contacts'] as List<Map<String, dynamic>>;
      expect(contacts, hasLength(1));
      expect(contacts[0]['phone'], '083333');
      expect(contacts[0]['ship'], true);
    });

    test('indirect different-address: shipping + backup when flag true', () {
      final result =
          call(isIndirect: true, isSameAddress: false, includeShipBackup: true);
      final contacts = result['contacts'] as List<Map<String, dynamic>>;
      expect(contacts, hasLength(2));
    });

    test('empty phone strings are skipped', () {
      final contacts = CheckoutPayloadBuilder.buildOrderLetterContactsPayload(
        isIndirectOrder: false,
        isShippingSameAsCustomer: true,
        customerPrimaryPhone: '',
        customerBackupPhone: '',
        includeCustomerBackupPhone: true,
        shippingPrimaryPhone: '',
        shippingBackupPhone: '',
        includeShippingBackupPhone: true,
      );
      expect(contacts, isEmpty);
    });
  });

  // ── buildPaymentPayload ───────────────────────────────────────────────────
  group('CheckoutPayloadBuilder.buildPaymentPayload', () {
    Map<String, dynamic> pay({
      bool isLunas = false,
      double totalAkhir = 1_000_000,
      String paymentAmountText = '500.000',
      String? method = 'Transfer',
      String? bank = 'BCA',
      String otherChannel = '',
      String ref = 'REF001',
      String note = '',
    }) =>
        CheckoutPayloadBuilder.buildPaymentPayload(
          isLunas: isLunas,
          totalAkhir: totalAkhir,
          paymentAmountText: paymentAmountText,
          paymentMethod: method,
          paymentBank: bank,
          otherChannelText: otherChannel,
          paymentRefText: ref,
          paymentDate: DateTime(2025, 6, 15),
          paymentNoteText: note,
          userId: 9,
        );

    test('contains all required keys', () {
      final p = pay();
      for (final key in [
        'payment_method',
        'payment_bank',
        'payment_number',
        'payment_amount',
        'payment_date',
        'note',
        'created_by',
      ]) {
        expect(p.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });

    test('isLunas=true uses totalAkhir as payment_amount', () {
      final p = pay(isLunas: true, totalAkhir: 1_200_000);
      expect(p['payment_amount'], 1_200_000.0);
    });

    test('isLunas=false parses paymentAmountText', () {
      final p = pay(isLunas: false, paymentAmountText: '750.000');
      expect(p['payment_amount'], 750_000.0);
    });

    test('method Lainnya maps to other', () {
      final p = pay(method: 'Lainnya', otherChannel: 'Gopay');
      expect(p['payment_method'], 'other');
    });

    test('payment_bank uses otherChannelText when method is Lainnya', () {
      final p = pay(method: 'Lainnya', bank: 'BCA', otherChannel: 'Gopay');
      expect(p['payment_bank'], 'Gopay');
    });

    test('normal method and bank passed through unchanged', () {
      final p = pay(method: 'Transfer', bank: 'Mandiri');
      expect(p['payment_method'], 'Transfer');
      expect(p['payment_bank'], 'Mandiri');
    });

    test('payment_date formatted as yyyy-MM-dd', () {
      final p = pay();
      expect(p['payment_date'], '2025-06-15');
    });

    test('created_by is userId', () {
      final p = pay();
      expect(p['created_by'], 9);
    });
  });

  // ── buildPaymentEntryPayload ──────────────────────────────────────────────
  group('CheckoutPayloadBuilder.buildPaymentEntryPayload', () {
    Map<String, dynamic> entry({
      String amount = '1.000.000',
      String? method = 'Transfer',
      String? bank = 'BRI',
      String other = '',
      String ref = '',
      String note = '',
    }) =>
        CheckoutPayloadBuilder.buildPaymentEntryPayload(
          amountText: amount,
          method: method,
          bank: bank,
          otherChannelText: other,
          refText: ref,
          date: DateTime(2025, 1, 1),
          noteText: note,
          userId: 7,
        );

    test('always parses amountText regardless of isLunas', () {
      final p = entry(amount: '2.500.000');
      expect(p['payment_amount'], 2_500_000.0);
    });

    test('method Lainnya → other, bank = otherChannelText', () {
      final p = entry(method: 'Lainnya', other: 'Dana');
      expect(p['payment_method'], 'other');
      expect(p['payment_bank'], 'Dana');
    });

    test('contains all required keys', () {
      final p = entry();
      for (final key in [
        'payment_method',
        'payment_bank',
        'payment_number',
        'payment_amount',
        'payment_date',
        'note',
        'created_by',
      ]) {
        expect(p.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });
  });
}
