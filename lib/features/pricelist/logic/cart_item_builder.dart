import '../../cart/data/cart_item.dart';
import '../data/models/item_lookup.dart';
import '../data/models/product.dart';

/// Encapsulates the deterministic snapshot logic that converts the product
/// detail page state into a [CartItem] ready for the cart.
///
/// Extracted from [ProductDetailPage._buildBottomBar] to keep presentation
/// layer focused on UI.
class CartItemBuilder {
  CartItemBuilder._();

  static const _kCustomItemNum = 'CUSTOM';

  /// Builds a fully-resolved [CartItem] from the current configurator state.
  ///
  /// The caller is responsible for validation (e.g. ensuring required lookups
  /// are selected) before invoking this method.
  static CartItem build({
    required Product activeProduct,
    required Product masterProduct,
    required String effectiveSize,
    required String effectiveDivan,
    required String effectiveHeadboard,
    required String effectiveSorong,
    required double totalFinalPrice,
    required double finalKasurPrice,
    required double finalDivanPrice,
    required double finalHeadboardPrice,
    required double finalSorongPrice,
    required bool isKasurOnly,
    required List<double> appliedDiscounts,
    required Map<String, List<ItemLookup>> groupedLookups,
    // Kasur
    required bool isKasurCustom,
    required ItemLookup? effectiveKasurLookup,
    required String customKasurNote,
    // Divan
    required bool isDivanCustom,
    required ItemLookup? effectiveDivanLookup,
    required String customDivanNote,
    // Headboard
    required bool isHeadboardCustom,
    required ItemLookup? effectiveHeadboardLookup,
    required String customHbNote,
    // Sorong
    required bool isSorongCustom,
    required ItemLookup? effectiveSorongLookup,
    required String customSorongNote,
  }) {
    final savingAsSet = !isKasurOnly;
    final summary =
        '$effectiveSize · $effectiveDivan · $effectiveHeadboard · $effectiveSorong';

    // ── Resolve SKU / Kain / Warna per component ──

    final kasurSkuFinal = _resolveSku(isKasurCustom, effectiveKasurLookup);
    final kasurKainFinal =
        _resolveKain(isKasurCustom, effectiveKasurLookup, customKasurNote);
    final kasurWarnaFinal =
        _resolveWarna(isKasurCustom, effectiveKasurLookup, customKasurNote);

    final divanSkuFinal = savingAsSet
        ? _resolveSku(isDivanCustom, effectiveDivanLookup)
        : '';
    final divanKainFinal = savingAsSet
        ? _resolveKain(isDivanCustom, effectiveDivanLookup, customDivanNote)
        : '';
    final divanWarnaFinal = savingAsSet
        ? _resolveWarna(isDivanCustom, effectiveDivanLookup, customDivanNote)
        : '';

    final hbSkuFinal = savingAsSet
        ? _resolveSku(isHeadboardCustom, effectiveHeadboardLookup)
        : '';
    final hbKainFinal = savingAsSet
        ? _resolveKain(
            isHeadboardCustom, effectiveHeadboardLookup, customHbNote)
        : '';
    final hbWarnaFinal = savingAsSet
        ? _resolveWarna(
            isHeadboardCustom, effectiveHeadboardLookup, customHbNote)
        : '';

    final sorongSkuFinal = savingAsSet
        ? _resolveSku(isSorongCustom, effectiveSorongLookup)
        : '';
    final sorongKainFinal = savingAsSet
        ? _resolveKain(
            isSorongCustom, effectiveSorongLookup, customSorongNote)
        : '';
    final sorongWarnaFinal = savingAsSet
        ? _resolveWarna(
            isSorongCustom, effectiveSorongLookup, customSorongNote)
        : '';

    // ── Build description lines ──

    final descLines = <String>[];
    if (activeProduct.kasur.isNotEmpty) {
      descLines.add(_componentDesc(
          activeProduct.kasur, kasurSkuFinal, kasurKainFinal, kasurWarnaFinal));
    }
    if (savingAsSet) {
      if (effectiveDivan.toLowerCase() != 'tanpa divan' &&
          divanSkuFinal.isNotEmpty) {
        descLines.add(_componentDesc(
            effectiveDivan, divanSkuFinal, divanKainFinal, divanWarnaFinal));
      }
      if (effectiveHeadboard.toLowerCase() != 'tanpa headboard' &&
          hbSkuFinal.isNotEmpty) {
        descLines.add(_componentDesc(
            effectiveHeadboard, hbSkuFinal, hbKainFinal, hbWarnaFinal));
      }
      if (effectiveSorong.toLowerCase() != 'tanpa sorong' &&
          sorongSkuFinal.isNotEmpty) {
        descLines.add(_componentDesc(
            effectiveSorong, sorongSkuFinal, sorongKainFinal, sorongWarnaFinal));
      }
    }
    final componentDescNote = descLines.join('\n');

    // ── Rounding correction ──

    final componentSum =
        finalKasurPrice + finalDivanPrice + finalHeadboardPrice + finalSorongPrice;
    final roundingDiff = totalFinalPrice - componentSum;

    // ── Configured product snapshot ──

    final configuredProduct = activeProduct.copyWith(
      price: totalFinalPrice,
      eupKasur: finalKasurPrice + roundingDiff,
      eupDivan: finalDivanPrice,
      eupHeadboard: finalHeadboardPrice,
      eupSorong: finalSorongPrice,
      description: componentDescNote.isNotEmpty
          ? '${activeProduct.description}\n[$summary]\n$componentDescNote'
          : '${activeProduct.description}\n[$summary]',
      isSet: savingAsSet,
      divan: savingAsSet ? effectiveDivan : 'Tanpa Divan',
      headboard: savingAsSet ? effectiveHeadboard : 'Tanpa Headboard',
      sorong: savingAsSet ? effectiveSorong : 'Tanpa Sorong',
    );

    // ── Bonus snapshots ──

    final bonusSnapshots = _buildBonusSnapshots(activeProduct, groupedLookups,
        effectiveSize: effectiveSize);

    // ── Discount percentages ──

    final discPct1 =
        appliedDiscounts.isNotEmpty ? appliedDiscounts[0] * 100 : 0.0;
    final discPct2 =
        appliedDiscounts.length >= 2 ? appliedDiscounts[1] * 100 : 0.0;
    final discPct3 =
        appliedDiscounts.length >= 3 ? appliedDiscounts[2] * 100 : 0.0;

    return CartItem(
      product: configuredProduct,
      masterProduct: masterProduct,
      kasurSku: kasurSkuFinal,
      divanSku: divanSkuFinal,
      divanKain: divanKainFinal,
      divanWarna: divanWarnaFinal,
      sandaranSku: hbSkuFinal,
      sandaranKain: hbKainFinal,
      sandaranWarna: hbWarnaFinal,
      sorongSku: sorongSkuFinal,
      sorongKain: sorongKainFinal,
      sorongWarna: sorongWarnaFinal,
      originalEupKasur: activeProduct.eupKasur,
      originalEupDivan: activeProduct.eupDivan,
      originalEupHeadboard: activeProduct.eupHeadboard,
      originalEupSorong: activeProduct.eupSorong,
      discount1: discPct1,
      discount2: discPct2,
      discount3: discPct3,
      bonusSnapshots: bonusSnapshots,
    );
  }

  /// Human-readable summary string for the toast message.
  static String buildSummaryForToast({
    required String effectiveSize,
    required String effectiveDivan,
    required String effectiveHeadboard,
    required String effectiveSorong,
  }) {
    final chosenParts = [effectiveDivan, effectiveHeadboard, effectiveSorong]
        .where((s) => !s.startsWith('Tanpa '))
        .toList();
    return chosenParts.isEmpty
        ? effectiveSize
        : '$effectiveSize · ${chosenParts.join(' · ')}';
  }

  // ── Private helpers ──

  static String _resolveSku(bool isCustom, ItemLookup? lkp) {
    if (isCustom) return _kCustomItemNum;
    return lkp?.itemNum ?? '';
  }

  static String _resolveKain(bool isCustom, ItemLookup? lkp, String note) {
    if (isCustom) return 'Custom';
    return lkp?.jenisKain ?? '';
  }

  static String _resolveWarna(bool isCustom, ItemLookup? lkp, String note) {
    if (isCustom) return note.isNotEmpty ? note : 'Custom';
    return lkp?.warnaKain ?? '';
  }

  static String _componentDesc(
      String name, String sku, String kain, String warna) {
    if (sku.isEmpty && kain.isEmpty) return name;
    final parts = [name];
    if (sku.isNotEmpty) parts.add(sku);
    if (kain.isNotEmpty) parts.add(kain);
    if (warna.isNotEmpty) parts.add(warna);
    return parts.join(' - ');
  }

  static List<CartBonusSnapshot> _buildBonusSnapshots(
    Product product,
    Map<String, List<ItemLookup>> groupedLookups, {
    required String effectiveSize,
  }) {
    ItemLookup? lookupFor(String? tipe) {
      if (tipe == null || tipe.trim().isEmpty) return null;
      final key = tipe.trim().toLowerCase();
      final candidates = (groupedLookups[key] ?? [])
          .where((l) => l.ukuran == effectiveSize)
          .toList();
      return candidates.isNotEmpty
          ? candidates.first
          : (groupedLookups[key] ?? []).firstOrNull;
    }

    final slots = <(String?, int?)>[
      (product.bonus1, product.qtyBonus1),
      (product.bonus2, product.qtyBonus2),
      (product.bonus3, product.qtyBonus3),
      (product.bonus4, product.qtyBonus4),
      (product.bonus5, product.qtyBonus5),
      (product.bonus6, product.qtyBonus6),
      (product.bonus7, product.qtyBonus7),
      (product.bonus8, product.qtyBonus8),
    ];
    final rawBonuses = <(String, int)>[
      for (final (name, qty) in slots)
        if (name != null && name.isNotEmpty) (name, qty ?? 1),
    ];

    return rawBonuses.map((b) {
      final (name, qty) = b;
      final lu = lookupFor(name);
      return CartBonusSnapshot(name: name, qty: qty, sku: lu?.itemNum ?? '');
    }).toList();
  }
}
