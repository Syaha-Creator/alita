import '../data/models/item_lookup.dart';
import '../data/models/product.dart';
import '../presentation/widgets/product_anchor_type.dart';
import 'product_detail_utils.dart';

/// Result of resolving the active product variant from user selections.
///
/// All fields are precomputed so the widget tree only needs to read values.
class ResolvedVariant {
  const ResolvedVariant({
    required this.activeProduct,
    required this.effectiveSize,
    required this.effectiveDivan,
    required this.effectiveHeadboard,
    required this.effectiveSorong,
    required this.availableSizes,
    required this.availableDivans,
    required this.availableHeadboards,
    required this.availableSorongs,
    required this.divansForConfigurator,
    required this.headboardsForConfigurator,
    required this.hasSetOptions,
    required this.kasurLookups,
    required this.effectiveKasurLookup,
    required this.divanLookups,
    required this.effectiveDivanLookup,
    required this.headboardLookups,
    required this.effectiveHeadboardLookup,
    required this.sorongLookups,
    required this.effectiveSorongLookup,
    required this.baseTotalEup,
    required this.maxLimits,
  });

  final Product activeProduct;
  final String effectiveSize;
  final String effectiveDivan;
  final String effectiveHeadboard;
  final String effectiveSorong;

  final List<String> availableSizes;
  final List<String> availableDivans;
  final List<String> availableHeadboards;
  final List<String> availableSorongs;
  final List<String> divansForConfigurator;
  final List<String> headboardsForConfigurator;

  /// Whether this product has meaningful set options (headboard/sorong) to
  /// display, computed from the *unfiltered* available lists. The configurator
  /// uses this to decide whether to show the "Beli Set" toggle independently
  /// of [isKasurOnly] (which zeroes out the configurator lists).
  final bool hasSetOptions;

  final List<ItemLookup> kasurLookups;
  final ItemLookup? effectiveKasurLookup;
  final List<ItemLookup> divanLookups;
  final ItemLookup? effectiveDivanLookup;
  final List<ItemLookup> headboardLookups;
  final ItemLookup? effectiveHeadboardLookup;
  final List<ItemLookup> sorongLookups;
  final ItemLookup? effectiveSorongLookup;

  final double baseTotalEup;
  final List<double> maxLimits;
}

/// Stateless resolver that computes the active product variant from the
/// full sibling list and current user selections.
///
/// Extracted from [ProductDetailPage.build] — all logic is identical.
abstract final class ProductVariantResolver {
  static ResolvedVariant resolve({
    required Product masterProduct,
    required List<Product> rawProducts,
    required AnchorType anchor,
    required bool isKasurOnly,
    required String? selectedSize,
    required String? selectedDivan,
    required String? selectedHeadboard,
    required String? selectedSorong,
    required ItemLookup? selectedKasurLookup,
    required ItemLookup? selectedDivanLookup,
    required ItemLookup? selectedHeadboardLookup,
    required ItemLookup? selectedSorongLookup,
    required bool isKasurCustom,
    required bool isDivanCustom,
    required bool isHeadboardCustom,
    required bool isSorongCustom,
    required Map<String, List<ItemLookup>> groupedLookups,
  }) {
    bool isPresent(String f) => ProductDetailUtils.isComponentPresent(f);
    String lKey(ItemLookup? l) => ProductDetailUtils.lookupKey(l);

    // ── 0. Sibling list ──
    // For divan/headboard/sorong anchors we use a strict filter first
    // (matching anchor + no higher-priority component). If that yields
    // no set-level headboard/sorong choices, we broaden the search to
    // include ALL rows sharing the same anchor component name so that
    // accessories from kasur-based set rows are also available.
    final siblings = rawProducts.where((p) {
      switch (anchor) {
        case AnchorType.kasur:
          return p.kasur.trim() == masterProduct.kasur.trim();
        case AnchorType.divan:
          return p.divan.trim() == masterProduct.divan.trim() &&
              !isPresent(p.kasur);
        case AnchorType.headboard:
          return p.headboard.trim() == masterProduct.headboard.trim() &&
              !isPresent(p.kasur) &&
              !isPresent(p.divan);
        case AnchorType.sorong:
          return p.sorong.trim() == masterProduct.sorong.trim() &&
              !isPresent(p.kasur) &&
              !isPresent(p.divan) &&
              !isPresent(p.headboard);
      }
    }).toList();

    // Broadened sibling list: match by anchor name only (ignoring kasur
    // presence). Used to discover headboard/sorong options that may only
    // exist on full-set rows.
    final List<Product> broadSiblings;
    if (anchor == AnchorType.divan) {
      broadSiblings = rawProducts
          .where((p) => p.divan.trim() == masterProduct.divan.trim())
          .toList();
    } else if (anchor == AnchorType.headboard) {
      broadSiblings = rawProducts
          .where((p) => p.headboard.trim() == masterProduct.headboard.trim())
          .toList();
    } else {
      broadSiblings = siblings;
    }

    final siblingsList = siblings.isEmpty ? [masterProduct] : siblings;

    // ── 1. Size filter ──
    final availableSizes = siblingsList
        .map((p) => p.ukuran)
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final effectiveSize =
        (selectedSize != null && availableSizes.contains(selectedSize))
            ? selectedSize
            : (availableSizes.isNotEmpty
                ? availableSizes.first
                : masterProduct.ukuran);
    final siblingsBySize =
        siblingsList.where((p) => p.ukuran == effectiveSize).toList();

    final availableDivans = siblingsBySize
        .map((p) => p.divan)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Broad siblings filtered by size — used to discover headboard/sorong
    // options that exist on full-set rows (kasur+divan+hb+sorong) but not
    // on the strict divan-only / headboard-only rows.
    final broadBySize =
        broadSiblings.where((p) => p.ukuran == effectiveSize).toList();

    // ── 2. Auto-select default "Beli Set" ──
    String effectiveDivan;
    String effectiveHeadboard;
    String effectiveSorong;

    // Source for auto-select: prefer strict siblings, fall back to broad.
    final autoSelectPool =
        siblingsBySize.length > 1 ? siblingsBySize : broadBySize;

    if (isKasurOnly) {
      effectiveDivan =
          anchor == AnchorType.divan ? masterProduct.divan : 'Tanpa Divan';
      effectiveHeadboard = anchor == AnchorType.headboard
          ? masterProduct.headboard
          : 'Tanpa Headboard';
      effectiveSorong =
          anchor == AnchorType.sorong ? masterProduct.sorong : 'Tanpa Sorong';
    } else {
      final bool needsAutoSelect = anchor == AnchorType.divan
          ? (selectedHeadboard == null ||
              selectedHeadboard.trim().toLowerCase().contains('tanpa'))
          : (selectedDivan == null ||
              selectedDivan.trim().toLowerCase().contains('tanpa'));

      if (needsAutoSelect) {
        final officialSet = autoSelectPool.firstWhere(
          (p) =>
              p.isSet == true &&
              (anchor == AnchorType.kasur
                  ? !p.divan.toLowerCase().contains('tanpa')
                  : !p.headboard.toLowerCase().contains('tanpa')),
          orElse: () => autoSelectPool.firstWhere(
            (p) => anchor == AnchorType.kasur
                ? !p.divan.toLowerCase().contains('tanpa')
                : !p.headboard.toLowerCase().contains('tanpa'),
            orElse: () => autoSelectPool.isNotEmpty
                ? autoSelectPool.first
                : siblingsBySize.first,
          ),
        );
        effectiveDivan = anchor == AnchorType.divan
            ? masterProduct.divan
            : officialSet.divan;
        effectiveHeadboard = officialSet.headboard;
        effectiveSorong = officialSet.sorong;
      } else {
        effectiveDivan = anchor == AnchorType.divan
            ? masterProduct.divan
            : (selectedDivan ?? '');
        effectiveHeadboard = selectedHeadboard ?? 'Tanpa Headboard';
        effectiveSorong = selectedSorong ?? 'Tanpa Sorong';
      }
    }

    // ── 3. Filter Divan ──
    if (!availableDivans.contains(effectiveDivan)) {
      if (!isKasurOnly) {
        effectiveDivan = availableDivans.firstWhere(
          (d) => !d.trim().toLowerCase().contains('tanpa'),
          orElse: () => availableDivans.isNotEmpty
              ? availableDivans.first
              : 'Tanpa Divan',
        );
      } else {
        effectiveDivan = 'Tanpa Divan';
      }
    }
    final siblingsByDivan =
        siblingsBySize.where((p) => p.divan == effectiveDivan).toList();
    final broadByDivan =
        broadBySize.where((p) => p.divan == effectiveDivan).toList();

    // ── 4. Filter Headboard ──
    // Merge strict + broad sources so headboards from full-set rows are
    // discoverable even when the strict divan-only filter has none.
    final strictHeadboards = siblingsByDivan
        .map((p) => p.headboard)
        .where((h) => h.isNotEmpty)
        .toSet();
    final broadHeadboards =
        broadByDivan.map((p) => p.headboard).where((h) => h.isNotEmpty).toSet();
    final availableHeadboards =
        (strictHeadboards.union(broadHeadboards)).toList()..sort();

    if (!availableHeadboards.contains(effectiveHeadboard)) {
      if (!isKasurOnly) {
        effectiveHeadboard = availableHeadboards.firstWhere(
          (h) => !h.trim().toLowerCase().contains('tanpa'),
          orElse: () => availableHeadboards.isNotEmpty
              ? availableHeadboards.first
              : 'Tanpa Headboard',
        );
      } else {
        effectiveHeadboard = 'Tanpa Headboard';
      }
    }
    // Use both strict and broad to find rows with matching headboard
    final allByDivan = {...siblingsByDivan, ...broadByDivan}.toList();
    final siblingsByHeadboard =
        allByDivan.where((p) => p.headboard == effectiveHeadboard).toList();

    // ── 5. Filter Sorong ──
    final availableSorongs = siblingsByHeadboard
        .map((p) => p.sorong)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (!availableSorongs.contains(effectiveSorong)) {
      effectiveSorong =
          availableSorongs.isNotEmpty ? availableSorongs.first : 'Tanpa Sorong';
    }

    // ── 6. Active product (final SKU) ──
    final Product activeProduct = siblingsByHeadboard.firstWhere(
      (p) => p.sorong == effectiveSorong,
      orElse: () => siblingsByHeadboard.isNotEmpty
          ? siblingsByHeadboard.first
          : masterProduct,
    );

    // ── 7. Lookup resolution ──
    final kasurKey = activeProduct.kasur.trim().toLowerCase();
    final kasurLookups = (groupedLookups[kasurKey] ?? [])
        .where((l) => l.ukuran == effectiveSize)
        .toList();
    final effectiveKasurLookup = kasurLookups.isEmpty
        ? null
        : (selectedKasurLookup != null &&
                kasurLookups.any((l) => lKey(l) == lKey(selectedKasurLookup)))
            ? selectedKasurLookup
            : kasurLookups.first;

    List<ItemLookup> divanLookups = [];
    if ((!isKasurOnly || anchor == AnchorType.divan) &&
        !activeProduct.divan.toLowerCase().contains('tanpa')) {
      final divanKey = activeProduct.divan.trim().toLowerCase();
      divanLookups = (groupedLookups[divanKey] ?? [])
          .where((l) => l.ukuran == effectiveSize)
          .toList();
      if (divanLookups.isEmpty) {
        divanLookups = groupedLookups[divanKey] ?? [];
      }
    }
    final effectiveDivanLookup = divanLookups.isEmpty
        ? null
        : (selectedDivanLookup != null &&
                divanLookups.any((l) => lKey(l) == lKey(selectedDivanLookup)))
            ? selectedDivanLookup
            : divanLookups.first;

    List<ItemLookup> headboardLookups = [];
    if ((!isKasurOnly || anchor == AnchorType.headboard) &&
        !activeProduct.headboard.toLowerCase().contains('tanpa')) {
      final headboardKey = activeProduct.headboard.trim().toLowerCase();
      headboardLookups = (groupedLookups[headboardKey] ?? [])
          .where((l) => l.ukuran == effectiveSize)
          .toList();
      if (headboardLookups.isEmpty) {
        headboardLookups = groupedLookups[headboardKey] ?? [];
      }
    }
    final effectiveHeadboardLookup = headboardLookups.isEmpty
        ? null
        : (selectedHeadboardLookup != null &&
                headboardLookups
                    .any((l) => lKey(l) == lKey(selectedHeadboardLookup)))
            ? selectedHeadboardLookup
            : headboardLookups.first;

    List<ItemLookup> sorongLookups = [];
    if (!activeProduct.sorong.toLowerCase().contains('tanpa')) {
      final sorongKey = activeProduct.sorong.trim().toLowerCase();
      sorongLookups = (groupedLookups[sorongKey] ?? [])
          .where((l) => l.ukuran == effectiveSize)
          .toList();
      if (sorongLookups.isEmpty) {
        sorongLookups = groupedLookups[sorongKey] ?? [];
      }
    }
    final effectiveSorongLookup = sorongLookups.isEmpty
        ? null
        : (selectedSorongLookup != null &&
                sorongLookups.any((l) => lKey(l) == lKey(selectedSorongLookup)))
            ? selectedSorongLookup
            : sorongLookups.first;

    // ── 8. Derived totals ──
    final buildAnchor = anchor;
    final double anchoredKasurEup =
        buildAnchor == AnchorType.kasur ? activeProduct.eupKasur : 0.0;
    final double anchoredDivanEup =
        (buildAnchor == AnchorType.kasur || buildAnchor == AnchorType.divan)
            ? activeProduct.eupDivan
            : 0.0;
    final baseTotalEup = anchoredKasurEup +
        anchoredDivanEup +
        activeProduct.eupHeadboard +
        activeProduct.eupSorong;
    final maxLimits = [
      activeProduct.disc1,
      activeProduct.disc2,
      activeProduct.disc3,
      activeProduct.disc4,
      activeProduct.disc5,
      activeProduct.disc6,
      activeProduct.disc7,
      activeProduct.disc8,
    ].where((d) => d > 0).toList();

    final divansForConfigurator = isKasurOnly
        ? <String>[]
        : availableDivans
            .where((d) => d.trim().toLowerCase() != 'tanpa divan')
            .toList();
    final headboardsForConfigurator =
        isKasurOnly ? <String>[] : availableHeadboards;

    // Computed from the FULL available lists (not filtered by isKasurOnly)
    // so the "Beli Set" toggle is visible even when isKasurOnly = true.
    final bool hasSetOptions;
    if (anchor == AnchorType.kasur) {
      hasSetOptions = true;
    } else if (anchor == AnchorType.divan) {
      hasSetOptions = availableHeadboards.any(
        (h) => !h.trim().toLowerCase().contains('tanpa'),
      );
    } else {
      hasSetOptions = false;
    }

    return ResolvedVariant(
      activeProduct: activeProduct,
      effectiveSize: effectiveSize,
      effectiveDivan: effectiveDivan,
      effectiveHeadboard: effectiveHeadboard,
      effectiveSorong: effectiveSorong,
      availableSizes: availableSizes,
      availableDivans: availableDivans,
      availableHeadboards: availableHeadboards,
      availableSorongs: availableSorongs,
      divansForConfigurator: divansForConfigurator,
      headboardsForConfigurator: headboardsForConfigurator,
      hasSetOptions: hasSetOptions,
      kasurLookups: kasurLookups,
      effectiveKasurLookup: effectiveKasurLookup,
      divanLookups: divanLookups,
      effectiveDivanLookup: effectiveDivanLookup,
      headboardLookups: headboardLookups,
      effectiveHeadboardLookup: effectiveHeadboardLookup,
      sorongLookups: sorongLookups,
      effectiveSorongLookup: effectiveSorongLookup,
      baseTotalEup: baseTotalEup,
      maxLimits: maxLimits,
    );
  }
}
