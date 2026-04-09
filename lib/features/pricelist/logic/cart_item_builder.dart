import '../../cart/data/cart_indirect_meta.dart';
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
    /// Non-null hanya untuk mode indirect (toko assign + diskon API).
    CartIndirectMeta? indirectMeta,

    // Bonus override (from "Tukar Bonus")
    List<Map<String, dynamic>>? customBonuses,
  }) {
    final hasKasur = _isComponentPresent(activeProduct.kasur);
    final savingAsSet = hasKasur ? !isKasurOnly : true;
    final summary =
        '$effectiveSize · $effectiveDivan · $effectiveHeadboard · $effectiveSorong';

    // ── Resolve SKU / Kain / Warna per component ──

    final kasurSkuFinal = _resolveSku(isKasurCustom, effectiveKasurLookup);
    final kasurKainFinal =
        _resolveKain(isKasurCustom, effectiveKasurLookup, customKasurNote);
    final kasurWarnaFinal =
        _resolveWarna(isKasurCustom, effectiveKasurLookup, customKasurNote);

    final divanSkuFinal =
        savingAsSet ? _resolveSku(isDivanCustom, effectiveDivanLookup) : '';
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

    final sorongSkuFinal =
        savingAsSet ? _resolveSku(isSorongCustom, effectiveSorongLookup) : '';
    final sorongKainFinal = savingAsSet
        ? _resolveKain(isSorongCustom, effectiveSorongLookup, customSorongNote)
        : '';
    final sorongWarnaFinal = savingAsSet
        ? _resolveWarna(isSorongCustom, effectiveSorongLookup, customSorongNote)
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
        descLines.add(_componentDesc(effectiveSorong, sorongSkuFinal,
            sorongKainFinal, sorongWarnaFinal));
      }
    }
    final componentDescNote = descLines.join('\n');

    // ── Rounding / markup correction ──
    //
    // When the user edits the total EUP upward, the difference between
    // totalFinalPrice and the component sum must be applied to the
    // PRIMARY component (the one that actually contributes to the price).
    // For standard products this is kasur; for divan-only or headboard-only
    // products there is no kasur so we fall through to the first non-zero
    // component.

    final componentSum = finalKasurPrice +
        finalDivanPrice +
        finalHeadboardPrice +
        finalSorongPrice;
    final roundingDiff = totalFinalPrice - componentSum;

    double adjKasur = finalKasurPrice;
    double adjDivan = finalDivanPrice;
    double adjHeadboard = finalHeadboardPrice;
    double adjSorong = finalSorongPrice;

    if (roundingDiff.abs() > 0.001) {
      if (hasKasur && finalKasurPrice > 0) {
        adjKasur += roundingDiff;
      } else if (_isComponentPresent(activeProduct.divan) &&
          finalDivanPrice > 0) {
        adjDivan += roundingDiff;
      } else if (_isComponentPresent(activeProduct.headboard) &&
          finalHeadboardPrice > 0) {
        adjHeadboard += roundingDiff;
      } else if (_isComponentPresent(activeProduct.sorong) &&
          finalSorongPrice > 0) {
        adjSorong += roundingDiff;
      } else {
        adjKasur += roundingDiff;
      }
    }

    // ── Configured product snapshot ──

    final configuredProduct = activeProduct.copyWith(
      price: totalFinalPrice,
      eupKasur: adjKasur,
      eupDivan: adjDivan,
      eupHeadboard: adjHeadboard,
      eupSorong: adjSorong,
      description: componentDescNote.isNotEmpty
          ? '${activeProduct.description}\n[$summary]\n$componentDescNote'
          : '${activeProduct.description}\n[$summary]',
      isSet: savingAsSet,
      divan: savingAsSet ? effectiveDivan : 'Tanpa Divan',
      headboard: savingAsSet ? effectiveHeadboard : 'Tanpa Headboard',
      sorong: savingAsSet ? effectiveSorong : 'Tanpa Sorong',
    );

    // ── Bonus snapshots ──

    final bonusSnapshots = customBonuses != null && customBonuses.isNotEmpty
        ? _buildCustomBonusSnapshots(customBonuses, groupedLookups,
            effectiveSize: effectiveSize)
        : _buildBonusSnapshots(activeProduct, groupedLookups,
            effectiveSize: effectiveSize);

    // ── Discount percentages ──

    final discPct1 =
        appliedDiscounts.isNotEmpty ? appliedDiscounts[0] * 100 : 0.0;
    final discPct2 =
        appliedDiscounts.length >= 2 ? appliedDiscounts[1] * 100 : 0.0;
    final discPct3 =
        appliedDiscounts.length >= 3 ? appliedDiscounts[2] * 100 : 0.0;
    final discPct4 =
        appliedDiscounts.length >= 4 ? appliedDiscounts[3] * 100 : 0.0;

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
      discount4: discPct4,
      bonusSnapshots: bonusSnapshots,
      indirectStoreAddressNumber: indirectMeta?.addressNumber,
      indirectStoreAlphaName: indirectMeta?.alphaName ?? '',
      indirectStoreAddress: indirectMeta?.address ?? '',
      indirectStorePhone: indirectMeta?.phone ?? '',
      indirectStoreDiscounts: indirectMeta?.storeDiscounts ?? const [],
      indirectStoreDiscountDisplay: indirectMeta?.discountDisplay ?? '',
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

  static bool _isComponentPresent(String field) {
    final v = field.trim().toLowerCase();
    return v.isNotEmpty && !v.startsWith('tanpa');
  }

  static String _resolveSku(bool isCustom, ItemLookup? lkp) {
    if (isCustom) return CartItem.customItemSku;
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

  static List<CartBonusSnapshot> _buildCustomBonusSnapshots(
    List<Map<String, dynamic>> customBonuses,
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

    return customBonuses.where((b) {
      final name = b['name']?.toString().trim() ?? '';
      return name.isNotEmpty;
    }).map((b) {
      final name = b['name'].toString().trim();
      final qty = (b['qty'] as num?)?.toInt() ?? 1;
      final directItemNum = b['item_num']?.toString().trim() ?? '';
      final lu = lookupFor(name);
      return CartBonusSnapshot(
          name: name, qty: qty, sku: lu?.itemNum ?? directItemNum);
    }).toList();
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
