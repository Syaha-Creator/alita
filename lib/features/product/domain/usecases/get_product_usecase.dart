import '../../data/repositories/product_repository.dart';
import '../entities/product_entity.dart';

class GetProductUseCase {
  final ProductRepository repository;

  GetProductUseCase(this.repository);

  Future<List<ProductEntity>> call() async {
    final productModels = await repository.fetchProducts();

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
        pricelist: model.pricelist.toDouble(),
        program: model.program,
        eupKasur: model.eupKasur.toDouble(),
        eupDivan: model.eupDivan.toDouble(),
        eupHeadboard: model.eupHeadboard.toDouble(),
        endUserPrice: model.endUserPrice.toDouble(),
        bonus: [
          if (model.bonus1 != null)
            BonusItem(name: model.bonus1 ?? "", quantity: model.qtyBonus1 ?? 0),
          if (model.bonus2 != null)
            BonusItem(name: model.bonus2 ?? "", quantity: model.qtyBonus2 ?? 0),
          if (model.bonus3 != null)
            BonusItem(name: model.bonus3 ?? "", quantity: model.qtyBonus3 ?? 0),
          if (model.bonus4 != null)
            BonusItem(name: model.bonus4 ?? "", quantity: model.qtyBonus4 ?? 0),
          if (model.bonus5 != null)
            BonusItem(name: model.bonus5 ?? "", quantity: model.qtyBonus5 ?? 0),
        ],
        discounts: [
          model.disc1.toDouble(),
          model.disc2.toDouble(),
          model.disc3.toDouble(),
          model.disc4.toDouble(),
          model.disc5.toDouble(),
        ],
        isSet: model.set,
      );
    }).toList();
  }
}
