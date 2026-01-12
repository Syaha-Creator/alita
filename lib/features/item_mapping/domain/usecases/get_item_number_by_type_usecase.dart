import '../repositories/item_mapping_repository.dart';

/// Use case untuk get item number by type
class GetItemNumberByTypeUseCase {
  final ItemMappingRepository repository;

  GetItemNumberByTypeUseCase(this.repository);

  Future<String?> call(String itemName) async {
    return await repository.getItemNumberByType(itemName);
  }
}
