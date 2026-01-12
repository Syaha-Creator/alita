import '../entities/item_lookup_entity.dart';

abstract class ItemLookupRepository {
  Future<List<ItemLookupEntity>> fetchItemLookups();

  /// Fetch available item numbers (and fabric choices) for the given variant
  Future<List<ItemLookupEntity>> fetchLookupItems({
    required String brand,
    required String kasur,
    String? divan,
    String? headboard,
    String? sorong,
    required String ukuran,
    String? contextItemType,
  });
}
