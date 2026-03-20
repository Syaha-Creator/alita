import '../../data/models/product.dart';

/// Builds the default bonus list from a [Product]'s bonus1–bonus8 fields.
///
/// Returns a list of maps with keys: `name`, `qty`, `max_qty`, `pl`, `is_custom`.
abstract final class ProductBonusBuilder {
  static List<Map<String, dynamic>> buildDefaultBonuses(Product product) {
    final slots = <(String?, int?, double?)>[
      (product.bonus1, product.qtyBonus1, product.plBonus1),
      (product.bonus2, product.qtyBonus2, product.plBonus2),
      (product.bonus3, product.qtyBonus3, product.plBonus3),
      (product.bonus4, product.qtyBonus4, product.plBonus4),
      (product.bonus5, product.qtyBonus5, product.plBonus5),
      (product.bonus6, product.qtyBonus6, product.plBonus6),
      (product.bonus7, product.qtyBonus7, product.plBonus7),
      (product.bonus8, product.qtyBonus8, product.plBonus8),
    ];

    return <Map<String, dynamic>>[
      for (final (name, qty, pl) in slots)
        if (name != null && name.isNotEmpty)
          {
            'name': name,
            'qty': qty ?? 1,
            'max_qty': ((qty ?? 1) * 2),
            'pl': pl,
            'is_custom': false,
          },
    ];
  }
}
