import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/store_discount_calculator.dart';
import '../../auth/logic/auth_provider.dart';
import '../../../core/enums/sales_mode.dart';
import '../data/models/assigned_store.dart';
import '../data/services/indirect_assigned_stores_service.dart';
import '../data/services/indirect_store_discount_service.dart';
import 'indirect_session_state.dart';
import 'sales_mode_provider.dart';

final indirectSessionProvider =
    StateNotifierProvider<IndirectSessionNotifier, IndirectSessionState>(
  (ref) => IndirectSessionNotifier(ref),
);

class IndirectSessionNotifier extends StateNotifier<IndirectSessionState> {
  IndirectSessionNotifier(this._ref)
      : _discountService = IndirectStoreDiscountService(),
        super(const IndirectSessionState());

  final Ref _ref;
  final IndirectStoreDiscountService _discountService;

  Future<void> selectStore(AssignedStore? store) async {
    if (store == null) {
      state = const IndirectSessionState();
      return;
    }

    state = IndirectSessionState(
      selectedStore: store,
      isLoadingDiscounts: true,
    );

    final token = _ref.read(authProvider).accessToken;
    if (token.isEmpty) {
      state = IndirectSessionState(
        selectedStore: store,
        isLoadingDiscounts: false,
      );
      return;
    }

    try {
      final discounts = await _discountService.fetchDiscounts(
        token: token,
        addressNumber: store.addressNumber,
      );
      final display = StoreDiscountCalculator.formatDisplay(discounts);
      state = IndirectSessionState(
        selectedStore: store,
        storeDiscounts: discounts,
        isLoadingDiscounts: false,
        discountDisplay: display,
      );
    } catch (_) {
      state = IndirectSessionState(
        selectedStore: store,
        storeDiscounts: const [],
        isLoadingDiscounts: false,
        discountDisplay: '',
      );
    }
  }

  void clear() {
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