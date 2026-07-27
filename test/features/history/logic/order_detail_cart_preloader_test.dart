import 'package:alitapricelist/features/history/data/models/order_history.dart';
import 'package:alitapricelist/features/history/logic/order_detail_cart_preloader.dart';
import 'package:flutter_test/flutter_test.dart';

OrderHistory _orderWith({
  required String itemType,
  required String pricelistType,
  required String pricelistArea,
}) {
  return OrderHistory.fromApiJson({
    'order_letter': {
      'id': 1,
      'no_sp': 'SP-001',
      'order_date': '2026-01-01',
      'request_date': '-',
      'note': '',
      'customer_name': 'A',
      'phone': '-',
      'address': '-',
      'email': '',
      'extended_amount': 1000000,
      'status': 'Approved',
      'channel': 'S1',
    },
    'order_letter_details': [
      {
        'order_letter_detail_id': 1,
        'desc_1': 'Kasur Bulan Purnama',
        'desc_2': '160x200',
        'item_description': 'Kasur Bulan Purnama',
        'item_type': itemType,
        'qty': 1,
        'customer_price': 1000000,
        'net_price': 900000,
        'brand': 'Comforta',
        'unit_price': 1000000,
        'pricelist_type': pricelistType,
        'pricelist_area': pricelistArea,
      },
    ],
    'order_letter_payments': <dynamic>[],
  });
}

void main() {
  group('OrderDetailCartPreloader.convert — pricelist_area passthrough', () {
    test(
      'propagates pricelist_area from order detail into the preloaded '
      'CartItem (regression: previously hardcoded to empty)',
      () {
        final order = _orderWith(
          itemType: 'Mattress',
          pricelistType: 'Regular',
          pricelistArea: 'Medan',
        );

        final items = OrderDetailCartPreloader.convert(order);

        expect(items, hasLength(1));
        expect(items.first.pricelistArea, 'Medan');
        expect(items.first.product.channel, 'Regular');
      },
    );

    test('defaults to empty when API omits pricelist_area', () {
      final order = _orderWith(
        itemType: 'Mattress',
        pricelistType: '',
        pricelistArea: '',
      );

      final items = OrderDetailCartPreloader.convert(order);

      expect(items.first.pricelistArea, '');
    });
  });
}
