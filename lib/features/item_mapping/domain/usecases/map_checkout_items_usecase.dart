import '../repositories/item_mapping_repository.dart';
import '../entities/checkout_item_mapping_entity.dart';
import '../../../product/domain/entities/product_entity.dart';

/// Use case untuk map checkout items
class MapCheckoutItemsUseCase {
  final ItemMappingRepository repository;

  MapCheckoutItemsUseCase(this.repository);

  Future<CheckoutItemMappingEntity> call(List<ProductEntity> products) async {
    return await repository.mapCheckoutItems(products);
  }
}
