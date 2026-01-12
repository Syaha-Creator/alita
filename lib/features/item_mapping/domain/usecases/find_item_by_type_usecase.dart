import '../repositories/item_mapping_repository.dart';
import '../../../product/domain/entities/item_lookup_entity.dart';

/// Use case untuk find item by type
class FindItemByTypeUseCase {
  final ItemMappingRepository repository;

  FindItemByTypeUseCase(this.repository);

  Future<ItemLookupEntity?> call(String itemName) async {
    return await repository.findItemByType(itemName);
  }
}
