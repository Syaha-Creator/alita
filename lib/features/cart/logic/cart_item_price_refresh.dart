import '../../../core/utils/store_discount_calculator.dart';
import '../../pricelist/data/models/product.dart';
import '../../pricelist/logic/product_detail_utils.dart';
import '../data/cart_item.dart';

/// Result of re-applying server catalog rows to local [CartItem] lines.
class CartPriceRefreshResult {
  const CartPriceRefreshResult({
    required this.items,
    required this.updatedCount,
    required this.notFoundCount,
  });

  final List<CartItem> items;
  final int updatedCount;
  final int notFoundCount;
}

/// Recomputes line prices from a fresh pricelist snapshot while preserving
/// qty, SKUs, kain/warna, sales discount % (diskon 1–4), and indirect store discounts.
abstract final class CartItemPriceRefresh {
  CartItemPriceRefresh._();

  static List<CartBonusSnapshot> _bonusSnapshotsFromProduct(Product p) {
    final slots = <(String?, int?)>[
      (p.bonus1, p.qtyBonus1),
      (p.bonus2, p.qtyBonus2),
      (p.bonus3, p.qtyBonus3),
      (p.bonus4, p.qtyBonus4),
      (p.bonus5, p.qtyBonus5),
      (p.bonus6, p.qtyBonus6),
      (p.bonus7, p.qtyBonus7),
      (p.bonus8, p.qtyBonus8),
    ];

    return [
      for (final (name, qty) in slots)
        if (name != null && name.isNotEmpty)
          CartBonusSnapshot(name: name, qty: qty ?? 1),
    ];
  }

  static List<double> _salesDiscountFractions(CartItem item) {
    final out = <double>[];
    if (item.discount1 > 0) out.add(item.discount1 / 100.0);
    if (item.discount2 > 0) out.add(item.discount2 / 100.0);
    if (item.discount3 > 0) out.add(item.discount3 / 100.0);
    if (item.discount4 > 0) out.add(item.discount4 / 100.0);
    return out;
  }

  static double _eupAfterStore(double raw, List<double> storeDiscounts) {
    if (raw <= 0) return 0;
    if (storeDiscounts.isEmpty) return raw;
    return StoreDiscountCalculator.cascade(raw, storeDiscounts);
  }

  /// Finds the API row for this cart line: [Product.id] first, then variant fields.
  static Product? matchCatalogRow(CartItem item, List<Product> catalog) {
    for (final p in catalog) {
      if (p.id == item.product.id) return p;
    }
    final snap = item.product;
    for (final p in catalog) {
      if (p.kasur == snap.kasur &&
          p.ukuran == snap.ukuran &&
          p.divan == snap.divan &&
          p.headboard == snap.headboard &&
          p.sorong == snap.sorong) {
        return p;
      }
    }
    return null;
  }

  static bool _linePricingEquals(CartItem a, CartItem b) =>
      a.product.price == b.product.price &&
      a.totalPrice == b.totalPrice &&
      a.originalEupKasur == b.originalEupKasur &&
      a.originalEupDivan == b.originalEupDivan &&
      a.originalEupHeadboard == b.originalEupHeadboard &&
      a.originalEupSorong == b.originalEupSorong;

  /// Returns updated [CartItem] or [item] if FOC / no change.
  static CartItem applyCatalogRow(CartItem item, Product fresh) {
    if (item.isFocVoucherActive) return item;

    final fractions = _salesDiscountFractions(item);
    final store = item.indirectStoreDiscounts;

    double partPrice(bool useComponent, double catalogEup) {
      if (!useComponent || catalogEup <= 0) return 0;
      final base = _eupAfterStore(catalogEup, store);
      return ProductDetailUtils.calculateCascadingPrice(base, fractions);
    }

    final useKasur = ProductDetailUtils.isComponentPresent(item.product.kasur);
    final useDivan = ProductDetailUtils.isComponentPresent(item.product.divan);
    final useHb =
        ProductDetailUtils.isComponentPresent(item.product.headboard);
    final useSorong =
        ProductDetailUtils.isComponentPresent(item.product.sorong);

    final finalKasur = partPrice(useKasur, fresh.eupKasur);
    final finalDivan = partPrice(useDivan, fresh.eupDivan);
    final finalHb = partPrice(useHb, fresh.eupHeadboard);
    final finalSorong = partPrice(useSorong, fresh.eupSorong);

    final totalFinalPrice = finalKasur + finalDivan + finalHb + finalSorong;

    final mergedProduct = item.product.copyWith(
      price: totalFinalPrice,
      eupKasur: finalKasur,
      eupDivan: finalDivan,
      eupHeadboard: finalHb,
      eupSorong: finalSorong,
      pricelist: fresh.pricelist,
      plKasur: fresh.plKasur,
      plDivan: fresh.plDivan,
      plHeadboard: fresh.plHeadboard,
      plSorong: fresh.plSorong,
      plBonus1: fresh.plBonus1,
      plBonus2: fresh.plBonus2,
      plBonus3: fresh.plBonus3,
      plBonus4: fresh.plBonus4,
      plBonus5: fresh.plBonus5,
      plBonus6: fresh.plBonus6,
      plBonus7: fresh.plBonus7,
      plBonus8: fresh.plBonus8,
      bottomPriceAnalyst: fresh.bottomPriceAnalyst,
      disc1: fresh.disc1,
      disc2: fresh.disc2,
      disc3: fresh.disc3,
      disc4: fresh.disc4,
      disc5: fresh.disc5,
      disc6: fresh.disc6,
      disc7: fresh.disc7,
      disc8: fresh.disc8,
      bonus1: fresh.bonus1,
      qtyBonus1: fresh.qtyBonus1,
      bonus2: fresh.bonus2,
      qtyBonus2: fresh.qtyBonus2,
      bonus3: fresh.bonus3,
      qtyBonus3: fresh.qtyBonus3,
      bonus4: fresh.bonus4,
      qtyBonus4: fresh.qtyBonus4,
      bonus5: fresh.bonus5,
      qtyBonus5: fresh.qtyBonus5,
      bonus6: fresh.bonus6,
      qtyBonus6: fresh.qtyBonus6,
      bonus7: fresh.bonus7,
      qtyBonus7: fresh.qtyBonus7,
      bonus8: fresh.bonus8,
      qtyBonus8: fresh.qtyBonus8,
      isAvailable: fresh.isAvailable,
      imageUrl: fresh.imageUrl.isNotEmpty ? fresh.imageUrl : item.product.imageUrl,
    );

    return item.copyWith(
      product: mergedProduct,
      masterProduct: fresh,
      originalEupKasur: fresh.eupKasur,
      originalEupDivan: fresh.eupDivan,
      originalEupHeadboard: fresh.eupHeadboard,
      originalEupSorong: fresh.eupSorong,
      bonusSnapshots: _bonusSnapshotsFromProduct(fresh),
    );
  }

  /// Applies [catalog] to each line. Unmatched lines are left unchanged.
  static CartPriceRefreshResult applyToLines(
    List<CartItem> lines,
    List<Product> catalog,
  ) {
    var updated = 0;
    var notFound = 0;
    final out = <CartItem>[];

    for (final item in lines) {
      final fresh = matchCatalogRow(item, catalog);
      if (fresh == null) {
        out.add(item);
        if (!item.isFocVoucherActive) notFound++;
        continue;
      }
      final next = applyCatalogRow(item, fresh);
      if (!_linePricingEquals(item, next)) updated++;
      out.add(next);
    }

    return CartPriceRefreshResult(
      items: out,
      updatedCount: updated,
      notFoundCount: notFound,
    );
  }
}
