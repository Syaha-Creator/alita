import '../entities/item_lookup_entity.dart';

abstract class ItemLookupRepository {
  Future<List<ItemLookupEntity>> fetchItemLookups();
}
