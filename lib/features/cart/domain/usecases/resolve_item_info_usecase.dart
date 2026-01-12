import 'package:flutter/foundation.dart';

import '../../../../config/dependency_injection.dart';
import '../../../product/domain/usecases/fetch_lookup_items_usecase.dart';
import '../entities/cart_entity.dart';

/// Use case untuk resolve item number dan item description menggunakan lookup service
class ResolveItemInfoUseCase {
  final FetchLookupItemsUseCase _fetchLookupItemsUseCase;

  ResolveItemInfoUseCase({
    FetchLookupItemsUseCase? fetchLookupItemsUseCase,
  }) : _fetchLookupItemsUseCase =
            fetchLookupItemsUseCase ?? locator<FetchLookupItemsUseCase>();

  Future<Map<String, String?>> call({
    required CartEntity item,
    required String itemType,
  }) async {
    if (kDebugMode) {
      print(
          '[ResolveItemInfoUseCase] type=$itemType, brand=${item.product.brand}');
    }

    // Check for prefilled item number first
    String? prefilled;
    switch (itemType) {
      case 'kasur':
        prefilled = item.product.itemNumberKasur ?? item.product.itemNumber;
        break;
      case 'divan':
        prefilled = item.product.itemNumberDivan;
        break;
      case 'headboard':
        prefilled = item.product.itemNumberHeadboard;
        break;
      case 'sorong':
        prefilled = item.product.itemNumberSorong;
        break;
    }

    // Helper to check invalid item number
    bool isInvalid(String? s) =>
        s == null ||
        s.isEmpty ||
        s == '0' ||
        s == 'null' ||
        s.toLowerCase() == 'undefined';

    try {
      final list = await _fetchLookupItemsUseCase(
        brand: item.product.brand,
        kasur: item.product.kasur,
        divan: item.product.divan.isNotEmpty ? item.product.divan : null,
        headboard:
            item.product.headboard.isNotEmpty ? item.product.headboard : null,
        sorong: item.product.sorong.isNotEmpty ? item.product.sorong : null,
        ukuran: item.product.ukuran,
        contextItemType: itemType,
      );

      if (list.isNotEmpty) {
        final lookupItem = list.first;
        return {
          'item_number': !isInvalid(prefilled)
              ? prefilled
              : (!isInvalid(lookupItem.itemNum)
                  ? lookupItem.itemNum
                  : item.product.id.toString()),
          'item_description': lookupItem.itemDesc,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            '[ResolveItemInfoUseCase] Error fetching lookup for $itemType: $e');
      }
    }

    return {
      'item_number':
          !isInvalid(prefilled) ? prefilled : item.product.id.toString(),
      'item_description': null,
    };
  }
}
