import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/enums/sales_mode.dart';

const _prefsKey = 'sales_mode_v1';

/// Mode pricelist: direct vs indirect (persist ringan di SharedPreferences).
class SalesModeNotifier extends StateNotifier<SalesMode> {
  SalesModeNotifier() : super(SalesMode.direct) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == 'indirect') {
      state = SalesMode.indirect;
    } else {
      state = SalesMode.direct;
    }
  }

  Future<void> setMode(SalesMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      mode == SalesMode.indirect ? 'indirect' : 'direct',
    );
  }
}

final salesModeProvider =
    StateNotifierProvider<SalesModeNotifier, SalesMode>((ref) {
  return SalesModeNotifier();
});
