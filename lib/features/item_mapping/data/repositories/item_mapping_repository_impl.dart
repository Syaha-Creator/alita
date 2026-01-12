import 'package:flutter/foundation.dart';

import '../../../product/domain/entities/item_lookup_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/usecases/get_item_lookup_usecase.dart';
import '../../domain/entities/checkout_item_mapping_entity.dart';
import '../../domain/entities/product_item_mapping_entity.dart';
import '../../domain/repositories/item_mapping_repository.dart';

/// Repository implementation untuk item mapping
class ItemMappingRepositoryImpl implements ItemMappingRepository {
  final GetItemLookupUsecase _getItemLookupUsecase;
  List<ItemLookupEntity>? _cachedItemLookups;

  ItemMappingRepositoryImpl({
    required GetItemLookupUsecase getItemLookupUsecase,
  }) : _getItemLookupUsecase = getItemLookupUsecase;

  /// Load dan cache item lookups
  Future<void> _loadItemLookups() async {
    if (_cachedItemLookups == null) {
      try {
        _cachedItemLookups = await _getItemLookupUsecase();
      } catch (e) {
        if (kDebugMode) {
          print('Error loading item lookups: $e');
        }
        _cachedItemLookups = [];
      }
    }
  }

  @override
  Future<ItemLookupEntity?> findItemByType(String itemName) async {
    if (itemName.isEmpty) return null;

    await _loadItemLookups();

    try {
      return _cachedItemLookups?.firstWhere(
        (item) =>
            item.tipe.toLowerCase().trim() == itemName.toLowerCase().trim(),
        orElse: () => throw StateError('Item not found'),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getItemNumberByType(String itemName) async {
    final item = await findItemByType(itemName);
    return item?.itemNum;
  }

  @override
  Future<ProductItemMappingEntity> mapProductItems(
    ProductEntity product,
  ) async {
    await _loadItemLookups();

    // Mapping kasur
    final kasurItemNumber = await getItemNumberByType(product.kasur);

    // Mapping divan
    final divanItemNumber = await getItemNumberByType(product.divan);

    // Mapping headboard
    final headboardItemNumber = await getItemNumberByType(product.headboard);

    // Mapping sorong
    final sorongItemNumber = await getItemNumberByType(product.sorong);

    // Mapping accessories (jika ada)
    String? accessoriesItemNumber;
    if (product.itemNumberAccessories != null &&
        product.itemNumberAccessories!.isNotEmpty) {
      accessoriesItemNumber = product.itemNumberAccessories;
    }

    // Mapping bonus items
    final List<String?> bonusItemNumbers = [];
    for (int i = 0; i < product.bonus.length; i++) {
      final bonus = product.bonus[i];
      if (bonus.name.isNotEmpty) {
        final bonusItemNumber = await getItemNumberByType(bonus.name);
        bonusItemNumbers.add(bonusItemNumber);
      } else {
        bonusItemNumbers.add(null);
      }
    }

    return ProductItemMappingEntity(
      productId: product.id,
      brand: product.brand,
      kasurItemNumber: kasurItemNumber,
      divanItemNumber: divanItemNumber,
      headboardItemNumber: headboardItemNumber,
      sorongItemNumber: sorongItemNumber,
      accessoriesItemNumber: accessoriesItemNumber,
      bonusItemNumbers: bonusItemNumbers,
    );
  }

  @override
  Future<CheckoutItemMappingEntity> mapCheckoutItems(
    List<ProductEntity> products,
  ) async {
    final List<ProductItemMappingEntity> productMappings = [];

    for (final product in products) {
      final mapping = await mapProductItems(product);
      productMappings.add(mapping);
    }

    return CheckoutItemMappingEntity(
      productMappings: productMappings,
      totalProducts: products.length,
    );
  }

  @override
  void clearCache() {
    _cachedItemLookups = null;
  }
}

