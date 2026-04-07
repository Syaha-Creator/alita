/// Metadata toko + diskon saat menambah baris keranjang dari mode indirect.
class CartIndirectMeta {
  const CartIndirectMeta({
    required this.addressNumber,
    required this.alphaName,
    required this.address,
    required this.phone,
    required this.storeDiscounts,
    required this.discountDisplay,
  });

  final int addressNumber;
  final String alphaName;
  final String address;
  final String phone;
  final List<double> storeDiscounts;
  final String discountDisplay;
}
