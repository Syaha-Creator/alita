import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';

// ─────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────

class MasterDataState {
  final List<Map<String, dynamic>> areas;
  final List<Map<String, dynamic>> channels;
  final List<Map<String, dynamic>> brands;
  final bool isLoading;
  final String? error;

  const MasterDataState({
    this.areas = const [],
    this.channels = const [],
    this.brands = const [],
    this.isLoading = true,
    this.error,
  });

  MasterDataState copyWith({
    List<Map<String, dynamic>>? areas,
    List<Map<String, dynamic>>? channels,
    List<Map<String, dynamic>>? brands,
    bool? isLoading,
    String? error,
  }) {
    return MasterDataState(
      areas: areas ?? this.areas,
      channels: channels ?? this.channels,
      brands: brands ?? this.brands,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────────────────

class MasterDataNotifier extends StateNotifier<MasterDataState> {
  MasterDataNotifier() : super(const MasterDataState()) {
    _loadFromCache();
  }

  static final ApiClient _api = ApiClient.instance;

  /// Step 1: Read from local cache first (instant UI).
  /// Step 2: If a valid token exists, sync from API in background.
  Future<void> _loadFromCache() async {
    try {
      final areasJson = await StorageService.loadCachedAreas();
      final channelsJson = await StorageService.loadCachedChannels();
      final brandsJson = await StorageService.loadCachedBrands();

      _setState(MasterDataState(
        areas: _parseJsonList(areasJson),
        channels: _parseJsonList(channelsJson),
        brands: _parseJsonList(brandsJson),
        isLoading: false,
      ));

      final token = await StorageService.loadAccessToken();
      if (token.isNotEmpty) {
        unawaited(syncMasterData());
      }
    } catch (e) {
      debugPrint('MasterData cache load error: $e');
      try {
        _setState(state.copyWith(isLoading: false, error: e.toString()));
      } on StateError {
        // Notifier disposed; ignore
      }
    }
  }

  /// Updates state only if this notifier has not been disposed (e.g. after
  /// ref.invalidate on login). Prevents StateError when async work completes
  /// after the notifier was disposed.
  void _setState(MasterDataState value) {
    try {
      state = value;
    } on StateError {
      // Notifier was disposed (e.g. invalidated on login); ignore
    }
  }

  /// Fetch fresh master data from the on-premise API and save to cache.
  ///
  /// Performs 3 parallel GET requests (pl_areas, pl_channels, pl_brands).
  /// On success the raw JSON is persisted via [StorageService] and the
  /// parsed lists are pushed into state.
  Future<void> syncMasterData() async {
    _setState(state.copyWith(isLoading: true, error: null));

    try {
      final results = await Future.wait([
        _api.get('/pl_areas'),
        _api.get('/pl_channels'),
        _api.get('/pl_brands'),
      ]);

      final areasOk = results[0].statusCode == 200;
      final channelsOk = results[1].statusCode == 200;
      final brandsOk = results[2].statusCode == 200;

      await StorageService.saveMasterData(
        areas: areasOk ? results[0].body : null,
        channels: channelsOk ? results[1].body : null,
        brands: brandsOk ? results[2].body : null,
      );

      final currentState = state;
      _setState(MasterDataState(
        areas: areasOk ? _parseJsonList(results[0].body) : currentState.areas,
        channels: channelsOk ? _parseJsonList(results[1].body) : currentState.channels,
        brands: brandsOk ? _parseJsonList(results[2].body) : currentState.brands,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('MasterData sync error: $e');
      try {
        _setState(state.copyWith(isLoading: false, error: e.toString()));
      } on StateError {
        // Notifier disposed; ignore
      }
    }
  }

  /// Safely parses a JSON string into a list of maps.
  /// Supports: [...], {"data": [...]}, {"result": {"data": [...]}},
  /// {"pl_areas": [...]}, {"result": {"pl_areas": [...]}}, etc.
  List<Map<String, dynamic>> _parseJsonList(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);

      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }

      if (decoded is Map<String, dynamic>) {
        // Top-level keys
        for (final key in ['data', 'pl_areas', 'pl_channels', 'pl_brands']) {
          if (decoded[key] is List) {
            return (decoded[key] as List)
                .whereType<Map<String, dynamic>>()
                .toList();
          }
        }
        // Nested under "result" (e.g. {"status":"success","result":{"data":[...]}})
        final result = decoded['result'];
        if (result is Map<String, dynamic>) {
          for (final key in ['data', 'pl_areas', 'pl_channels', 'pl_brands']) {
            if (result[key] is List) {
              return (result[key] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList();
            }
          }
        }
      }

      return [];
    } catch (e) {
      debugPrint('_parseJsonList error: $e');
      return [];
    }
  }
}

// ─────────────────────────────────────────────────────────
//  Provider
// ─────────────────────────────────────────────────────────

final masterDataProvider =
    StateNotifierProvider<MasterDataNotifier, MasterDataState>(
  (ref) => MasterDataNotifier(),
);
