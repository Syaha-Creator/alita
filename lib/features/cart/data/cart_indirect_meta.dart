/// Metadata toko + diskon saat menambah baris keranjang dari mode indirect.
class CartIndirectMeta {
  const CartIndirectMeta({
    required this.addressNumber,
    required this.alphaName,
    required this.address,
    required this.phone,
    required this.storeDiscounts,
    required this.discountDisplay,
    this.isNewCustomer = false,
    this.discountCode = '',
  });

  final int addressNumber;
  final String alphaName;
  final String address;
  final String phone;
  final List<double> storeDiscounts;
  final String discountDisplay;
  /// True jika toko ditandai sebagai customer baru oleh API (search_type).
  /// Order indirect ke customer baru wajib mendapat persetujuan ASM.
  final bool isNewCustomer;
  /// Kode diskon toko dari API (`disc_name`), dipakai sebagai `code_standart`
  /// di baris `order_letter_discounts` indirect.
  final String discountCode;
}
