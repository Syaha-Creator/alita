import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/checkout/data/models/store_model.dart';
import 'package:alitapricelist/features/checkout/data/utils/indirect_store_match.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';

Product _product() => const Product(
      id: '1',
      name: 'P',
      price: 1,
      imageUrl: '',
      category: 'C',
      kasur: 'K',
      ukuran: '160',
      divan: '',
      headboard: '',
      sorong: '',
      isSet: false,
      pricelist: 1,
      eupKasur: 1,
      eupDivan: 0,
      eupHeadboard: 0,
      eupSorong: 0,
      plKasur: 1,
      plDivan: 0,
      plHeadboard: 0,
      plSorong: 0,
    );

void main() {
  group('matchWorkPlaceForIndirectCartLine', () {
    test('returns null when not indirect', () {
      final item = CartItem(product: _product());
      final stores = [const StoreModel(id: 1, name: 'A')];
      expect(matchWorkPlaceForIndirectCartLine(stores, item), isNull);
    });

    test('matches store name after stripping parenthetical alpha_name', () {
      final item = CartItem(
        product: _product(),
        indirectStoreAddressNumber: 10,
        indirectStoreAlphaName: '57 SEJAHTERA (SA - REG)',
      );
      final stores = [
        const StoreModel(id: 139, name: '57 SEJAHTERA'),
      ];
      expect(matchWorkPlaceForIndirectCartLine(stores, item)?.id, 139);
    });
  });
}
