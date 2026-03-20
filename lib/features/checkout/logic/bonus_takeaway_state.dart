import '../../cart/data/cart_item.dart';

/// Manages take-away bonus state (checked SKUs + per-bonus quantities).
///
/// Extracted from [CheckoutPage] to reduce state field sprawl.
/// All methods are pure state mutations — the caller is responsible for
/// triggering UI rebuild (e.g. `setState`).
class BonusTakeAwayState {
  final Set<String> _checkedSkus = <String>{};
  final Map<String, int> _qtys = {};

  String _key(int itemIndex, CartBonusSnapshot bonus) =>
      '${itemIndex}_${bonus.sku.isNotEmpty ? bonus.sku : bonus.name}';

  bool isChecked(int itemIndex, CartBonusSnapshot bonus) =>
      _checkedSkus.contains(_key(itemIndex, bonus));

  int currentQty(int itemIndex, CartBonusSnapshot bonus) {
    final raw = _qtys[_key(itemIndex, bonus)] ?? 0;
    return raw.clamp(0, bonus.qty);
  }

  void toggle(int itemIndex, CartBonusSnapshot bonus, bool checked) {
    final k = _key(itemIndex, bonus);
    if (checked) {
      _checkedSkus.add(k);
      _qtys[k] = (_qtys[k] ?? 0).clamp(1, bonus.qty);
    } else {
      _checkedSkus.remove(k);
      _qtys[k] = 0;
    }
  }

  void setQty(int itemIndex, CartBonusSnapshot bonus, int value) {
    final k = _key(itemIndex, bonus);
    final clamped = value.clamp(0, bonus.qty);
    _qtys[k] = clamped;
    if (clamped <= 0) {
      _checkedSkus.remove(k);
    } else {
      _checkedSkus.add(k);
    }
  }
}
