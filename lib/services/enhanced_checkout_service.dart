import '../features/product/domain/entities/product_entity.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import 'item_mapping_service.dart';
import 'checkout_service.dart';

class EnhancedCheckoutService {
  final CheckoutService _checkoutService;
  final ItemMappingService _itemMappingService;

  EnhancedCheckoutService({
    required CheckoutService checkoutService,
    required ItemMappingService itemMappingService,
  })  : _checkoutService = checkoutService,
        _itemMappingService = itemMappingService;

  /// Checkout dengan item mapping dari pl_lookup_item_nums
  Future<Map<String, dynamic>> checkoutWithItemMapping({
    required List<CartEntity> cartItems,
    required String customerName,
    required String customerPhone,
    required String email,
    required String customerAddress,
    required String shipToName,
    required String addressShipTo,
    required String requestDate,
    required String note,
    String? spgCode,
    bool isTakeAway = false,
  }) async {
    try {
      // Mapping semua item ke item lookup
      final products = cartItems.map((item) => item.product).toList();
      final checkoutMapping =
          await _itemMappingService.mapCheckoutItems(products);

      // Buat cart items dengan item_number yang sudah di-mapping
      final mappedCartItems =
          await _createMappedCartItems(cartItems, checkoutMapping);

      // Lanjutkan checkout dengan data yang sudah di-mapping
      return await _checkoutService.createOrderLetterFromCart(
        cartItems: mappedCartItems,
        customerName: customerName,
        customerPhone: customerPhone,
        email: email,
        customerAddress: customerAddress,
        shipToName: shipToName,
        addressShipTo: addressShipTo,
        requestDate: requestDate,
        note: note,
        spgCode: spgCode,
        isTakeAway: isTakeAway,
      );
    } catch (e) {
      print('EnhancedCheckoutService: Error during checkout with mapping: $e');
      rethrow;
    }
  }

  /// Buat cart items dengan item_number yang sudah di-mapping
  Future<List<CartEntity>> _createMappedCartItems(
    List<CartEntity> originalCartItems,
    CheckoutItemMapping checkoutMapping,
  ) async {
    final List<CartEntity> mappedCartItems = [];

    for (int i = 0; i < originalCartItems.length; i++) {
      final originalItem = originalCartItems[i];
      final productMapping = checkoutMapping.productMappings[i];

      // Buat product entity baru dengan item_number yang sudah di-mapping
      final mappedProduct = ProductEntity(
        id: originalItem.product.id,
        area: originalItem.product.area,
        channel: originalItem.product.channel,
        brand: originalItem.product.brand,
        kasur: originalItem.product.kasur,
        divan: originalItem.product.divan,
        headboard: originalItem.product.headboard,
        sorong: originalItem.product.sorong,
        ukuran: originalItem.product.ukuran,
        pricelist: originalItem.product.pricelist,
        program: originalItem.product.program,
        eupKasur: originalItem.product.eupKasur,
        eupDivan: originalItem.product.eupDivan,
        eupHeadboard: originalItem.product.eupHeadboard,
        endUserPrice: originalItem.product.endUserPrice,
        bonus: originalItem.product.bonus,
        discounts: originalItem.product.discounts,
        isSet: originalItem.product.isSet,
        plKasur: originalItem.product.plKasur,
        plDivan: originalItem.product.plDivan,
        plHeadboard: originalItem.product.plHeadboard,
        plSorong: originalItem.product.plSorong,
        eupSorong: originalItem.product.eupSorong,
        bottomPriceAnalyst: originalItem.product.bottomPriceAnalyst,
        disc1: originalItem.product.disc1,
        disc2: originalItem.product.disc2,
        disc3: originalItem.product.disc3,
        disc4: originalItem.product.disc4,
        disc5: originalItem.product.disc5,
        itemNumber: productMapping.kasurItemNumber ?? '',
        itemNumberKasur: productMapping.kasurItemNumber ?? '',
        itemNumberDivan: productMapping.divanItemNumber ?? '',
        itemNumberHeadboard: productMapping.headboardItemNumber ?? '',
        itemNumberSorong: productMapping.sorongItemNumber ?? '',
        itemNumberAccessories: productMapping.accessoriesItemNumber ?? '',
        itemNumberBonus1: productMapping.bonusItemNumbers.isNotEmpty
            ? productMapping.bonusItemNumbers[0] ?? ''
            : null,
        itemNumberBonus2: productMapping.bonusItemNumbers.length > 1
            ? productMapping.bonusItemNumbers[1] ?? ''
            : null,
        itemNumberBonus3: productMapping.bonusItemNumbers.length > 2
            ? productMapping.bonusItemNumbers[2] ?? ''
            : null,
        itemNumberBonus4: productMapping.bonusItemNumbers.length > 3
            ? productMapping.bonusItemNumbers[3] ?? ''
            : null,
        itemNumberBonus5: productMapping.bonusItemNumbers.length > 4
            ? productMapping.bonusItemNumbers[4] ?? ''
            : null,
      );

      // Buat cart item baru dengan product yang sudah di-mapping
      final mappedCartItem = CartEntity(
        product: mappedProduct,
        quantity: originalItem.quantity,
        netPrice: originalItem.netPrice,
        discountPercentages: originalItem.discountPercentages,
        installmentMonths: originalItem.installmentMonths,
        installmentPerMonth: originalItem.installmentPerMonth,
        isSelected: originalItem.isSelected,
        bonusTakeAway: originalItem.bonusTakeAway,
      );

      mappedCartItems.add(mappedCartItem);
    }

    return mappedCartItems;
  }

  /// Validasi item mapping sebelum checkout
  Future<ItemMappingValidationResult> validateItemMapping(
      List<CartEntity> cartItems) async {
    final products = cartItems.map((item) => item.product).toList();
    final checkoutMapping =
        await _itemMappingService.mapCheckoutItems(products);

    return ItemMappingValidationResult(
      isValid: checkoutMapping.allItemsMapped,
      totalProducts: checkoutMapping.totalProducts,
      totalUnmappedItems: checkoutMapping.totalUnmappedItems,
      productMappings: checkoutMapping.productMappings,
    );
  }

  /// Dapatkan laporan item mapping untuk debugging
  Future<String> generateItemMappingReport(List<CartEntity> cartItems) async {
    final products = cartItems.map((item) => item.product).toList();
    final checkoutMapping =
        await _itemMappingService.mapCheckoutItems(products);

    final buffer = StringBuffer();
    buffer.writeln('=== ITEM MAPPING REPORT ===');
    buffer.writeln('Total Products: ${checkoutMapping.totalProducts}');
    buffer.writeln('All Items Mapped: ${checkoutMapping.allItemsMapped}');
    buffer
        .writeln('Total Unmapped Items: ${checkoutMapping.totalUnmappedItems}');
    buffer.writeln();

    for (int i = 0; i < checkoutMapping.productMappings.length; i++) {
      final productMapping = checkoutMapping.productMappings[i];
      final product = products[i];

      buffer.writeln('Product ${i + 1}: ${product.brand} (ID: ${product.id})');
      buffer.writeln(
          '  Kasur: ${product.kasur} -> ${productMapping.kasurItemNumber ?? "NOT FOUND"}');
      buffer.writeln(
          '  Divan: ${product.divan} -> ${productMapping.divanItemNumber ?? "NOT FOUND"}');
      buffer.writeln(
          '  Headboard: ${product.headboard} -> ${productMapping.headboardItemNumber ?? "NOT FOUND"}');
      buffer.writeln(
          '  Sorong: ${product.sorong} -> ${productMapping.sorongItemNumber ?? "NOT FOUND"}');

      if (productMapping.bonusItemNumbers.isNotEmpty) {
        for (int j = 0; j < productMapping.bonusItemNumbers.length; j++) {
          final bonusItemNumber = productMapping.bonusItemNumbers[j];
          if (bonusItemNumber != null) {
            buffer.writeln(
                '  Bonus ${j + 1}: ${product.bonus[j].name} -> $bonusItemNumber');
          }
        }
      }

      if (productMapping.hasUnmappedItems) {
        buffer.writeln(
            '  ⚠️  Unmapped items: ${productMapping.unmappedItems.join(", ")}');
      }

      buffer.writeln();
    }

    return buffer.toString();
  }
}

class ItemMappingValidationResult {
  final bool isValid;
  final int totalProducts;
  final int totalUnmappedItems;
  final List<ProductItemMapping> productMappings;

  ItemMappingValidationResult({
    required this.isValid,
    required this.totalProducts,
    required this.totalUnmappedItems,
    required this.productMappings,
  });

  @override
  String toString() {
    return 'ItemMappingValidationResult(isValid: $isValid, totalProducts: $totalProducts, totalUnmappedItems: $totalUnmappedItems)';
  }
}
