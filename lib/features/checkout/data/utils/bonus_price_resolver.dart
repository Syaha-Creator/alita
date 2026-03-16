import '../../../pricelist/data/models/product.dart';

/// Resolves bonus pricelist value by matching bonus name.
class BonusPriceResolver {
  const BonusPriceResolver._();

  static double resolvePlPrice(Product product, String bonusName) {
    final candidates = <({String? name, double? price})>[
      (name: product.bonus1, price: product.plBonus1),
      (name: product.bonus2, price: product.plBonus2),
      (name: product.bonus3, price: product.plBonus3),
      (name: product.bonus4, price: product.plBonus4),
      (name: product.bonus5, price: product.plBonus5),
      (name: product.bonus6, price: product.plBonus6),
      (name: product.bonus7, price: product.plBonus7),
      (name: product.bonus8, price: product.plBonus8),
    ];

    for (final candidate in candidates) {
      if ((candidate.name ?? '') == bonusName) {
        return (candidate.price ?? 0).toDouble();
      }
    }
    return 0.0;
  }
}
