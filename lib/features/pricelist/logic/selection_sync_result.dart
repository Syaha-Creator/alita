import '../data/models/item_lookup.dart';

/// Result of comparing current vs effective selection state.
///
/// If [hasChanges] is true, the page should apply the new values via setState.
class SelectionSyncResult {
  final bool hasChanges;
  final String? divan;
  final String? headboard;
  final String? sorong;
  final ItemLookup? kasurLookup;
  final ItemLookup? divanLookup;
  final ItemLookup? headboardLookup;
  final ItemLookup? sorongLookup;

  const SelectionSyncResult._({
    required this.hasChanges,
    this.divan,
    this.headboard,
    this.sorong,
    this.kasurLookup,
    this.divanLookup,
    this.headboardLookup,
    this.sorongLookup,
  });

  factory SelectionSyncResult.noChange() =>
      const SelectionSyncResult._(hasChanges: false);

  factory SelectionSyncResult.changed({
    required String? divan,
    required String? headboard,
    required String? sorong,
    required ItemLookup? kasurLookup,
    required ItemLookup? divanLookup,
    required ItemLookup? headboardLookup,
    required ItemLookup? sorongLookup,
  }) =>
      SelectionSyncResult._(
        hasChanges: true,
        divan: divan,
        headboard: headboard,
        sorong: sorong,
        kasurLookup: kasurLookup,
        divanLookup: divanLookup,
        headboardLookup: headboardLookup,
        sorongLookup: sorongLookup,
      );

  /// Pure computation: diff current state vs effective values.
  static SelectionSyncResult compute({
    required bool isKasurOnly,
    required String? currentDivan,
    required String? currentHeadboard,
    required String? currentSorong,
    required ItemLookup? currentKasurLookup,
    required ItemLookup? currentDivanLookup,
    required ItemLookup? currentHeadboardLookup,
    required ItemLookup? currentSorongLookup,
    required String effectiveDivan,
    required String effectiveHeadboard,
    required String effectiveSorong,
    required ItemLookup? effectiveKasurLookup,
    required ItemLookup? effectiveDivanLookup,
    required ItemLookup? effectiveHeadboardLookup,
    required ItemLookup? effectiveSorongLookup,
    required bool isKasurCustom,
    required bool isDivanCustom,
    required bool isHeadboardCustom,
    required bool isSorongCustom,
  }) {
    var shouldUpdate = false;

    String? nextDivan = currentDivan;
    String? nextHeadboard = currentHeadboard;
    String? nextSorong = currentSorong;
    ItemLookup? nextKasurLookup = currentKasurLookup;
    ItemLookup? nextDivanLookup = currentDivanLookup;
    ItemLookup? nextHeadboardLookup = currentHeadboardLookup;
    ItemLookup? nextSorongLookup = currentSorongLookup;

    if (!isKasurOnly) {
      if (nextDivan != effectiveDivan) {
        nextDivan = effectiveDivan;
        shouldUpdate = true;
      }
      if (nextHeadboard != effectiveHeadboard) {
        nextHeadboard = effectiveHeadboard;
        shouldUpdate = true;
      }
      if (nextSorong != effectiveSorong) {
        nextSorong = effectiveSorong;
        shouldUpdate = true;
      }
    }

    if (!isKasurCustom &&
        effectiveKasurLookup != null &&
        _key(nextKasurLookup) != _key(effectiveKasurLookup)) {
      nextKasurLookup = effectiveKasurLookup;
      shouldUpdate = true;
    }
    if (!isDivanCustom &&
        effectiveDivanLookup != null &&
        _key(nextDivanLookup) != _key(effectiveDivanLookup)) {
      nextDivanLookup = effectiveDivanLookup;
      shouldUpdate = true;
    }
    if (!isHeadboardCustom &&
        effectiveHeadboardLookup != null &&
        _key(nextHeadboardLookup) != _key(effectiveHeadboardLookup)) {
      nextHeadboardLookup = effectiveHeadboardLookup;
      shouldUpdate = true;
    }
    if (!isSorongCustom &&
        effectiveSorongLookup != null &&
        _key(nextSorongLookup) != _key(effectiveSorongLookup)) {
      nextSorongLookup = effectiveSorongLookup;
      shouldUpdate = true;
    }

    if (!shouldUpdate) return SelectionSyncResult.noChange();

    return SelectionSyncResult.changed(
      divan: nextDivan,
      headboard: nextHeadboard,
      sorong: nextSorong,
      kasurLookup: nextKasurLookup,
      divanLookup: nextDivanLookup,
      headboardLookup: nextHeadboardLookup,
      sorongLookup: nextSorongLookup,
    );
  }

  static String _key(ItemLookup? lookup) {
    if (lookup == null) return '';
    final tipe = lookup.tipe.trim().toLowerCase();
    final ukuran = lookup.ukuran.trim().toLowerCase();
    final itemNum = lookup.itemNum.trim().toLowerCase();
    final kain = (lookup.jenisKain ?? '').trim().toLowerCase();
    final warna = (lookup.warnaKain ?? '').trim().toLowerCase();
    return '$tipe|$ukuran|$itemNum|$kain|$warna';
  }
}
