import '../data/models/assigned_store.dart';

/// Toko assign terpilih + diskon toko dari API (sesi indirect).
class IndirectSessionState {
  const IndirectSessionState({
    this.selectedStore,
    this.storeDiscounts = const [],
    this.isLoadingDiscounts = false,
    this.discountDisplay = '',
  });

  final AssignedStore? selectedStore;
  final List<double> storeDiscounts;
  final bool isLoadingDiscounts;
  final String discountDisplay;

  bool get hasStore => selectedStore != null;
  bool get hasDiscounts => storeDiscounts.isNotEmpty;

  IndirectSessionState copyWith({
    AssignedStore? selectedStore,
    List<double>? storeDiscounts,
    bool? isLoadingDiscounts,
    String? discountDisplay,
    bool clearStore = false,
  }) {
    return IndirectSessionState(
      selectedStore: clearStore ? null : (selectedStore ?? this.selectedStore),
      storeDiscounts: clearStore ? const [] : (storeDiscounts ?? this.storeDiscounts),
      isLoadingDiscounts: isLoadingDiscounts ?? this.isLoadingDiscounts,
      discountDisplay:
          clearStore ? '' : (discountDisplay ?? this.discountDisplay),
    );
  }
}
