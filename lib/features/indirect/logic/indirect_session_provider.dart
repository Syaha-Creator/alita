import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/sales_mode.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/store_discount_calculator.dart';
import '../../auth/logic/auth_provider.dart';
import '../../cart/logic/cart_provider.dart';
import '../data/models/assigned_store.dart';
import '../data/services/indirect_assigned_stores_service.dart';
import '../data/services/indirect_store_discount_service.dart';
import 'indirect_session_state.dart';
import 'sales_mode_provider.dart';

final indirectSessionProvider =
    NotifierProvider<IndirectSessionNotifier, IndirectSessionState>(
  IndirectSessionNotifier.new,
);

class IndirectSessionNotifier extends Notifier<IndirectSessionState> {
  IndirectSessionNotifier({IndirectStoreDiscountService? discountService})
      : _discountService = discountService ?? IndirectStoreDiscountService();

  final IndirectStoreDiscountService _discountService;

  @override
  IndirectSessionState build() => const IndirectSessionState();

  // Track alamat toko yang sedang di-fetch. Jika user ganti toko sebelum
  // response tiba, hasilnya diabaikan (stale cancellation pattern).
  int? _pendingFetchAddressNumber;

  /// Returns `false` when the change is blocked because the cart already has
  /// items for another store (caller should show user feedback).
  ///
  /// Re-selecting the same store, or selecting the first store while none is
  /// set yet, is always allowed.
  Future<bool> selectStore(AssignedStore? store) async {
    final current = state.selectedStore;
    final cartHasItems = ref.read(cartProvider).isNotEmpty;
    if (cartHasItems && current != null) {
      final isSameStore = store != null &&
          store.addressNumber == current.addressNumber;
      if (!isSameStore) {
        Log.info(
          'Blocked store change while cart has ${ref.read(cartProvider).length} '
          'item(s); clear cart first',
          tag: 'Indirect',
        );
        return false;
      }
    }

    if (store == null) {
      _pendingFetchAddressNumber = null;
      state = const IndirectSessionState();
      return true;
    }

    // Tandai fetch ini milik toko yang baru dipilih.
    _pendingFetchAddressNumber = store.addressNumber;

    state = IndirectSessionState(
      selectedStore: store,
      isLoadingDiscounts: true,
    );

    final token = ref.read(authProvider).accessToken;
    if (token.isEmpty) {
      if (_pendingFetchAddressNumber != store.addressNumber) return true;
      state = IndirectSessionState(
        selectedStore: store,
        isLoadingDiscounts: false,
      );
      return true;
    }

    try {
      final result = await _discountService.fetchDiscounts(
        token: token,
        addressNumber: store.addressNumber,
      );

      // Abaikan hasil jika user sudah memilih toko lain.
      if (_pendingFetchAddressNumber != store.addressNumber) return true;

      final display = StoreDiscountCalculator.formatDisplay(result.discounts);
      state = IndirectSessionState(
        selectedStore: store,
        storeDiscounts: result.discounts,
        isLoadingDiscounts: false,
        discountDisplay: display,
        discountCode: result.discountCode,
      );
    } catch (e, st) {
      Log.warning(
        'IndirectSession: gagal fetch diskon toko — $e',
        tag: 'Indirect',
      );
      Log.error(e, st, reason: 'IndirectSessionNotifier.selectStore');
      if (_pendingFetchAddressNumber != store.addressNumber) return true;
      state = IndirectSessionState(
        selectedStore: store,
        storeDiscounts: const [],
        isLoadingDiscounts: false,
        discountDisplay: '',
        discountCode: '',
      );
    }
    return true;
  }

  void clear() {
    // Reset the in-flight guard too — otherwise a fetch already running for
    // the previously selected store would still pass the staleness check in
    // selectStore() (same addressNumber) and clobber this cleared state once
    // it resolves.
    _pendingFetchAddressNumber = null;
    state = const IndirectSessionState();
  }
}

/// Daftar toko assign (hanya mode indirect + sales code tersedia).
final assignedStoresProvider =
    FutureProvider.autoDispose<List<AssignedStore>>((ref) async {
  final mode = ref.watch(salesModeProvider);
  if (mode != SalesMode.indirect) return [];

  final addressNumber = ref.watch(authProvider.select((a) => a.addressNumber));
  if (addressNumber == null || addressNumber.isEmpty) return [];

  return IndirectAssignedStoresService().fetchBySalesCode(addressNumber);
});