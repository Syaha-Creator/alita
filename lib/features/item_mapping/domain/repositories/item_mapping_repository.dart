import '../../../product/domain/entities/item_lookup_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../entities/checkout_item_mapping_entity.dart';
import '../entities/product_item_mapping_entity.dart';

/// Repository interface untuk item mapping operations
abstract class ItemMappingRepository {
  /// Cari item lookup berdasarkan nama item (tipe)
  Future<ItemLookupEntity?> findItemByType(String itemName);

  /// Dapatkan item_num berdasarkan nama item
  Future<String?> getItemNumberByType(String itemName);

  /// Mapping semua item dari product ke item lookup
  Future<ProductItemMappingEntity> mapProductItems(ProductEntity product);

  /// Mapping untuk checkout - ganti semua item_number dengan yang dari lookup
  Future<CheckoutItemMappingEntity> mapCheckoutItems(
    List<ProductEntity> products,
  );

  /// Clear cache
  void clearCache();
}

