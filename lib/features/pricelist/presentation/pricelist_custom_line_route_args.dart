import '../../cart/data/cart_item.dart';

/// Typed `extra` untuk navigasi ke `/pricelist/custom_line` saat mengedit
/// baris custom yang sudah ada di keranjang.
class PricelistCustomLineRouteArgs {
  const PricelistCustomLineRouteArgs({
    this.editItem,
    this.cartIndex,
  });

  final CartItem? editItem;
  final int? cartIndex;
}
