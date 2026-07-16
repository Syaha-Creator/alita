import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/enums/order_status.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/api_session_expired.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/app_telemetry.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/retry.dart';
import '../../auth/logic/auth_provider.dart';
import '../../profile/logic/profile_provider.dart';
import 'approval_inbox_utils.dart';
import 'approval_prior_check.dart';

export 'approval_inbox_utils.dart';

// ── Geotagging: alamat + koordinat untuk payload approval ───────
class ApprovalLocation {
  final String address;
  final double latitude;
  final double longitude;

  /// True jika posisi berasal dari cache OS yang diambil paksa (tombol
  /// "Lanjutkan tanpa lokasi presisi") tanpa filter kesegaran — dipakai agar
  /// [address] ditandai sebagai perkiraan, bukan fix GPS langsung.
  final bool isApproximate;

  const ApprovalLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isApproximate = false,
  });
}

// ── State ─────────────────────────────────────────────────────
class ApprovalInboxState {
  final bool isLoading;
  final String? error;
  final List<dynamic> pendingApprovals;
  final List<dynamic> historyApprovals;

  /// Filter rentang tanggal eksplisit. Keduanya null → API tanpa
  /// `date_from`/`date_to` → backend default **bulan berjalan**.
  final DateTime? startDate;
  final DateTime? endDate;

  /// Filter tab **Selesai** menurut `work_place_name` (null = semua lokasi).
  final String? historyWorkPlaceFilter;

  /// Query pencarian teks bebas (no SP atau nama customer).
  final String searchQuery;

  /// Waktu fetch sukses terakhir — untuk skip re-fetch yang terlalu dekat.
  final DateTime? lastFetchedAt;

  const ApprovalInboxState({
    this.isLoading = true,
    this.error,
    this.pendingApprovals = const [],
    this.historyApprovals = const [],
    this.startDate,
    this.endDate,
    this.historyWorkPlaceFilter,
    this.searchQuery = '',
    this.lastFetchedAt,
  });

  ApprovalInboxState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<dynamic>? pendingApprovals,
    List<dynamic>? historyApprovals,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDateRange = false,
    bool updateHistoryWorkPlaceFilter = false,
    String? historyWorkPlaceFilter,
    String? searchQuery,
    DateTime? lastFetchedAt,
  }) {
    return ApprovalInboxState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      historyApprovals: historyApprovals ?? this.historyApprovals,
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
      historyWorkPlaceFilter: updateHistoryWorkPlaceFilter
          ? historyWorkPlaceFilter
          : this.historyWorkPlaceFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }

  /// Daftar unik lokasi toko dari riwayat (urut A–Z).
  List<String> get historyWorkPlaceOptions =>
      approvalHistoryWorkPlaceOptions(historyApprovals);

  /// Pending setelah filter pencarian.
  List<dynamic> get filteredPendingApprovals =>
      approvalFilteredByQuery(pendingApprovals, searchQuery);

  /// Riwayat setelah filter lokasi + pencarian.
  List<dynamic> get filteredHistoryApprovals {
    final byWorkPlace = approvalHistoryFilteredByWorkPlace(
      historyApprovals,
      historyWorkPlaceFilter,
    );
    return approvalFilteredByQuery(byWorkPlace, searchQuery);
  }
}

// ── Notifier ──────────────────────────────────────────────────
class ApprovalInboxNotifier extends StateNotifier<ApprovalInboxState> {
  final Ref ref;
  final ApiClient _api;

  /// Guard sinkron untuk mencegah fetch paralel.
  /// Dipakai sebagai pengganti state.isLoading agar tidak bentrok dengan
  /// nilai default isLoading=true yang di-set sebelum fetch pertama jalan.
  bool _fetchInFlight = false;

  ApprovalInboxNotifier(
    this.ref, {
    ApiClient? apiClient,
    bool skipInitialFetch = false,
  })  : _api = apiClient ?? ApiClient.instance,
        super(const ApprovalInboxState()) {
    if (!skipInitialFetch) {
      fetchInbox();
    }
  }

  /// Update query pencarian no SP / nama customer (client-side, tanpa re-fetch).
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  /// Update filter rentang tanggal lalu re-fetch.
  void updateDateFilter(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    fetchInbox(force: true);
  }

  /// Hapus filter tanggal lalu re-fetch.
  void clearDateFilter() {
    state = state.copyWith(
      clearDateRange: true,
      clearError: true,
      isLoading: true,
    );
    fetchInbox(force: true);
  }

  /// Filter tab Selesai per lokasi/toko (`work_place_name`). `null` = semua.
  void setHistoryWorkPlaceFilter(String? workPlace) {
    state = state.copyWith(
      updateHistoryWorkPlaceFilter: true,
      historyWorkPlaceFilter: workPlace,
    );
  }

  /// Normalisasi nilai `approved` dari API ke [OrderStatus] enum.
  static OrderStatus _normalizeApprovedStatus(dynamic value) =>
      OrderStatusX.fromDynamic(value);

  /// Skip re-fetch jika data masih segar (kecuali [force]).
  static const _inboxFreshnessWindow = Duration(seconds: 45);

  static const _locationTimeout = Duration(seconds: 20);
  static const _geocodeTimeout = Duration(seconds: 3);

  /// Batas tunggu fix GPS/network segar sebelum kita mulai balapan dengan
  /// posisi cache OS (`getLastKnownPosition`, biasanya instan). Sinyal lemah
  /// di gudang/toko sering membuat fix segar lambat — daripada approver
  /// menunggu penuh [_locationTimeout], kita ambil yang lebih dulu siap.
  static const _lastKnownRaceDelay = Duration(seconds: 6);

  /// Posisi cache dianggap terlalu basi untuk geotagging approval jika lebih
  /// tua dari ini — pada kasus itu kita tetap tunggu fix segar.
  static const _lastKnownMaxAge = Duration(minutes: 15);

  /// Mendapatkan posisi GPS saat ini untuk geotagging approval.
  /// Mengembalikan null jika layanan lokasi mati, izin ditolak, atau timeout.
  Future<Position?> _getCurrentLocation() async {
    try {
      // Platform call berikut seharusnya instan; timeout 5s sebagai safety net.
      final enabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 5));
      if (!enabled) {
        Log.warning('Location service disabled', tag: 'Approval');
        return null;
      }

      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 5));
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 30));
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        Log.warning('Location permission denied: $permission', tag: 'Approval');
        return null;
      }

      // LocationAccuracy.medium pakai network/WiFi positioning — jauh lebih cepat
      // (~1–3s) dibanding .high yang menunggu GPS hardware cold-fix (bisa 30–60s).
      // Akurasi ~100m sudah cukup untuk geotagging approval.
      //
      // Balapan dengan cache OS: kalau fix segar belum siap dalam
      // [_lastKnownRaceDelay], coba posisi terakhir yang di-cache OS
      // (near-instant) sebagai fallback — asal tidak terlalu basi. Fix segar
      // tetap dibiarkan berjalan sampai [_locationTimeout] sebagai jaring
      // pengaman kalau cache tidak tersedia.
      final completer = Completer<Position?>();

      unawaited(
        Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: _locationTimeout,
          ),
        ).then((pos) {
          if (!completer.isCompleted) completer.complete(pos);
        }).catchError((e) {
          Log.warning('Fresh location fix gagal/timeout: $e', tag: 'Approval');
        }),
      );

      unawaited(
        Future.delayed(_lastKnownRaceDelay, () async {
          if (completer.isCompleted) return;
          try {
            final last = await Geolocator.getLastKnownPosition();
            if (last == null || completer.isCompleted) return;
            final age = DateTime.now().difference(last.timestamp);
            if (age > _lastKnownMaxAge) {
              Log.info(
                'Cache lokasi terlalu basi (${age.inMinutes}m) — tunggu fix segar',
                tag: 'Approval',
              );
              return;
            }
            completer.complete(last);
          } catch (e) {
            Log.warning('getLastKnownPosition gagal: $e', tag: 'Approval');
          }
        }),
      );

      return await completer.future.timeout(
        _locationTimeout,
        onTimeout: () => null,
      );
    } on TimeoutException {
      Log.warning('Location request timed out', tag: 'Approval');
      return null;
    } catch (e) {
      Log.warning('ApprovalInbox._getCurrentLocation: $e', tag: 'Approval');
      return null;
    }
  }

  /// Reverse geocoding: koordinat → alamat lengkap. [isApproximate] ditandai
  /// pada hasil jika [position] berasal dari cache OS yang diambil paksa
  /// (bukan fix GPS langsung) — lihat [getFallbackLocationForApproval].
  Future<ApprovalLocation> _resolveAddress(
    Position position, {
    required bool isApproximate,
  }) async {
    final coordFallback =
        'Koordinat ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    String address = coordFallback;
    try {
      try {
        await setLocaleIdentifier('id_ID');
      } catch (e) {
        Log.warning('setLocaleIdentifier id_ID gagal: $e', tag: 'Approval');
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(_geocodeTimeout);
      if (placemarks.isNotEmpty) {
        final formatted =
            formatPlacemarkAddressForApproval(placemarks.first);
        if (formatted.isNotEmpty) address = formatted;
      }
    } on TimeoutException {
      Log.warning('Geocoding timed out', tag: 'Approval');
    } catch (e) {
      Log.warning('ApprovalInbox.geocode: $e', tag: 'Approval');
    }

    if (isApproximate) address = '(Lokasi perkiraan) $address';

    return ApprovalLocation(
      address: address,
      latitude: position.latitude,
      longitude: position.longitude,
      isApproximate: isApproximate,
    );
  }

  /// API untuk UI: ambil alamat + koordinat sebelum proses approval.
  /// Jika null (GPS/izin gagal), UI wajib tampilkan peringatan dan jangan lanjutkan.
  Future<ApprovalLocation?> getCurrentAddressForApproval() async {
    final position = await _getCurrentLocation();
    if (position == null) return null;
    return _resolveAddress(position, isApproximate: false);
  }

  /// Fallback manual (tombol "Lanjutkan tanpa lokasi presisi"): ambil posisi
  /// terakhir dari cache OS **tanpa filter kesegaran**, untuk kasus sinyal
  /// sangat lemah di mana fix segar tidak kunjung selesai. Hasilnya ditandai
  /// [ApprovalLocation.isApproximate] agar tetap transparan untuk audit.
  /// Mengembalikan null jika cache OS benar-benar tidak tersedia (mis. GPS
  /// belum pernah dipakai di perangkat ini).
  Future<ApprovalLocation?> getFallbackLocationForApproval() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) return null;
      return _resolveAddress(last, isApproximate: true);
    } catch (e) {
      Log.warning('getFallbackLocationForApproval gagal: $e', tag: 'Approval');
      return null;
    }
  }

  /// Legacy: hanya koordinat (untuk kompatibilitas).
  Future<Position?> getCurrentLocationForApproval() => _getCurrentLocation();

  /// Header Status Sync: update status order letter (Approved/Rejected).
  Future<void> updateOrderLetterStatus(int orderId, String newStatus) async {
    final res = await _api.put(
      '/order_letters/$orderId',
      body: {'status': newStatus},
    );

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiSessionExpiredException(
        'order_letters put $orderId ${res.statusCode}',
      );
    }
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Gagal update status header SP ($orderId -> $newStatus). '
        'Status: ${res.statusCode}',
      );
    }
  }

  /// Void SP dari detail (inbox selesai): GET agar backend mencatat [user_id]
  /// yang melakukan penolakan (`order_letters_rejected`).
  ///
  /// Token & client credentials disuntikkan oleh [ApiClient.get] seperti URL contoh API.
  Future<void> voidOrderLetterViaRejectedEndpoint({
    required int orderLetterId,
    required int userId,
    String? token,
  }) async {
    final res = await _api.get(
      '/order_letters/$orderLetterId/order_letters_rejected',
      token: token,
      queryParams: {'user_id': userId.toString()},
    );

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiSessionExpiredException(
        'order_letters_rejected $orderLetterId ${res.statusCode}',
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Gagal void SP (order_letters_rejected). Status: ${res.statusCode}',
      );
    }
  }

  /// Final check seluruh approval diskon pada satu SP.
  Future<bool> isAllDiscountsApproved(int orderId) async {
    final res = await _api.get('/order_letters/$orderId');

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiSessionExpiredException(
        'isAllDiscountsApproved $orderId ${res.statusCode}',
      );
    }
    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil detail SP untuk final check approval. '
        'Status: ${res.statusCode}',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final details =
        body['result']?['order_letter_details'] as List<dynamic>? ?? [];

    final allDiscountsForThisSP = <dynamic>[];
    for (final detail in details) {
      final d = detail as Map<String, dynamic>;
      final discounts = d['order_letter_discount'] as List<dynamic>? ?? [];
      allDiscountsForThisSP.addAll(discounts);
    }

    if (allDiscountsForThisSP.isEmpty) return false;

    return allDiscountsForThisSP.every(
      (d) =>
          OrderStatusX.fromDynamic(
            (d as Map<String, dynamic>)['approved'],
          ) ==
          OrderStatus.approved,
    );
  }

  /// [force] = true: abaikan freshness window dan fetch ulang
  /// (pull-to-refresh, filter tanggal, refresh pasca approve).
  Future<void> fetchInbox({bool force = false}) async {
    if (_fetchInFlight && !force) return;

    // Hindari double-fetch beruntun dari profile + inbox + constructor.
    if (!force &&
        state.error == null &&
        state.lastFetchedAt != null &&
        DateTime.now().difference(state.lastFetchedAt!) <
            _inboxFreshnessWindow) {
      return;
    }

    _fetchInFlight = true;
    state = state.copyWith(isLoading: true, clearError: true);
    final sw = Stopwatch()..start();

    try {
      final profile = await ref.read(profileProvider.future);
      final currentUserIdStr = profile?.id.toString() ?? '';

      final queryParams = <String, String>{
        'user_id': profile?.id.toString() ?? '0',
      };

      // Filter tanggal server-side (bukan page/limit).
      // null = backend default ke bulan berjalan — sama kontrak dengan
      // GET /order_letters di [orderHistoryProvider] / [dateFilterProvider].
      final startDate = state.startDate;
      final endDate = state.endDate;
      if (startDate != null && endDate != null) {
        queryParams['date_from'] = AppFormatters.apiDate(startDate);
        queryParams['date_to'] = AppFormatters.apiDate(endDate);
      }

      final response = await retry(
        () => _api.get(
          '/order_letter_approvals',
          queryParams: queryParams,
        ),
        maxAttempts: 2,
        tag: 'approvalInbox',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawOrders = data['result'] as List<dynamic>? ?? [];

        // Validasi tiap item (cegah silent crash)
        final List<dynamic> rawOrdersSafe = [];
        for (var i = 0; i < rawOrders.length; i++) {
          try {
            final wrap = rawOrders[i];
            if (wrap is! Map) continue;
            final wrapMap = Map<String, dynamic>.from(wrap);
            wrapMap['order_letter'] as Map<String, dynamic>?;
            wrapMap['order_letter_details'] as List<dynamic>?;
            rawOrdersSafe.add(wrapMap);
          } catch (e) {
            Log.warning('Skip invalid approval item: $e', tag: 'Approval');
          }
        }

        // ── Grouping: deduplikasi SP berdasarkan order_letter_id ──────
        final Map<dynamic, Map<String, dynamic>> grouped = {};
        for (final wrap in rawOrdersSafe) {
          final letter = wrap['order_letter'] as Map<String, dynamic>? ?? {};
          final key =
              letter['id'] ?? letter['no_sp'] ?? Object.hash(wrap, null);

          if (!grouped.containsKey(key)) {
            grouped[key] = Map<String, dynamic>.from(wrap);
          }
        }
        final List<dynamic> allOrders = grouped.values.toList();

        final List<dynamic> pending = [];
        final List<dynamic> history = [];

        for (var orderIndex = 0;
            orderIndex < allOrders.length;
            orderIndex++) {
          final orderWrap = allOrders[orderIndex];
          bool isMyApproval = false;
          bool isMyApprovalDone = false;
          bool hasActionablePending = false;

          final letter =
              orderWrap['order_letter'] as Map<String, dynamic>? ?? {};
          final details =
              orderWrap['order_letter_details'] as List<dynamic>? ?? [];

          final headerEnum = OrderStatusX.fromRaw(
            letter['status']?.toString() ?? '',
          );
          final bool headerRejected = headerEnum == OrderStatus.rejected;

          bool hasRejectedDiscount = false;

          for (final detail in details) {
            final discounts =
                (detail as Map<String, dynamic>)['order_letter_discount']
                        as List<dynamic>? ??
                    [];
            final discountMaps =
                discounts.map((d) => d as Map<String, dynamic>).toList();

            for (int i = 0; i < discountMaps.length; i++) {
              final disc = discountMaps[i];
              final discEnum = _normalizeApprovedStatus(disc['approved']);

              if (discEnum == OrderStatus.rejected) {
                hasRejectedDiscount = true;
              }

              final approverId = disc['approver_id']?.toString() ?? '';
              if (approverId.isEmpty || approverId != currentUserIdStr) {
                continue;
              }

              isMyApproval = true;

              if (discEnum == OrderStatus.approved ||
                  discEnum == OrderStatus.rejected) {
                isMyApprovalDone = true;
              } else if (discEnum == OrderStatus.pending) {
                if (arePriorApprovalsSatisfied(
                  discounts: discountMaps,
                  myIndex: i,
                )) {
                  hasActionablePending = true;
                }
              }
            }
          }

          if (!isMyApproval) continue;

          if (headerRejected || hasRejectedDiscount) {
            history.add(orderWrap);
          } else if (hasActionablePending) {
            pending.add(orderWrap);
          } else if (isMyApprovalDone) {
            history.add(orderWrap);
          }
        }

        // Urutkan terbaru di atas berdasarkan created_at
        DateTime parseDate(dynamic wrap) =>
            DateTime.tryParse(
              wrap['order_letter']?['created_at']?.toString() ?? '',
            ) ??
            DateTime(2000);

        pending.sort((a, b) => parseDate(b).compareTo(parseDate(a)));
        history.sort((a, b) => parseDate(b).compareTo(parseDate(a)));

        sw.stop();
        AppTelemetry.event('approval_inbox_loaded', data: {
          'pending_count': pending.length,
          'history_count': history.length,
          'duration_ms': sw.elapsedMilliseconds,
        });

        state = state.copyWith(
          isLoading: false,
          clearError: true,
          pendingApprovals: pending,
          historyApprovals: history,
          lastFetchedAt: DateTime.now(),
        );
      } else {
        sw.stop();
        if (response.statusCode == 401 || response.statusCode == 403) {
          AppTelemetry.error('approval_inbox_auth', data: {
            'status_code': response.statusCode,
            'duration_ms': sw.elapsedMilliseconds,
          });
          await ref.read(authProvider.notifier).logout();
          state = state.copyWith(
            isLoading: false,
            clearError: true,
            pendingApprovals: const [],
            historyApprovals: const [],
          );
          return;
        }
        AppTelemetry.error('approval_inbox_failed', data: {
          'status_code': response.statusCode,
          'duration_ms': sw.elapsedMilliseconds,
        });
        state = state.copyWith(
          isLoading: false,
          error: 'Gagal memuat data (Status: ${response.statusCode})',
        );
      }
    } catch (e, st) {
      sw.stop();
      Log.error(e, st, reason: 'ApprovalInbox.fetchInbox');
      AppTelemetry.error('approval_inbox_failed', data: {
        'reason': e.toString(),
        'duration_ms': sw.elapsedMilliseconds,
      });
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _fetchInFlight = false;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────
final approvalInboxProvider =
    StateNotifierProvider<ApprovalInboxNotifier, ApprovalInboxState>((ref) {
  return ApprovalInboxNotifier(ref);
});
