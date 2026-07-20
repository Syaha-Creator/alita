import '../../../cart/data/cart_item.dart';

/// Aturan persetujuan pesanan **indirect (SO)** — mirror logic checkout create.
///
/// Penting: **diskon tambahan (d1/d2/d3) hanya ke RSM**, bukan ASM.
/// ASM hanya untuk customer baru, ukuran custom, FOC, Medan, dll.
class IndirectApprovalRules {
  const IndirectApprovalRules._();

  static bool isIndirectCart(List<CartItem> cartItems) =>
      cartItems.any((e) => e.isIndirectSale);

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
