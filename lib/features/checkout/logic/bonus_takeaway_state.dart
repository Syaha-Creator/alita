import '../../cart/data/cart_item.dart';

/// Manages take-away bonus state (checked SKUs + per-bonus quantities).
///
/// Extracted from [CheckoutPage] to reduce state field sprawl.
/// All methods are pure state mutations — the caller is responsible for
/// triggering UI rebuild (e.g. `setState`).
///
/// [maxQty] must be the **effective** ceiling shown in UI
/// (`bonus.qty * cartItem.quantity`). Clamping only to `bonus.qty` made the
/// "+" stepper look enabled while the stored value never increased.
class BonusTakeAwayState {
  final Set<String> _checkedSkus = <String>{};
  final Map<String, int> _qtys = {};

  String _key(int itemIndex, CartBonusSnapshot bonus) =>
      '${itemIndex}_${bonus.sku.isNotEmpty ? bonus.sku : bonus.name}';

  bool isChecked(int itemIndex, CartBonusSnapshot bonus) =>
      _checkedSkus.contains(_key(itemIndex, bonus));

  int currentQty(
    int itemIndex,
    CartBonusSnapshot bonus, {
    required int maxQty,
  }) {
    final ceiling = maxQty < 0 ? 0 : maxQty;
    final raw = _qtys[_key(itemIndex, bonus)] ?? 0;
    return raw.clamp(0, ceiling);
  }

  void toggle(
    int itemIndex,
    CartBonusSnapshot bonus,
    bool checked, {
    required int maxQty,
  }) {
    final k = _key(itemIndex, bonus);
    final ceiling = maxQty < 0 ? 0 : maxQty;
    if (checked) {
      _checkedSkus.add(k);
      final existing = _qtys[k] ?? 0;
      // Saat dicentang, mulai dari 1 (atau pertahankan qty lama) sampai ceiling.
      _qtys[k] = (existing <= 0 ? 1 : existing).clamp(1, ceiling);
    } else {
      _checkedSkus.remove(k);
      _qtys[k] = 0;
    }
  }

  void setQty(
    int itemIndex,
    CartBonusSnapshot bonus,
    int value, {
    required int maxQty,
  }) {
    final k = _key(itemIndex, bonus);
    final ceiling = maxQty < 0 ? 0 : maxQty;
    final clamped = value.clamp(0, ceiling);
    _qtys[k] = clamped;
    if (clamped <= 0) {
      _checkedSkus.remove(k);
    } else {
      _checkedSkus.add(k);
    }
  }

  /// Untuk persist ke [QuotationModel] / JSON.
  List<String> get bonusCheckedKeysSnapshot => _checkedSkus.toList();

  Map<String, int> get bonusQtySnapshot => Map<String, int>.from(_qtys);

  /// Pulihkan dari draft penawaran (kunci sama dengan [_key]).
  void applyPersistedSnapshot({
    List<String> checkedKeys = const [],
    Map<String, int> qtyByKey = const {},
  }) {
    _checkedSkus
      ..clear()
      ..addAll(checkedKeys);
    _qtys
      ..clear()
      ..addAll(qtyByKey);
  }
}
