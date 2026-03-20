import '../data/models/item_lookup.dart';

/// Pure utility functions extracted from [ProductDetailPage] to keep
/// the presentation layer thin. All methods are stateless and side-effect free.
abstract final class ProductDetailUtils {
  /// Reverse-engineers a list of cascading discount percentages (0–1 each)
  /// from a desired [targetTotal] given the [baseTotalEup] and the ordered
  /// [maxLimits] (disc1..disc8 ceilings).
  static List<double> computeDiscountsFromTargetTotal(
    double targetTotal,
    double baseTotalEup,
    List<double> maxLimits,
  ) {
    if (targetTotal >= baseTotalEup || targetTotal <= 0 || maxLimits.isEmpty) {
      return [];
    }
    final result = <double>[];
    double base = baseTotalEup;
    for (final limit in maxLimits) {
      final d = (1 - targetTotal / base).clamp(0.0, limit);
      result.add(d);
      base = base * (1 - d);
    }
    return result;
  }

  /// Applies cascading [discounts] to [basePrice] and returns the final price.
  static double calculateCascadingPrice(
    double basePrice,
    List<double> discounts,
  ) {
    double finalPrice = basePrice;
    for (final disc in discounts) {
      finalPrice -= (finalPrice * disc);
    }
    return finalPrice;
  }

  /// Deterministic identity key for an [ItemLookup] used to compare selections.
  static String lookupKey(ItemLookup? lookup) {
    if (lookup == null) return '';
    final tipe = lookup.tipe.trim().toLowerCase();
    final ukuran = lookup.ukuran.trim().toLowerCase();
    final itemNum = lookup.itemNum.trim().toLowerCase();
    final kain = (lookup.jenisKain ?? '').trim().toLowerCase();
    final warna = (lookup.warnaKain ?? '').trim().toLowerCase();
    return '$tipe|$ukuran|$itemNum|$kain|$warna';
  }

  /// Returns `true` when a component field value indicates a real component
  /// (i.e. it is not empty and does not start with "tanpa").
  static bool isComponentPresent(String field) {
    final v = field.trim().toLowerCase();
    return v.isNotEmpty && !v.startsWith('tanpa');
  }

  /// Collects the non-zero discount ceilings (disc1..disc8) from a product's
  /// raw disc values into an ordered list.
  static List<double> collectMaxLimits(List<double> rawDiscValues) {
    return rawDiscValues.where((d) => d > 0).toList();
  }
}
