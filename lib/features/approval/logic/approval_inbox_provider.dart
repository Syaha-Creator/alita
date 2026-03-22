import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/enums/order_status.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/app_telemetry.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/retry.dart';
import '../../profile/logic/profile_provider.dart';
import 'approval_decision_service.dart';

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

  const ApprovalInboxState({
    this.isLoading = true,
    this.error,
    this.pendingApprovals = const [],
    this.historyApprovals = const [],
    this.startDate,
    this.endDate,
  });

  ApprovalInboxState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? pendingApprovals,
    List<dynamic>? historyApprovals,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ApprovalInboxState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      historyApprovals: historyApprovals ?? this.historyApprovals,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
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
    );
    fetchInbox();
  }

  /// Normalisasi nilai `approved` dari API ke [OrderStatus] enum.
  static OrderStatus _normalizeApprovedStatus(dynamic value) =>
      OrderStatusX.fromDynamic(value);

  /// Delegates to [ApprovalDecisionService.arePriorApproversApproved].
  static bool _arePriorApproved(
    List<Map<String, dynamic>> discounts,
    int targetLevel,
  ) =>
      ApprovalDecisionService.arePriorApproversApproved(
        discountsInDetail: discounts,
        targetLevelId: targetLevel,
      );

  /// Mendapatkan posisi GPS saat ini untuk geotagging approval.
  /// Mengembalikan null jika layanan lokasi mati, izin ditolak, atau gagal.
  Future<Position?> _getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e, st) {
      Log.error(e, st, reason: 'ApprovalInbox._getCurrentLocation');
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
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final street = place.street ?? '';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';
        final adminArea = place.administrativeArea ?? '';
        final parts = <String>[
          if (street.isNotEmpty) street,
          if (subLocality.isNotEmpty) subLocality,
          if (locality.isNotEmpty) locality,
          if (adminArea.isNotEmpty) adminArea,
        ];
        if (parts.isNotEmpty) {
          address = parts.join(', ');
        }
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'ApprovalInbox._getCurrentAddress.geocode');
      address = 'Lokasi tidak terdeteksi';
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
            final entry = Map<String, dynamic>.from(wrap);
            entry['order_letter_details'] = List<dynamic>.from(
                wrap['order_letter_details'] as List<dynamic>? ?? []);
            entry['order_letter_payments'] = List<dynamic>.from(
                wrap['order_letter_payments'] as List<dynamic>? ?? []);
            grouped[key] = entry;
          } else {
            final entry = grouped[key]!;
            final existing =
                entry['order_letter_details'] as List<dynamic>;
            final incoming =
                wrap['order_letter_details'] as List<dynamic>? ?? [];
            final existingIds = existing
                .map((d) =>
                    (d as Map<String, dynamic>)['order_letter_detail_id'] ??
                    (d)['id'])
                .toSet();
            for (final d in incoming) {
              final dMap = d as Map<String, dynamic>;
              final dId = dMap['order_letter_detail_id'] ?? dMap['id'];
              if (!existingIds.contains(dId)) {
                existing.add(d);
                existingIds.add(dId);
              }
            }
          }
        }
        final List<dynamic> allOrders = grouped.values.toList();

        final List<dynamic> pending = [];
        final List<dynamic> history = [];

        for (var orderIndex = 0; orderIndex < allOrders.length; orderIndex++) {
          final orderWrap = allOrders[orderIndex];
          bool isMyApproval = false;
          bool isMyApprovalDone = false;
          bool hasActionablePending = false;

          final letter =
              orderWrap['order_letter'] as Map<String, dynamic>? ?? {};
          final details =
              orderWrap['order_letter_details'] as List<dynamic>? ?? [];

          // ── Rejected gate: SP yang sudah ditolak siapapun → history ──
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

            for (final disc in discountMaps) {
              final discEnum = _normalizeApprovedStatus(disc['approved']);

              if (discEnum == OrderStatus.rejected) {
                hasRejectedDiscount = true;
              }

              final approverId = disc['approver_id']?.toString();
              if (approverId == null || approverId.isEmpty) continue;
              if (approverId != currentUserIdStr) continue;

              isMyApproval = true;

              if (discEnum == OrderStatus.approved ||
                  discEnum == OrderStatus.rejected) {
                isMyApprovalDone = true;
              } else if (discEnum == OrderStatus.pending) {
                final myLevel =
                    (disc['approver_level_id'] as num?)?.toInt() ?? 99;
                if (_arePriorApproved(discountMaps, myLevel)) {
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
          // else: waiting for prior approver → don't show yet
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
