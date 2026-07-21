import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alitapricelist/core/services/storage_service.dart';
import 'package:alitapricelist/core/utils/log.dart';

import '../data/quotation_model.dart';

/// Manages the list of locally-saved quotation drafts.
///
/// Data is persisted as JSON on disk ([StorageService]) to avoid huge SP channel payloads.
class QuotationListNotifier extends StateNotifier<List<QuotationModel>> {
  QuotationListNotifier() : super([]) {
    _load();
  }

  bool _loadComplete = false;

  Future<void> _load() async {
    try {
      final raw = await StorageService.loadQuotationsJson();
      if (raw.isNotEmpty) {
        final loaded = QuotationModel.decodeList(raw);
        state = loaded;
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'Quotation._load');
    } finally {
      _loadComplete = true;
    }
  }

  Future<void> _save() async {
    try {
      final encoded = QuotationModel.encodeList(state);

      // Verify the encoded string can be decoded back (safety net)
      final verified = QuotationModel.decodeList(encoded);
      if (verified.length != state.length) {
        Log.warning(
          'Serialization mismatch: state=${state.length} decoded=${verified.length}',
          tag: 'Quotation',
        );
      }

      await StorageService.saveQuotationsJson(encoded);
    } catch (e, st) {
      Log.error(e, st, reason: 'Quotation._save');
    }
  }

  /// Waits for the initial [_load] to finish before any mutation runs —
  /// otherwise a mutation racing ahead of `_load()` would operate on the
  /// empty initial state, and `_load()` completing afterwards would then
  /// clobber the mutation back to the pre-mutation (on-disk) data.
  Future<void> _ensureLoaded() async {
    if (_loadComplete) return;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return !_loadComplete;
    });
  }

  /// Add a new quotation draft (newest first).
  Future<void> add(QuotationModel quotation) async {
    await _ensureLoaded();
    state = [quotation, ...state];
    await _save();
  }

  /// Remove a draft by its ID.
  Future<void> remove(String id) async {
    await _ensureLoaded();
    state = state.where((q) => q.id != id).toList();
    await _save();
  }

  /// Replace an existing draft (e.g. after re-edit).
  Future<void> update(QuotationModel quotation) async {
    await _ensureLoaded();
    state = [
      for (final q in state)
        if (q.id == quotation.id) quotation else q,
    ];
    await _save();
  }
}

final quotationListProvider =
    StateNotifierProvider<QuotationListNotifier, List<QuotationModel>>(
  (ref) => QuotationListNotifier(),
);

/// Holds the quotation being edited so customer data survives
/// a round-trip to the catalogue for adding more products.
/// Set when "Tambah Item" is tapped; cleared after checkout / re-save.
final activeDraftProvider = StateProvider<QuotationModel?>((ref) => null);
