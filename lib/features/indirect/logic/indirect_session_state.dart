import '../data/models/assigned_store.dart';

/// Toko assign terpilih + diskon toko dari API (sesi indirect).
class IndirectSessionState {
  const IndirectSessionState({
    this.selectedStore,
    this.storeDiscounts = const [],
    this.isLoadingDiscounts = false,
    this.discountDisplay = '',
    this.discountCode = '',
  });

  final AssignedStore? selectedStore;
  final List<double> storeDiscounts;
  final bool isLoadingDiscounts;
  final String discountDisplay;
  /// Kode diskon toko dari API (`disc_name`), dipakai sebagai `code_standart`
  /// di baris `order_letter_discounts` indirect.
  final String discountCode;

  bool get hasStore => selectedStore != null;
  bool get hasDiscounts => storeDiscounts.isNotEmpty;

  IndirectSessionState copyWith({
    AssignedStore? selectedStore,
    List<double>? storeDiscounts,
    bool? isLoadingDiscounts,
    String? discountDisplay,
    String? discountCode,
    bool clearStore = false,
  }) {
    return IndirectSessionState(
      selectedStore: clearStore ? null : (selectedStore ?? this.selectedStore),
      storeDiscounts: clearStore ? const [] : (storeDiscounts ?? this.storeDiscounts),
      isLoadingDiscounts: isLoadingDiscounts ?? this.isLoadingDiscounts,
      discountDisplay: clearStore ? '' : (discountDisplay ?? this.discountDisplay),
      discountCode: clearStore ? '' : (discountCode ?? this.discountCode),
    );
  }
}
