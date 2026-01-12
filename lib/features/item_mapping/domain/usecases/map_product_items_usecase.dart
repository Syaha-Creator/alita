import '../repositories/item_mapping_repository.dart';
import '../entities/product_item_mapping_entity.dart';
import '../../../product/domain/entities/product_entity.dart';

/// Use case untuk map product items
class MapProductItemsUseCase {
  final ItemMappingRepository repository;

  MapProductItemsUseCase(this.repository);

  Future<ProductItemMappingEntity> call(ProductEntity product) async {
    return await repository.mapProductItems(product);
  }
}
