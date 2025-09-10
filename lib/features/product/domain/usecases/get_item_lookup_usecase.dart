import '../entities/item_lookup_entity.dart';
import '../repositories/item_lookup_repository.dart';

class GetItemLookupUsecase {
  final ItemLookupRepository repository;

  GetItemLookupUsecase({required this.repository});

  Future<List<ItemLookupEntity>> call() async {
    try {
      return await repository.fetchItemLookups();
    } catch (e) {
      rethrow;
    }
  }
}
