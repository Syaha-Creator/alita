import '../../data/models/product.dart';

/// Builds the default bonus list from a [Product]'s bonus1–bonus8 fields.
///
/// Returns a list of maps with keys: `name`, `qty`, `max_qty`, `pl`, `is_custom`.
abstract final class ProductBonusBuilder {
  static List<Map<String, dynamic>> buildDefaultBonuses(Product product) {
    return <Map<String, dynamic>>[
      if (product.bonus1 != null && product.bonus1!.isNotEmpty)
        {
          'name': product.bonus1!,
          'qty': product.qtyBonus1 ?? 1,
          'max_qty': ((product.qtyBonus1 ?? 1) * 2),
          'pl': product.plBonus1,
          'is_custom': false,
        },
      if (product.bonus2 != null && product.bonus2!.isNotEmpty)
        {
          'name': product.bonus2!,
          'qty': product.qtyBonus2 ?? 1,
          'max_qty': ((product.qtyBonus2 ?? 1) * 2),
          'pl': product.plBonus2,
          'is_custom': false,
        },
      if (product.bonus3 != null && product.bonus3!.isNotEmpty)
        {
          'name': product.bonus3!,
          'qty': product.qtyBonus3 ?? 1,
          'max_qty': ((product.qtyBonus3 ?? 1) * 2),
          'pl': product.plBonus3,
          'is_custom': false,
        },
      if (product.bonus4 != null && product.bonus4!.isNotEmpty)
        {
          'name': product.bonus4!,
          'qty': product.qtyBonus4 ?? 1,
          'max_qty': ((product.qtyBonus4 ?? 1) * 2),
          'pl': product.plBonus4,
          'is_custom': false,
        },
      if (product.bonus5 != null && product.bonus5!.isNotEmpty)
        {
          'name': product.bonus5!,
          'qty': product.qtyBonus5 ?? 1,
          'max_qty': ((product.qtyBonus5 ?? 1) * 2),
          'pl': product.plBonus5,
          'is_custom': false,
        },
      if (product.bonus6 != null && product.bonus6!.isNotEmpty)
        {
          'name': product.bonus6!,
          'qty': product.qtyBonus6 ?? 1,
          'max_qty': ((product.qtyBonus6 ?? 1) * 2),
          'pl': product.plBonus6,
          'is_custom': false,
        },
      if (product.bonus7 != null && product.bonus7!.isNotEmpty)
        {
          'name': product.bonus7!,
          'qty': product.qtyBonus7 ?? 1,
          'max_qty': ((product.qtyBonus7 ?? 1) * 2),
          'pl': product.plBonus7,
          'is_custom': false,
        },
      if (product.bonus8 != null && product.bonus8!.isNotEmpty)
        {
          'name': product.bonus8!,
          'qty': product.qtyBonus8 ?? 1,
          'max_qty': ((product.qtyBonus8 ?? 1) * 2),
          'pl': product.plBonus8,
          'is_custom': false,
        },
    ];
  }
}
