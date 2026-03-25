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

/// Susun satu baris alamat baca-manusia dari [Placemark] (prioritas Indonesia).
/// Memakai `thoroughfare` / `subThoroughfare` bila `street` kosong (sering di Android).
String _formatPlacemarkAddressForApproval(Placemark place) {
  String nt(String? s) => (s ?? '').trim();

  var line1 = nt(place.street);
  if (line1.isEmpty) {
    final sub = nt(place.subThoroughfare);
    final thru = nt(place.thoroughfare);
    if (sub.isNotEmpty && thru.isNotEmpty) {
      line1 = '$sub $thru';
    } else if (thru.isNotEmpty) {
      line1 = thru;
    } else if (sub.isNotEmpty) {
      line1 = sub;
    } else {
      line1 = nt(place.name);
    }
  }

  final parts = <String>[];
  if (line1.isNotEmpty) parts.add(line1);

  void addUnique(String value) {
    final t = value.trim();
    if (t.isEmpty) return;
    final lower = t.toLowerCase();
    if (parts.any((p) => p.toLowerCase() == lower)) return;
    parts.add(t);
  }

  addUnique(nt(place.subLocality));

  final subAdm = nt(place.subAdministrativeArea);
  if (subAdm.isNotEmpty) {
    final lower = subAdm.toLowerCase();
    addUnique(
      lower.contains('kecamatan') ? subAdm : 'Kecamatan $subAdm',
    );
  }

  addUnique(nt(place.locality));
  addUnique(nt(place.administrativeArea));

  return parts.join(', ');
}

/// Label lokasi/toko dari raw `orderWrap` API (sama logika dengan header approval).
String approvalOrderWrapWorkPlace(dynamic wrap) {
  if (wrap is! Map) return '';
  final map = Map<String, dynamic>.from(wrap);
  final order = map['order_letter'] as Map<String, dynamic>? ?? {};
  for (final v in <dynamic>[
    map['work_place_name'],
    map['workplace_name'],
    order['work_place_name'],
    order['workplace_name'],
    order['work_place'],
  ]) {
    final s = v?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
  }
  return '';
}

/// Daftar unik `work_place` untuk tab Selesai (urut A–Z).
List<String> approvalHistoryWorkPlaceOptions(List<dynamic> history) {
  final set = <String>{};
  for (final w in history) {
    final label = approvalOrderWrapWorkPlace(w);
    if (label.isNotEmpty) set.add(label);
  }
  final out = set.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return out;
}

/// Riwayat approval difilter di klien menurut lokasi/toko.
List<dynamic> approvalHistoryFilteredByWorkPlace(
  List<dynamic> history,
  String? workPlace,
) {
  if (workPlace == null || workPlace.isEmpty) return history;
  return history
      .where((w) => approvalOrderWrapWorkPlace(w) == workPlace)
      .toList();
}

// ── Geotagging: alamat + koordinat untuk payload approval ───────
class ApprovalLocation {
  final String address;
  final double latitude;
  final double longitude;

  const ApprovalLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

// ── State ─────────────────────────────────────────────────────
class ApprovalInboxState {
  final bool isLoading;
  final String? error;
  final List<dynamic> pendingApprovals;
  final List<dynamic> historyApprovals;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Filter tab **Selesai** menurut `work_place_name` (null = semua lokasi).
  final String? historyWorkPlaceFilter;

  const ApprovalInboxState({
    this.isLoading = true,
    this.error,
    this.pendingApprovals = const [],
    this.historyApprovals = const [],
    this.startDate,
    this.endDate,
    this.historyWorkPlaceFilter,
  });

  ApprovalInboxState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? pendingApprovals,
    List<dynamic>? historyApprovals,
    DateTime? startDate,
    DateTime? endDate,
    bool updateHistoryWorkPlaceFilter = false,
    String? historyWorkPlaceFilter,
  }) {
    return ApprovalInboxState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      historyApprovals: historyApprovals ?? this.historyApprovals,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      historyWorkPlaceFilter: updateHistoryWorkPlaceFilter
          ? historyWorkPlaceFilter
          : this.historyWorkPlaceFilter,
    );
  }

  /// Daftar unik lokasi toko dari riwayat (urut A–Z).
  List<String> get historyWorkPlaceOptions =>
      approvalHistoryWorkPlaceOptions(historyApprovals);

  /// Riwayat setelah filter lokasi (hanya pengaruh tab Selesai).
  List<dynamic> get filteredHistoryApprovals =>
      approvalHistoryFilteredByWorkPlace(
        historyApprovals,
        historyWorkPlaceFilter,
      );
}

// ── Notifier ──────────────────────────────────────────────────
class ApprovalInboxNotifier extends StateNotifier<ApprovalInboxState> {
  final Ref ref;

  ApprovalInboxNotifier(this.ref) : super(const ApprovalInboxState()) {
    fetchInbox();
  }

  /// Update filter rentang tanggal lalu re-fetch.
  void updateDateFilter(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    fetchInbox();
  }

  /// Hapus filter tanggal lalu re-fetch.
  void clearDateFilter() {
    state = ApprovalInboxState(
      pendingApprovals: state.pendingApprovals,
      historyApprovals: state.historyApprovals,
      historyWorkPlaceFilter: state.historyWorkPlaceFilter,
    );
    fetchInbox();
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

  /// Index-based prior approval check: all discounts BEFORE [myIndex]
  /// in the list must be approved. This is more reliable than
  /// [approver_level_id] which may be null/missing from the API.
  static bool _arePriorApprovedByIndex(
    List<Map<String, dynamic>> discounts,
    int myIndex,
  ) {
    for (int i = 0; i < myIndex; i++) {
      if (_normalizeApprovedStatus(discounts[i]['approved']) !=
          OrderStatus.approved) {
        return false;
      }
    }
    return true;
  }

  static const _locationTimeout = Duration(seconds: 15);
  static const _geocodeTimeout = Duration(seconds: 10);

  /// Mendapatkan posisi GPS saat ini untuk geotagging approval.
  /// Mengembalikan null jika layanan lokasi mati, izin ditolak, atau timeout.
  Future<Position?> _getCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled()
          .timeout(_locationTimeout);
      if (!enabled) {
        Log.warning('Location service disabled', tag: 'Approval');
        return null;
      }

      var permission = await Geolocator.checkPermission()
          .timeout(_locationTimeout);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 30));
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        Log.warning('Location permission denied: $permission', tag: 'Approval');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _locationTimeout,
        ),
      ).timeout(_locationTimeout);
    } on TimeoutException {
      Log.warning('Location request timed out', tag: 'Approval');
      return null;
    } catch (e) {
      Log.warning('ApprovalInbox._getCurrentLocation: $e', tag: 'Approval');
      return null;
    }
  }

  /// Reverse geocoding: koordinat → alamat lengkap. Mengembalikan null jika
  /// GPS/izin gagal; jika koordinat ada tapi geocode gagal, alamat = fallback.
  Future<ApprovalLocation?> _getCurrentAddress() async {
    final position = await _getCurrentLocation();
    if (position == null) return null;

    String address = 'Lokasi tidak terdeteksi';
    try {
      try {
        await setLocaleIdentifier('id_ID');
      } catch (_) {}

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(_geocodeTimeout);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final formatted = _formatPlacemarkAddressForApproval(place);
        if (formatted.isNotEmpty) {
          address = formatted;
        } else {
          address =
              'Koordinat ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        }
      } else {
        address =
            'Koordinat ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      }
    } on TimeoutException {
      Log.warning('Geocoding timed out', tag: 'Approval');
    } catch (e) {
      Log.warning('ApprovalInbox.geocode: $e', tag: 'Approval');
    }

    if (address == 'Lokasi tidak terdeteksi') {
      address =
          'Koordinat ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    }

    return ApprovalLocation(
      address: address,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// API untuk UI: ambil alamat + koordinat sebelum proses approval.
  /// Jika null (GPS/izin gagal), UI wajib tampilkan peringatan dan jangan lanjutkan.
  Future<ApprovalLocation?> getCurrentAddressForApproval() =>
      _getCurrentAddress();

  /// Legacy: hanya koordinat (untuk kompatibilitas).
  Future<Position?> getCurrentLocationForApproval() => _getCurrentLocation();

  static final ApiClient _api = ApiClient.instance;

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

  Future<void> fetchInbox() async {
    state = state.copyWith(isLoading: true, error: null);
    final sw = Stopwatch()..start();

    try {
      final profile = await ref.read(profileProvider.future);
      final currentUserIdStr = profile?.id.toString() ?? '';

      final queryParams = <String, String>{
        'user_id': profile?.id.toString() ?? '0',
      };

      final startDate = state.startDate;
      final endDate = state.endDate;
      if (startDate != null && endDate != null) {
        queryParams['start_date'] = AppFormatters.apiDate(startDate);
        queryParams['end_date'] = AppFormatters.apiDate(endDate);
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
                // Index-based: all discounts BEFORE this user's
                // position must be approved.
                if (_arePriorApprovedByIndex(discountMaps, i)) {
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
          pendingApprovals: pending,
          historyApprovals: history,
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
            error: null,
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
    }
  }
}

// ── Provider ──────────────────────────────────────────────────
final approvalInboxProvider =
    StateNotifierProvider<ApprovalInboxNotifier, ApprovalInboxState>((ref) {
  return ApprovalInboxNotifier(ref);
});
