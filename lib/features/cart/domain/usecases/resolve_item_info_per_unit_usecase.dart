import 'package:flutter/foundation.dart';

import '../entities/cart_entity.dart';
import 'resolve_item_info_usecase.dart';

/// Use case untuk resolve per-unit item info (number + description) jika available
class ResolveItemInfoPerUnitUseCase {
  final ResolveItemInfoUseCase _resolveItemInfoUseCase;

  ResolveItemInfoPerUnitUseCase(this._resolveItemInfoUseCase);

  Future<List<Map<String, String?>>> call({
    required CartEntity item,
    required String itemType,
  }) async {
    final qty = item.quantity;
    if (kDebugMode) {
      print(
          '[ResolveItemInfoPerUnitUseCase] type=$itemType, qty=$qty');
    }

    // If per-unit selections exist, use them with item_description from selection
    final perUnit = item.selectedItemNumbersPerUnit?[itemType];
    if (perUnit != null && perUnit.isNotEmpty) {
      final List<Map<String, String?>> results = [];
      for (int i = 0; i < qty; i++) {
        final sel = i < perUnit.length ? perUnit[i] : null;
        final numSel = sel != null ? (sel['item_number'] ?? '') : '';
        final descSel =
            sel != null ? sel['item_description']?.toString() : null;
        if (numSel.isNotEmpty) {
          results.add({
            'item_number': numSel,
            'item_description': descSel,
          });
        } else {
          // fallback per-unit to lookup resolution
          results.add(await _resolveItemInfoUseCase(
            item: item,
            itemType: itemType,
          ));
        }
      }
      if (kDebugMode) {
        print(
            '[ResolveItemInfoPerUnitUseCase] per-unit info for $itemType => $results');
      }
      return results;
    }

    // No per-unit selections; get single info from lookup and reuse
    final info = await _resolveItemInfoUseCase(
      item: item,
      itemType: itemType,
    );
    final all = List<Map<String, String?>>.filled(qty, info);
    if (kDebugMode) {
      print(
          '[ResolveItemInfoPerUnitUseCase] single info for $itemType => $info (reused x$qty)');
    }
    return all;
  }
}

