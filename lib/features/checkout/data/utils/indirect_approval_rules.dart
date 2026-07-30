import '../../../cart/data/cart_item.dart';
import '../../../history/data/models/order_history.dart';

/// Aturan persetujuan pesanan **indirect (SO)** — mirror logic checkout create.
///
/// Penting: **diskon tambahan (d1/d2/d3) hanya ke RSM**, bukan ASM.
/// ASM hanya untuk customer baru, ukuran custom, FOC, Medan, dll.
class IndirectApprovalRules {
  const IndirectApprovalRules._();

  static bool isIndirectCart(List<CartItem> cartItems) =>
      cartItems.any((e) => e.isIndirectSale);

  /// True jika shipping tujuan berbeda dari alamat customer ("Customer Baru").
  ///
  /// **Create mode** ([editOrder] null): pakai toggle UI checkout langsung.
  ///
  /// **Edit mode** ([editOrder] non-null): field pengiriman di checkout page
  /// disembunyikan saat edit item, dan toggle UI-nya (`isShippingSameAsCustomer`
  /// / `isReceiverBranchMode`) TIDAK direstore dari order lama — nilainya
  /// selalu default. Kalau dipakai apa adanya, syarat ASM "Customer Baru"
  /// yang berlaku saat order pertama dibuat akan diam-diam hilang begitu
  /// item diedit (baris approval lama dihapus lalu tidak dibuat ulang).
  /// Jadi untuk edit mode kita derive langsung dari data order:
  /// `ship_to_name` berbeda dari `customer_name` → dianggap Customer Baru.
  static bool isCustomerBaruShipping({
    required OrderHistory? editOrder,
    required bool isShippingSameAsCustomer,
    required bool isReceiverBranchMode,
  }) {
    if (editOrder != null) {
      final shipToName = editOrder.shipToName.trim();
      final customerName = editOrder.customerName.trim();
      return shipToName.isNotEmpty && shipToName != customerName;
    }
    return !isShippingSameAsCustomer && !isReceiverBranchMode;
  }

  /// ASM wajib (acknowledgment 0%). **Tidak** termasuk diskon tambahan.
  static bool requiresAsm({
    required bool isCustomerBaruShipping,
    required bool hasNewCustomerStoreItem,
    required bool hasFocVoucherItem,
    required bool hasMedanPricelistItem,
    required bool hasCustomSizeItem,
  }) {
    return isCustomerBaruShipping ||
        hasNewCustomerStoreItem ||
        hasFocVoucherItem ||
        hasMedanPricelistItem ||
        hasCustomSizeItem;
  }

  /// RSM wajib: diskon tambahan d1–d3, bonus diubah, atau Klaus.
  ///
  /// Selaras [CheckoutDiscountBuilder] (indirect):
  /// - d4 → Analyst (bukan RSM)
  /// - customer baru toko → ASM ([requiresAsm]), bukan RSM
  static bool requiresRsm({
    required List<CartItem> cartItems,
    required bool isKlausRuleActive,
  }) {
    if (isKlausRuleActive) return true;
    return cartItems.any((item) {
      if (!item.isIndirectSale) return false;
      return item.discount1 > 0 ||
          item.discount2 > 0 ||
          item.discount3 > 0 ||
          item.isBonusCustomized;
    });
  }

  /// Sama seperti [CheckoutPage] saat create: tidak ada baris approval pending.
  static bool autoApprove({
    required List<CartItem> cartItems,
    required bool isCustomerBaruShipping,
    required bool hasNewCustomerStoreItem,
    required bool hasFocVoucherItem,
    required bool hasMedanPricelistItem,
    required bool hasCustomSizeItem,
    required bool isKlausRuleActive,
  }) {
    if (!isIndirectCart(cartItems)) return false;
    return !requiresAsm(
          isCustomerBaruShipping: isCustomerBaruShipping,
          hasNewCustomerStoreItem: hasNewCustomerStoreItem,
          hasFocVoucherItem: hasFocVoucherItem,
          hasMedanPricelistItem: hasMedanPricelistItem,
          hasCustomSizeItem: hasCustomSizeItem,
        ) &&
        !requiresRsm(
          cartItems: cartItems,
          isKlausRuleActive: isKlausRuleActive,
        );
  }

  /// Helper: derive flags dari cart (tanpa konteks shipping UI).
  static bool cartHasNewCustomerStore(List<CartItem> cartItems) =>
      cartItems.any((item) => item.isNewCustomerStore);

  static bool cartHasFocVoucher(List<CartItem> cartItems) =>
      cartItems.any((item) => item.isFocVoucherActive);

  static bool cartHasMedanArea(List<CartItem> cartItems) => cartItems.any(
        (item) => item.pricelistArea.trim().toLowerCase() == 'medan',
      );

  static bool cartHasCustomSize(List<CartItem> cartItems) =>
      cartItems.any((item) => item.isCustomSize);
}
