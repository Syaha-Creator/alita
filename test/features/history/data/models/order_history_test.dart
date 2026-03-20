import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/history/data/models/order_history.dart';

void main() {
  group('OrderHistory.fromApiJson', () {
    test('parses full API response correctly', () {
      final json = _fullApiResponse();
      final order = OrderHistory.fromApiJson(json);

      expect(order.id, 42);
      expect(order.noSp, 'SP-001');
      expect(order.orderDate, '2026-03-10');
      expect(order.requestDate, '2026-03-15');
      expect(order.customerName, 'John Doe');
      expect(order.phone, '081234567890');
      expect(order.address, 'Jl. Test No. 1');
      expect(order.email, 'john@test.com');
      expect(order.isTakeAway, false);
      expect(order.totalAmount, 5000000.0);
      expect(order.postage, 100000.0);
      expect(order.status, 'Pending');
      expect(order.details, hasLength(2));
      expect(order.payments, hasLength(1));
    });

    test('handles missing order_letter by using root json', () {
      final json = <String, dynamic>{
        'id': 10,
        'no_sp': 'SP-FLAT',
        'order_date': '2026-01-01',
        'request_date': '-',
        'note': '',
        'customer_name': 'Flat User',
        'phone': '0',
        'address': '-',
        'email': '',
        'extended_amount': 0,
        'status': 'Approved',
        'order_letter_details': <dynamic>[],
        'order_letter_payments': <dynamic>[],
      };

      final order = OrderHistory.fromApiJson(json);
      expect(order.id, 10);
      expect(order.noSp, 'SP-FLAT');
      expect(order.customerName, 'Flat User');
      expect(order.status, 'Approved');
    });

    test('totalAmount parses String values correctly', () {
      final json = <String, dynamic>{
        'order_letter': {
          'id': 1,
          'no_sp': 'X',
          'order_date': '-',
          'request_date': '-',
          'note': '',
          'customer_name': 'A',
          'phone': '-',
          'address': '-',
          'email': '',
          'extended_amount': '14000000.0',
          'postage': '250000',
          'status': 'Pending',
        },
        'order_letter_details': <dynamic>[],
        'order_letter_payments': <dynamic>[],
      };

      final order = OrderHistory.fromApiJson(json);
      expect(order.totalAmount, 14000000.0);
      expect(order.postage, 250000.0);
    });

    test('isTakeAway parses "TAKE AWAY" string', () {
      final json = <String, dynamic>{
        'order_letter': {
          'id': 1,
          'no_sp': 'X',
          'order_date': '-',
          'request_date': '-',
          'note': '',
          'customer_name': 'A',
          'phone': '-',
          'address': '-',
          'extended_amount': 0,
          'status': 'P',
          'take_away': 'TAKE AWAY',
        },
        'order_letter_details': <dynamic>[],
        'order_letter_payments': <dynamic>[],
      };

      final order = OrderHistory.fromApiJson(json);
      expect(order.isTakeAway, true);
    });

    test('isTakeAway parses boolean true', () {
      final json = <String, dynamic>{
        'order_letter': {
          'id': 1,
          'no_sp': 'X',
          'order_date': '-',
          'request_date': '-',
          'note': '',
          'customer_name': 'A',
          'phone': '-',
          'address': '-',
          'extended_amount': 0,
          'status': 'P',
          'take_away': true,
        },
        'order_letter_details': <dynamic>[],
        'order_letter_payments': <dynamic>[],
      };

      final order = OrderHistory.fromApiJson(json);
      expect(order.isTakeAway, true);
    });

    test('isTakeAway defaults to false for null', () {
      final json = <String, dynamic>{
        'order_letter': {
          'id': 1,
          'no_sp': 'X',
          'order_date': '-',
          'request_date': '-',
          'note': '',
          'customer_name': 'A',
          'phone': '-',
          'address': '-',
          'extended_amount': 0,
          'status': 'P',
        },
        'order_letter_details': <dynamic>[],
        'order_letter_payments': <dynamic>[],
      };

      final order = OrderHistory.fromApiJson(json);
      expect(order.isTakeAway, false);
    });

    test('propagates noSp to detail items', () {
      final json = <String, dynamic>{
        'order_letter': {
          'id': 1,
          'no_sp': 'SP-PARENT',
          'order_date': '-',
          'request_date': '-',
          'note': '',
          'customer_name': 'A',
          'phone': '-',
          'address': '-',
          'extended_amount': 0,
          'status': 'P',
        },
        'order_letter_details': <dynamic>[
          {
            'id': 10,
            'item_description': 'Kasur',
            'desc_1': 'Spring Air',
            'item_type': 'Kasur',
            'qty': 1,
            'customer_price': 1000000,
            'net_price': 900000,
            'brand': 'SA',
            'unit_price': 1000000,
          },
        ],
        'order_letter_payments': <dynamic>[],
      };

      final order = OrderHistory.fromApiJson(json);
      expect(order.details.first.noSp, 'SP-PARENT');
    });

    test('createdAt parses valid ISO string', () {
      final json = <String, dynamic>{
        'order_letter': {
          'id': 1,
          'no_sp': 'X',
          'order_date': '-',
          'request_date': '-',
          'note': '',
          'customer_name': 'A',
          'phone': '-',
          'address': '-',
          'extended_amount': 0,
          'status': 'P',
          'created_at': '2026-03-10T10:30:00.000Z',
        },
        'order_letter_details': <dynamic>[],
        'order_letter_payments': <dynamic>[],
      };

      final order = OrderHistory.fromApiJson(json);
      expect(order.createdAt, isNotNull);
      expect(order.createdAt!.year, 2026);
    });
  });

  group('OrderHistoryX extension', () {
    test('mainItemsCount and bonusItemsCount', () {
      final order = _orderWithDetails([
        _detail(id: 1, type: 'Kasur'),
        _detail(id: 2, type: 'Divan'),
        _detail(id: 3, type: 'Bonus'),
        _detail(id: 4, type: 'bonus'),
      ]);

      expect(order.mainItemsCount, 2);
      expect(order.bonusItemsCount, 2);
    });

    test('firstItemName returns first non-bonus detail', () {
      final order = _orderWithDetails([
        _detail(id: 1, type: 'Bonus', desc1: 'Bantal'),
        _detail(id: 2, type: 'Kasur', desc1: 'Spring Air Grand'),
      ]);

      expect(order.firstItemName, 'Spring Air Grand');
    });

    test('firstItemName returns Pesanan when no main items', () {
      final order = _orderWithDetails([
        _detail(id: 1, type: 'Bonus', desc1: 'Bantal'),
      ]);

      expect(order.firstItemName, 'Pesanan');
    });

    test('mainItems sorted by id', () {
      final order = _orderWithDetails([
        _detail(id: 3, type: 'Kasur', desc1: 'C'),
        _detail(id: 1, type: 'Divan', desc1: 'A'),
        _detail(id: 2, type: 'Bonus', desc1: 'B'),
      ]);

      final mains = order.mainItems;
      expect(mains, hasLength(2));
      expect(mains[0].id, 1);
      expect(mains[1].id, 3);
    });
  });

  group('OrderDetail.fromApiJson', () {
    test('parses all fields', () {
      final json = <String, dynamic>{
        'order_letter_detail_id': 99,
        'no_sp': 'SP-1',
        'item_description': 'Kasur Spring Air',
        'desc_1': 'Grand Royal',
        'item_type': 'Kasur',
        'qty': 2,
        'customer_price': '5000000.0',
        'net_price': 4500000,
        'brand': 'SA',
        'unit_price': 5000000,
        'extended_price': 9000000,
        'order_letter_discount': <dynamic>[],
      };

      final detail = OrderDetail.fromApiJson(json);
      expect(detail.id, 99);
      expect(detail.noSp, 'SP-1');
      expect(detail.desc1, 'Grand Royal');
      expect(detail.qty, 2);
      expect(detail.customerPrice, 5000000.0);
      expect(detail.netPrice, 4500000.0);
      expect(detail.extendedPrice, 9000000.0);
    });

    test('computes extendedPrice when zero in json', () {
      final json = <String, dynamic>{
        'id': 10,
        'item_description': 'Test',
        'desc_1': 'Test',
        'item_type': 'Kasur',
        'qty': 3,
        'customer_price': 1000,
        'net_price': 900,
        'brand': 'X',
        'unit_price': 1000,
        'extended_price': 0,
      };

      final detail = OrderDetail.fromApiJson(json);
      expect(detail.extendedPrice, 3000.0);
    });

    test('parses discounts', () {
      final json = <String, dynamic>{
        'id': 1,
        'item_description': 'Test',
        'desc_1': 'Test',
        'item_type': 'Kasur',
        'qty': 1,
        'customer_price': 0,
        'net_price': 0,
        'brand': '',
        'unit_price': 0,
        'order_letter_discount': <dynamic>[
          {
            'order_letter_discount_id': 5,
            'discount': '10',
            'approver_name': 'SPV',
            'approver_level': 'spv',
            'approved': 'Approved',
          },
        ],
      };

      final detail = OrderDetail.fromApiJson(json);
      expect(detail.discounts, hasLength(1));
      expect(detail.discounts.first.discountVal, '10');
      expect(detail.discounts.first.approverName, 'SPV');
    });
  });

  group('OrderPayment.fromApiJson', () {
    test('parses all fields', () {
      final json = <String, dynamic>{
        'payment_method': 'Transfer',
        'payment_bank': 'BCA',
        'payment_amount': '2500000.0',
        'image': 'https://example.com/receipt.jpg',
        'payment_date': '2026-03-10',
        'created_at': '2026-03-10T10:00:00Z',
      };

      final payment = OrderPayment.fromApiJson(json);
      expect(payment.method, 'Transfer');
      expect(payment.bank, 'BCA');
      expect(payment.amount, 2500000.0);
      expect(payment.image, 'https://example.com/receipt.jpg');
      expect(payment.paymentDate, '2026-03-10');
    });

    test('handles null values with defaults', () {
      final payment = OrderPayment.fromApiJson(const <String, dynamic>{});
      expect(payment.method, '-');
      expect(payment.bank, '-');
      expect(payment.amount, 0.0);
      expect(payment.image, '');
    });
  });

  group('OrderDiscount.fromApiJson', () {
    test('parses all fields', () {
      final json = <String, dynamic>{
        'order_letter_discount_id': 7,
        'discount': '15.5',
        'approver_name': 'Manager A',
        'approver_level': 'manager',
        'approved': 'Approved',
        'approved_at': '2026-03-10T12:00:00Z',
      };

      final disc = OrderDiscount.fromApiJson(json);
      expect(disc.id, 7);
      expect(disc.discountVal, '15.5');
      expect(disc.approverName, 'Manager A');
      expect(disc.approverLevel, 'manager');
      expect(disc.approvedStatus, 'Approved');
      expect(disc.approvedAt, '2026-03-10T12:00:00Z');
    });

    test('handles null values with defaults', () {
      final disc = OrderDiscount.fromApiJson(const <String, dynamic>{});
      expect(disc.id, 0);
      expect(disc.discountVal, '0');
      expect(disc.approverName, '-');
    });
  });
}

// ── Helpers ──────────────────────────────────────────────────────

Map<String, dynamic> _fullApiResponse() => {
      'order_letter': {
        'id': 42,
        'no_sp': 'SP-001',
        'order_date': '2026-03-10',
        'request_date': '2026-03-15',
        'note': 'Urgent',
        'customer_name': 'John Doe',
        'phone': '081234567890',
        'address': 'Jl. Test No. 1',
        'email': 'john@test.com',
        'take_away': false,
        'extended_amount': 5000000,
        'postage': 100000,
        'status': 'Pending',
        'creator': '1',
        'creator_name': 'Admin',
        'sales_code': 'SC-01',
        'sales_name': 'Sales A',
        'created_at': '2026-03-10T08:00:00Z',
      },
      'work_place_name': 'Sleep Center Intercon',
      'company_name': 'PT Massindo',
      'order_letter_details': <dynamic>[
        {
          'order_letter_detail_id': 100,
          'item_description': 'Kasur SA',
          'desc_1': 'Grand Royal',
          'item_type': 'Kasur',
          'qty': 1,
          'customer_price': 3000000,
          'net_price': 2800000,
          'brand': 'SA',
          'unit_price': 3000000,
          'extended_price': 3000000,
          'order_letter_discount': <dynamic>[],
        },
        {
          'order_letter_detail_id': 101,
          'item_description': 'Bantal',
          'desc_1': 'Bantal Bonus',
          'item_type': 'Bonus',
          'qty': 2,
          'customer_price': 0,
          'net_price': 0,
          'brand': 'SA',
          'unit_price': 0,
          'extended_price': 0,
          'order_letter_discount': <dynamic>[],
        },
      ],
      'order_letter_payments': <dynamic>[
        {
          'payment_method': 'Transfer',
          'payment_bank': 'BCA',
          'payment_amount': 5000000,
          'image': 'receipt.jpg',
          'payment_date': '2026-03-10',
          'created_at': '2026-03-10T10:00:00Z',
        },
      ],
    };

OrderHistory _orderWithDetails(List<OrderDetail> details) => OrderHistory(
      id: 1,
      noSp: 'SP-T',
      orderDate: '-',
      requestDate: '-',
      note: '',
      customerName: 'Test',
      phone: '-',
      address: '-',
      email: '',
      isTakeAway: false,
      workPlaceName: '-',
      companyName: '-',
      totalAmount: 0,
      status: 'Pending',
      details: details,
    );

OrderDetail _detail({
  required int id,
  required String type,
  String desc1 = 'Item',
}) =>
    OrderDetail(
      id: id,
      itemDescription: desc1,
      desc1: desc1,
      itemType: type,
      qty: 1,
      customerPrice: 0,
      netPrice: 0,
      brand: '',
      unitPrice: 0,
    );
