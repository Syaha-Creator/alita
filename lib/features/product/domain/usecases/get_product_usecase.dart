import '../../data/repositories/product_repository.dart';
import '../entities/product_entity.dart';

class GetProductUseCase {
  final ProductRepository repository;
  GetProductUseCase(this.repository);

  Future<List<ProductEntity>> callWithFilter({
    required String area,
    required String channel,
    required String brand,
  }) async {
    final productModels = await repository.fetchProductsWithFilter(
      area: area,
      channel: channel,
      brand: brand,
    );
    return productModels.map((model) {
      return ProductEntity(
        id: model.id,
        area: model.area,
        channel: model.channel,
        brand: model.brand,
        kasur: model.kasur,
        divan: model.divan,
        headboard: model.headboard,
        sorong: model.sorong,
        ukuran: model.ukuran,
        pricelist: model.pricelist,
        program: model.program,
        eupKasur: model.eupKasur,
        eupDivan: model.eupDivan,
        eupHeadboard: model.eupHeadboard,
        endUserPrice: model.endUserPrice,
        isSet: model.set,
        bonus: [
          if (model.bonus1 != null && model.bonus1!.isNotEmpty)
            BonusItem(
                name: model.bonus1!,
                quantity: model.qtyBonus1 ?? 0,
                originalQuantity: model.qtyBonus1 ?? 0),
          if (model.bonus2 != null && model.bonus2!.isNotEmpty)
            BonusItem(
                name: model.bonus2!,
                quantity: model.qtyBonus2 ?? 0,
                originalQuantity: model.qtyBonus2 ?? 0),
          if (model.bonus3 != null && model.bonus3!.isNotEmpty)
            BonusItem(
                name: model.bonus3!,
                quantity: model.qtyBonus3 ?? 0,
                originalQuantity: model.qtyBonus3 ?? 0),
          if (model.bonus4 != null && model.bonus4!.isNotEmpty)
            BonusItem(
                name: model.bonus4!,
                quantity: model.qtyBonus4 ?? 0,
                originalQuantity: model.qtyBonus4 ?? 0),
          if (model.bonus5 != null && model.bonus5!.isNotEmpty)
            BonusItem(
                name: model.bonus5!,
                quantity: model.qtyBonus5 ?? 0,
                originalQuantity: model.qtyBonus5 ?? 0),
        ],
        discounts: [
          model.disc1,
          model.disc2,
          model.disc3,
          model.disc4,
          model.disc5,
        ],
        plKasur: model.plKasur,
        plDivan: model.plDivan,
        plHeadboard: model.plHeadboard,
        plSorong: model.plSorong,
        eupSorong: model.eupSorong,
        bottomPriceAnalyst: model.bottomPriceAnalyst,
        disc1: model.disc1,
        disc2: model.disc2,
        disc3: model.disc3,
        disc4: model.disc4,
        disc5: model.disc5,
        itemNumber: model.itemNumber,
        itemNumberKasur: model.itemNumberKasur,
        itemNumberDivan: model.itemNumberDivan,
        itemNumberHeadboard: model.itemNumberHeadboard,
        itemNumberSorong: model.itemNumberSorong,
        itemNumberAccessories: model.itemNumberAccessories,
        itemNumberBonus1: model.itemNumberBonus1,
        itemNumberBonus2: model.itemNumberBonus2,
        itemNumberBonus3: model.itemNumberBonus3,
        itemNumberBonus4: model.itemNumberBonus4,
        itemNumberBonus5: model.itemNumberBonus5,
      );
    }).toList();
  }
}
