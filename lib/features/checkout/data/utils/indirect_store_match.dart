import '../../../cart/data/cart_item.dart';
import '../../../../core/utils/store_display_utils.dart';
import '../models/store_model.dart';

/// Mencocokkan baris keranjang indirect dengan entri `/all_stores` berdasarkan nama toko.
StoreModel? matchWorkPlaceForIndirectCartLine(
  List<StoreModel> stores,
  CartItem item,
) {
  if (!item.isIndirectSale) return null;
  final needle = StoreDisplayUtils.assignedStoreTitle(item.indirectStoreAlphaName)
      .toLowerCase()
      .trim();
  if (needle.isEmpty) return null;

  StoreModel? prefixMatch;
  for (final s in stores) {
    final n = s.name.trim().toLowerCase();
    if (n.isEmpty) continue;
    if (n == needle) return s;
    if (needle.startsWith(n) || n.startsWith(needle)) {
      prefixMatch ??= s;
    }
  }
  return prefixMatch;
}
