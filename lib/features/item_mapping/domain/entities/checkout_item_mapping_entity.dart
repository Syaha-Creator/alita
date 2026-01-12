import 'product_item_mapping_entity.dart';

/// Entity untuk checkout item mapping
/// Representasi mapping untuk semua products dalam checkout
class CheckoutItemMappingEntity {
  final List<ProductItemMappingEntity> productMappings;
  final int totalProducts;

  const CheckoutItemMappingEntity({
    required this.productMappings,
    required this.totalProducts,
  });

  /// Cek apakah semua item sudah ter-mapping
  bool get allItemsMapped {
    return productMappings.every((mapping) => !mapping.hasUnmappedItems);
  }

  /// Dapatkan total item yang tidak ter-mapping
  int get totalUnmappedItems {
    return productMappings.fold(
      0,
      (total, mapping) => total + mapping.unmappedItems.length,
    );
  }
}

