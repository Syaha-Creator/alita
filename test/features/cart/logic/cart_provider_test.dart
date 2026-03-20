import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/features/cart/logic/cart_provider.dart';
import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';

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

CartItem _item({String id = '1', double price = 1000, int qty = 1}) =>
    CartItem(product: _product(id: id, price: price), quantity: qty);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('cartItemKey', () {
    test('combines product id and SKUs', () {
      final item = CartItem(
        product: _product(),
        kasurSku: 'K1',
        divanSku: 'D1',
        sandaranSku: 'S1',
        sorongSku: 'SR1',
      );
      expect(cartItemKey(item), '1|K1|D1|S1|SR1');
    });

    test('empty SKUs produce pipe-only suffix', () {
      final item = CartItem(product: _product());
      expect(cartItemKey(item), '1||||');
    });
  });

  group('CartNotifier', () {
    late CartNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifier = CartNotifier();
    });

    test('starts with empty state', () {
      expect(notifier.state, isEmpty);
    });

    test('addItem adds product to cart', () async {
      await notifier.addItem(_item());
      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.product.id, '1');
    });

    test('addItem merges same product+SKU by incrementing qty', () async {
      await notifier.addItem(_item(qty: 1));
      await notifier.addItem(_item(qty: 2));
      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.quantity, 3);
    });

    test('addItem keeps separate lines for different products', () async {
      await notifier.addItem(_item(id: '1'));
      await notifier.addItem(_item(id: '2'));
      expect(notifier.state, hasLength(2));
    });

    test('addItem keeps separate lines for same product different SKUs',
        () async {
      await notifier.addItem(CartItem(
        product: _product(),
        kasurSku: 'A',
      ));
      await notifier.addItem(CartItem(
        product: _product(),
        kasurSku: 'B',
      ));
      expect(notifier.state, hasLength(2));
    });

    test('removeItemAt removes correct index', () async {
      await notifier.addItem(_item(id: '1'));
      await notifier.addItem(_item(id: '2'));
      await notifier.removeItemAt(0);
      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.product.id, '2');
    });

    test('removeItemAt ignores out-of-bounds index', () async {
      await notifier.addItem(_item());
      await notifier.removeItemAt(5);
      expect(notifier.state, hasLength(1));
    });

    test('removeItem removes by productId', () async {
      await notifier.addItem(_item(id: '1'));
      await notifier.addItem(_item(id: '2'));
      await notifier.removeItem('1');
      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.product.id, '2');
    });

    test('incrementItem increases quantity', () async {
      await notifier.addItem(_item(qty: 1));
      await notifier.incrementItem(0);
      expect(notifier.state.first.quantity, 2);
    });

    test('decrementItem decreases quantity', () async {
      await notifier.addItem(_item(qty: 3));
      await notifier.decrementItem(0);
      expect(notifier.state.first.quantity, 2);
    });

    test('decrementItem removes at qty 1', () async {
      await notifier.addItem(_item(qty: 1));
      await notifier.decrementItem(0);
      expect(notifier.state, isEmpty);
    });

    test('updateCartItem replaces snapshot keeping original qty', () async {
      await notifier.addItem(_item(id: '1', qty: 3));
      final updated = _item(id: '1', price: 9999, qty: 1);
      await notifier.updateCartItem(0, updated);
      expect(notifier.state.first.product.price, 9999);
      expect(notifier.state.first.quantity, 3);
    });

    test('clearCart empties state', () async {
      await notifier.addItem(_item(id: '1'));
      await notifier.addItem(_item(id: '2'));
      await notifier.clearCart();
      expect(notifier.state, isEmpty);
    });

    test('removeItemsByIds removes selected lines', () async {
      final i1 = _item(id: '1');
      final i2 = _item(id: '2');
      await notifier.addItem(i1);
      await notifier.addItem(i2);
      await notifier.removeItemsByIds({cartItemKey(i1)});
      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.product.id, '2');
    });

    test('totalItems sums quantities', () async {
      await notifier.addItem(_item(id: '1', qty: 2));
      await notifier.addItem(_item(id: '2', qty: 3));
      expect(notifier.totalItems, 5);
    });

    test('totalAmount sums price * qty', () async {
      await notifier.addItem(_item(id: '1', price: 100, qty: 2));
      await notifier.addItem(_item(id: '2', price: 300, qty: 1));
      expect(notifier.totalAmount, 500);
    });
  });
}
