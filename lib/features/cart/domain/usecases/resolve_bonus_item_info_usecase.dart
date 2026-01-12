import '../../../../config/dependency_injection.dart';
import '../../../../core/utils/error_logger.dart';
import '../../../product/domain/usecases/fetch_lookup_items_usecase.dart';
import '../entities/cart_entity.dart';

/// Use case untuk resolve bonus item number dan description
class ResolveBonusItemInfoUseCase {
  final FetchLookupItemsUseCase _fetchLookupItemsUseCase;

  ResolveBonusItemInfoUseCase({
    FetchLookupItemsUseCase? fetchLookupItemsUseCase,
  }) : _fetchLookupItemsUseCase =
            fetchLookupItemsUseCase ?? locator<FetchLookupItemsUseCase>();

  Future<Map<String, String?>> call({
    required CartEntity item,
    required String bonusName,
    String? bonusItemNumber,
  }) async {
    bool isInvalidItemNum(String? v) {
      if (v == null) return true;
      final s = v.trim();
      return s.isEmpty || s == '0' || s == '0.0';
    }

    // Resolve missing/invalid bonus item number via lookup by type (bonus name)
    String resolvedBonusNumber = bonusItemNumber ?? '';
    String? resolvedBonusDescription;
    if (isInvalidItemNum(resolvedBonusNumber)) {
            try {
              final list = await _fetchLookupItemsUseCase(
                brand: item.product.brand,
                kasur: bonusName, // treat bonus name as 'tipe'
                ukuran: item.product.ukuran,
              );
              // Prefer entries that clearly match bonus by description and brand
              String norm(String s) => s.toLowerCase().trim();
              final normBonus = norm(bonusName);
              final normBrand = norm(item.product.brand.split(' - ').first);
              bool descMatches(String? d) {
                final desc = norm(d ?? '');
                // All words in bonus name should appear in desc
                final tokens = normBonus.split(RegExp(r"\s+"));
                return tokens.every((t) => t.isEmpty || desc.contains(t));
              }

              final filtered = list.where((e) {
                final brandOk = norm(e.brand) == normBrand;
                final descOk = descMatches(e.itemDesc);
                return descOk && brandOk && !isInvalidItemNum(e.itemNum);
              }).toList();
              if (filtered.isNotEmpty) {
                resolvedBonusNumber = filtered.first.itemNum;
                resolvedBonusDescription = filtered.first.itemDesc;
              } else if (list.isNotEmpty &&
                  !isInvalidItemNum(list.first.itemNum)) {
                // fallback to first valid from API
                resolvedBonusNumber = list.first.itemNum;
                resolvedBonusDescription = list.first.itemDesc;
              } else {
                resolvedBonusNumber = item.product.id.toString();
              }
            } catch (e, stackTrace) {
              await ErrorLogger.logError(
                e,
                stackTrace: stackTrace,
                context: 'Failed to resolve bonus item info',
                extra: {
                  'productId': item.product.id,
                  'bonusItemNumber': bonusItemNumber,
                },
                fatal: false,
              );
              resolvedBonusNumber = item.product.id.toString();
            }
    }

    return {
      'item_number': resolvedBonusNumber,
      'item_description': resolvedBonusDescription,
    };
  }
}

