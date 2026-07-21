import '../../cart/data/cart_item.dart';
import '../data/models/product.dart';

/// Typed `extra` untuk navigasi ke `/product/:id` saat membawa konteks edit
/// dari keranjang (produk + item cart yang sedang diedit + posisinya).
///
/// Navigasi tanpa konteks edit tetap memakai [Product] langsung sebagai
/// `extra` (lihat handling di `app_router.dart`).
class ProductDetailRouteArgs {
  const ProductDetailRouteArgs({
    required this.product,
    this.editItem,
    this.cartIndex,
  });

  final Product product;
  final CartItem? editItem;
  final int? cartIndex;
}
