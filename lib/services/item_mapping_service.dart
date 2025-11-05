import 'package:flutter/foundation.dart';

import '../features/product/domain/entities/item_lookup_entity.dart';
import '../features/product/domain/entities/product_entity.dart';
import '../features/product/domain/usecases/get_item_lookup_usecase.dart';

class ItemMappingService {
  final GetItemLookupUsecase _getItemLookupUsecase;
  List<ItemLookupEntity>? _cachedItemLookups;

  ItemMappingService({required GetItemLookupUsecase getItemLookupUsecase})
      : _getItemLookupUsecase = getItemLookupUsecase;

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

  /// Cari item lookup berdasarkan nama item (tipe)
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

  /// Dapatkan item_num berdasarkan nama item
  Future<String?> getItemNumberByType(String itemName) async {
    final item = await findItemByType(itemName);
    return item?.itemNum;
  }

  /// Mapping semua item dari product ke item lookup
  Future<ProductItemMapping> mapProductItems(ProductEntity product) async {
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
      // Coba cari berdasarkan item_number yang ada, atau bisa ditambahkan field accessories di product
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

    return ProductItemMapping(
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

  /// Mapping untuk checkout - ganti semua item_number dengan yang dari lookup
  Future<CheckoutItemMapping> mapCheckoutItems(
      List<ProductEntity> products) async {
    final List<ProductItemMapping> productMappings = [];

    for (final product in products) {
      final mapping = await mapProductItems(product);
      productMappings.add(mapping);
    }

    return CheckoutItemMapping(
      productMappings: productMappings,
      totalProducts: products.length,
    );
  }

  /// Clear cache
  void clearCache() {
    _cachedItemLookups = null;
  }
}

class ProductItemMapping {
  final int productId;
  final String brand;
  final String? kasurItemNumber;
  final String? divanItemNumber;
  final String? headboardItemNumber;
  final String? sorongItemNumber;
  final String? accessoriesItemNumber;
  final List<String?> bonusItemNumbers;

  ProductItemMapping({
    required this.productId,
    required this.brand,
    this.kasurItemNumber,
    this.divanItemNumber,
    this.headboardItemNumber,
    this.sorongItemNumber,
    this.accessoriesItemNumber,
    required this.bonusItemNumbers,
  });

  /// Cek apakah ada item yang tidak ditemukan di lookup
  bool get hasUnmappedItems {
    return kasurItemNumber == null ||
        divanItemNumber == null ||
        headboardItemNumber == null ||
        sorongItemNumber == null ||
        bonusItemNumbers.any((item) => item == null);
  }

  /// Dapatkan daftar item yang tidak ditemukan
  List<String> get unmappedItems {
    final List<String> unmapped = [];

    if (kasurItemNumber == null) unmapped.add('Kasur');
    if (divanItemNumber == null) unmapped.add('Divan');
    if (headboardItemNumber == null) unmapped.add('Headboard');
    if (sorongItemNumber == null) unmapped.add('Sorong');

    for (int i = 0; i < bonusItemNumbers.length; i++) {
      if (bonusItemNumbers[i] == null) {
        unmapped.add('Bonus ${i + 1}');
      }
    }

    return unmapped;
  }

  @override
  String toString() {
    return 'ProductItemMapping(productId: $productId, brand: $brand, kasur: $kasurItemNumber, divan: $divanItemNumber, headboard: $headboardItemNumber, sorong: $sorongItemNumber, accessories: $accessoriesItemNumber, bonus: $bonusItemNumbers)';
  }
}

class CheckoutItemMapping {
  final List<ProductItemMapping> productMappings;
  final int totalProducts;

  CheckoutItemMapping({
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
        0, (total, mapping) => total + mapping.unmappedItems.length);
  }

  @override
  String toString() {
    return 'CheckoutItemMapping(totalProducts: $totalProducts, allItemsMapped: $allItemsMapped, totalUnmappedItems: $totalUnmappedItems)';
  }
}
