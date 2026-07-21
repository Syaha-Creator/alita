import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/enums/sales_mode.dart';

const _prefsKey = 'sales_mode_v1';

/// Mode pricelist: direct vs indirect (persist ringan di SharedPreferences).
class SalesModeNotifier extends StateNotifier<SalesMode> {
  SalesModeNotifier() : super(SalesMode.direct) {
    _load();
  }

  bool _loadComplete = false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == 'indirect') {
        state = SalesMode.indirect;
      } else {
        state = SalesMode.direct;
      }
    } finally {
      _loadComplete = true;
    }
  }

  /// Waits for the initial [_load] to finish before [setMode] runs —
  /// otherwise a mode switch racing ahead of the load would be visibly set,
  /// then immediately clobbered back to the persisted (stale) mode once
  /// `_load()` finishes afterwards.
  Future<void> _ensureLoaded() async {
    if (_loadComplete) return;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return !_loadComplete;
    });
  }

  Future<void> setMode(SalesMode mode) async {
    await _ensureLoaded();
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
