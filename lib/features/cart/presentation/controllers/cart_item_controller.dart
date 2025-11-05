import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/fabric_lookup_usecase.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/cart_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

class CartItemController {
  final FabricLookupUsecase _lookup;

  CartItemController({FabricLookupUsecase? lookup})
      : _lookup = lookup ?? FabricLookupUsecase();
  bool isNoneComponent(String value) {
    final v = (value).trim().toLowerCase();
    if (v.isEmpty) return true;
    if (v == '-' || v == 'n/a') return true;
    if (v.contains('tidak ada')) return true;
    if (v.contains('tanpa')) return true;
    return false;
  }

  Future<void> autoSelectFabricDefaults(BuildContext context, CartEntity item,
      {required bool Function() mounted}) async {
    final product = item.product;
    final cartBloc = context.read<CartBloc>();

    Future<void> tryAuto(String itemType, bool enabled) async {
      if (!enabled) return;
      if (item.selectedItemNumbers != null &&
          item.selectedItemNumbers![itemType] != null) {
        return;
      }
      String tipeForLookup;
      switch (itemType) {
        case 'divan':
          tipeForLookup = product.divan;
          break;
        case 'headboard':
          tipeForLookup = product.headboard;
          break;
        case 'sorong':
          tipeForLookup = product.sorong;
          break;
        case 'kasur':
        default:
          tipeForLookup = product.kasur;
      }
      final list = await _lookup.fetchByContext(
          brand: product.brand,
          kasur: tipeForLookup,
          divan: product.divan.isNotEmpty ? product.divan : null,
          headboard: product.headboard.isNotEmpty ? product.headboard : null,
          sorong: product.sorong.isNotEmpty ? product.sorong : null,
          ukuran: product.ukuran,
          contextItemType: itemType);
      if (list.length == 1) {
        final it = list.first;
        if (!mounted()) return;
        final qty = item.quantity;
        for (int idx = 0; idx < qty; idx++) {
          if (!mounted()) break;
          cartBloc.add(UpdateCartSelectedItemNumber(
            productId: product.id,
            netPrice: item.netPrice,
            itemType: itemType,
            itemNumber: it.itemNumber,
            jenisKain: it.fabricType,
            warnaKain: it.fabricColor,
            unitIndex: idx,
            cartLineId: item.cartLineId,
          ));
        }
      }
    }

    await Future.wait([
      tryAuto('kasur', !isNoneComponent(product.kasur)),
      tryAuto('divan', !isNoneComponent(product.divan)),
      tryAuto('headboard', !isNoneComponent(product.headboard)),
      tryAuto('sorong', !isNoneComponent(product.sorong)),
    ]);
  }

  Future<void> autoFillNewUnitsIfSingleOption(
      BuildContext context, CartEntity item,
      {required String itemType,
      required String tipeForLookup,
      required bool Function() mounted}) async {
    final product = item.product;
    final cartBloc = context.read<CartBloc>();
    final perUnit = item.selectedItemNumbersPerUnit?[itemType] ?? const [];
    final list = await _lookup.fetchByContext(
        brand: product.brand,
        kasur: tipeForLookup,
        divan: product.divan.isNotEmpty ? product.divan : null,
        headboard: product.headboard.isNotEmpty ? product.headboard : null,
        sorong: product.sorong.isNotEmpty ? product.sorong : null,
        ukuran: product.ukuran,
        contextItemType: itemType);
    if (list.length == 1) {
      final it = list.first;
      if (!mounted()) return;
      for (int idx = 0; idx < item.quantity; idx++) {
        final sel = idx < perUnit.length ? perUnit[idx] : null;
        final already =
            sel != null && (sel['item_number'] ?? '').toString().isNotEmpty;
        if (already) continue;
        if (!mounted()) break;
        cartBloc.add(UpdateCartSelectedItemNumber(
          productId: product.id,
          netPrice: item.netPrice,
          itemType: itemType,
          itemNumber: it.itemNumber,
          jenisKain: it.fabricType,
          warnaKain: it.fabricColor,
          unitIndex: idx,
          cartLineId: item.cartLineId,
        ));
      }
    }
  }

  Future<List<String>> getSorongOptions(
      ProductEntity product, Future<List<String>> Function() fetch) async {
    return await fetch();
  }
}
