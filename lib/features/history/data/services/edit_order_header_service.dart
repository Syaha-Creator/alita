import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/api_session_expired.dart';
import '../../../../core/utils/app_telemetry.dart';
import '../../../../core/utils/log.dart';
import '../models/order_history.dart';

/// Service untuk edit header [order_letters].
///
/// **Direct:** update header + reset approval discount (L2+) + notifikasi.
/// **Indirect (SO):** update header; status `Approved` hanya jika tidak ada
/// baris ASM/RSM/Analyst yang masih Pending — kalau masih pending → `Pending`.
class EditOrderHeaderService {
  EditOrderHeaderService({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  static const _timeout = Duration(seconds: 20);

  /// Order indirect (channel SO) — edit header tidak menyentuh approval chain.
  static bool isIndirectOrder(OrderHistory order) =>
      (order.channel?.trim().toUpperCase() ?? '') == 'SO';

  /// True jika masih ada baris approval L2+ (ASM/SPV/RSM/Analyst/FOC) Pending.
  /// User (L1) dan Diskon Toko diabaikan (auto-approved).
  static bool hasPendingApproverChain(OrderHistory order) {
    for (final detail in order.details) {
      for (final disc in detail.discounts) {
        final level = disc.approverLevel.toLowerCase().trim();
        if (level == 'user' || level.startsWith('diskon toko')) continue;
        if (disc.approverLevelId == 1) continue;
        if (OrderStatusX.fromRaw(disc.approvedStatus) == OrderStatus.pending) {
          return true;
        }
      }
    }
    return false;
  }

  /// Status header setelah edit informasi.
  ///
  /// - Ada chain approver masih Pending → selalu `Pending` (Direct & Indirect).
  /// - Indirect tanpa pending chain → `Approved` (auto-approve SO).
  /// - Direct tanpa pending (sebelum reset) → `Pending` (akan di-reset L2+).
  static String resolveEditHeaderStatus({
    required OrderHistory order,
    required bool isIndirect,
  }) {
    if (hasPendingApproverChain(order)) {
      return OrderStatus.pending.apiValue;
    }
    return isIndirect
        ? OrderStatus.approved.apiValue
        : OrderStatus.pending.apiValue;
  }

  // ── Payload builder ──────────────────────────────────────────────

  static Map<String, dynamic> buildHeaderPayload({
    required String customerName,
    required String phone,
    required String address,
    required String email,
    required String shipToName,
    required String addressShipTo,
    required String requestDate,
    String? noPo,
    String? salesCode,
    String? note,
    double postage = 0,
    String status = 'Pending',
    /// Grand total baru = subtotal item + [postage]. WAJIB dikirim setiap
    /// ongkir berubah — server tidak menghitung ulang `extended_amount` sendiri.
    required double extendedAmount,
    /// Sum `customer_price * qty` semua item (sebelum diskon) — dipakai server
    /// untuk hitung ulang `discount` (%). Wajib dikirim ulang tiap edit header
    /// (walau item tak berubah), atau nilainya stale terhadap `extendedAmount` baru.
    required double hargaAwal,
  }) {
    final cleanNoPo = noPo?.trim();
    final cleanSalesCode = salesCode?.trim();
    final discount =
        hargaAwal > 0 ? ((hargaAwal - extendedAmount) / hargaAwal) * 100 : 0.0;
    return {
      'customer_name': customerName.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'email': email.trim(),
      'ship_to_name': shipToName.trim(),
      'address_ship_to': addressShipTo.trim(),
      'request_date': requestDate.trim(),
      'no_po': (cleanNoPo == null || cleanNoPo.isEmpty) ? null : cleanNoPo,
      'sales_code': (cleanSalesCode == null || cleanSalesCode.isEmpty)
          ? null
          : cleanSalesCode,
      'note': note?.trim() ?? '',
      'postage': postage,
      'extended_amount': extendedAmount,
      'harga_awal': hargaAwal,
      'discount': discount,
      'status': status,
    };
  }

  /// Sum `customer_price * qty` dari semua [OrderHistory.details] — baseline
  /// harga sebelum diskon, dipakai untuk recompute `discount` (%) di
  /// [buildHeaderPayload] tanpa perlu menyentuh item.
  static double computeHargaAwal(OrderHistory order) =>
      order.details.fold<double>(0, (s, d) => s + d.customerPrice * d.qty);

  /// Sum `net_price * qty` dari semua [OrderHistory.details] — subtotal item
  /// riil (sebelum ongkir). Lebih aman daripada `totalAmount - postage`
  /// karena tidak tergantung field lama yang mungkin sudah korup/tidak sinkron.
  static double computeItemsSubtotal(OrderHistory order) =>
      order.details.fold<double>(0, (s, d) => s + d.netPrice * d.qty);

  // ── Helpers: collect IDs ─────────────────────────────────────────

  /// Kumpulkan discount ID yang perlu di-reset: **hanya L2 ke atas** (skip User/SC).
  ///
  /// User (approver_level == 'User' atau approver_level_id == 1) selalu
  /// auto-approved → tidak perlu di-reset.
  static List<int> collectDiscountIds(OrderHistory order) {
    final ids = <int>[];
    for (final detail in order.details) {
      for (final disc in detail.discounts) {
        if (disc.id <= 0) continue;
        final level = disc.approverLevel.toLowerCase();
        // Skip User/SC (L1) dan Diskon Toko — keduanya auto-approved.
        if (level == 'user') continue;
        if (level.startsWith('diskon toko')) continue;
        ids.add(disc.id);
      }
    }
    return ids;
  }

  /// Cari approver pertama L2+ untuk notifikasi (SPV/ASM).
  /// Ambil yang [approver_level_id] terkecil di atas 1.
  static Map<String, dynamic>? _findFirstNonUserApprover(OrderHistory order) {
    final candidates = <Map<String, dynamic>>[];
    for (final detail in order.details) {
      for (final disc in detail.discounts) {
        if (disc.approverLevel.toLowerCase() == 'user') continue;
        if (disc.approverId == null || disc.approverId!.isEmpty) continue;
        candidates.add({
          'approver_id': disc.approverId,
          'approver_name': disc.approverName,
          'approver_level': disc.approverLevel,
        });
      }
    }
    if (candidates.isEmpty) return null;
    // Deduplicate by approver_id, ambil yang pertama
    final seen = <String>{};
    for (final c in candidates) {
      final id = c['approver_id']?.toString() ?? '';
      if (seen.add(id)) return c;
    }
    return null;
  }

  // ── Step 1: PATCH header ─────────────────────────────────────────

  Future<void> patchHeader({
    required int orderLetterId,
    required Map<String, dynamic> payload,
    String? token,
  }) async {
    final res = await _api.put(
      '/order_letters/$orderLetterId',
      token: token,
      body: payload,
      timeout: _timeout,
    );
    _assertOk(res.statusCode, 'PATCH header SP $orderLetterId', res.body);
    Log.info(
      'EditHeader: header SP $orderLetterId updated',
      tag: 'EditOrderHeader',
    );
  }

  // ── Step 2: Reset discounts (L2+) ───────────────────────────────

  Future<void> _resetOneDiscount({
    required int discountId,
    String? token,
  }) async {
    final res = await _api.put(
      '/order_letter_discounts/$discountId',
      token: token,
      body: {'approved': null, 'approved_at': null},
      timeout: _timeout,
    );
    _assertOk(res.statusCode, 'reset discount $discountId', res.body);
  }

  Future<void> resetNonUserDiscounts({
    required List<int> discountIds,
    String? token,
  }) async {
    Log.info(
      'EditHeader: resetting ${discountIds.length} discount rows (L2+)',
      tag: 'EditOrderHeader',
    );
    for (final id in discountIds) {
      await _resetOneDiscount(discountId: id, token: token);
    }
    Log.info(
      'EditHeader: discounts reset to pending',
      tag: 'EditOrderHeader',
    );
  }

  // ── Step 3: Notifikasi ke approver berikutnya ────────────────────

  /// Kirim push notification ke SPV/ASM (approver L2 pertama) untuk
  /// memberitahu bahwa SP sudah diedit dan perlu approval ulang.
  static Future<void> triggerReEditNotification({
    required OrderHistory order,
    required String token,
    required String editorName,
  }) async {
    try {
      final nextApprover = _findFirstNonUserApprover(order);
      if (nextApprover == null) {
        Log.info(
          'EditHeader: no approver to notify',
          tag: 'EditOrderHeader',
        );
        return;
      }

      final approverId = nextApprover['approver_id']?.toString() ?? '';
      if (approverId.isEmpty) return;

      final fcmToken = await _fetchFcmToken(
        userId: approverId,
        accessToken: token,
      );
      if (fcmToken == null || fcmToken.isEmpty) return;

      await _callCloudFunction(
        functionName: 'sendApprovalNotification',
        params: {
          'token': fcmToken,
          'sp_number': order.noSp,
          'sender_name': editorName,
          'order_letter_id': order.id,
          'type': 're_edit',
        },
      );

      AppTelemetry.event('approval_notification_sent', data: {
        'type': 're_edit',
        'sp_number': order.noSp,
      });

      Log.info(
        'EditHeader: re-edit notification sent to ${nextApprover['approver_name']}',
        tag: 'EditOrderHeader',
      );
    } catch (e, st) {
      Log.error(e, st,
          reason: 'EditOrderHeaderService.triggerReEditNotification');
      AppTelemetry.error('approval_notification_failed', data: {
        'sp_number': order.noSp,
        'reason': e.toString(),
      });
    }
  }

  // ── Orchestrator ─────────────────────────────────────────────────

  /// Jalankan semua step berurutan.
  ///
  /// [resetApprovals] false untuk indirect (SO): hanya PATCH header.
  Future<void> editAndReset({
    required OrderHistory order,
    required Map<String, dynamic> headerPayload,
    String? token,
    bool resetApprovals = true,
  }) async {
    await patchHeader(
      orderLetterId: order.id,
      payload: headerPayload,
      token: token,
    );
    if (!resetApprovals) return;
    final ids = collectDiscountIds(order);
    if (ids.isNotEmpty) {
      await resetNonUserDiscounts(discountIds: ids, token: token);
    }
  }

  // ── Private helpers ──────────────────────────────────────────────

  void _assertOk(int statusCode, String label, String body) {
    if (statusCode == 401 || statusCode == 403) {
      throw ApiSessionExpiredException('$label status=$statusCode');
    }
    if (statusCode != 200 && statusCode != 201) {
      throw Exception(
        'Gagal $label (status $statusCode).\n'
        'Response: ${Log.previewBody(body)}',
      );
    }
  }

  static Future<String?> _fetchFcmToken({
    required String userId,
    required String accessToken,
  }) async {
    try {
      final res = await ApiClient.instance.get(
        '/device_tokens',
        token: accessToken,
        queryParams: {'user_id': userId},
      );
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return null;
      final body = Map<String, dynamic>.from(decoded);
      final result = body['result'];
      if (result is List && result.isNotEmpty) {
        final first = result.first;
        return first is Map ? first['token']?.toString() : null;
      } else if (result is Map) {
        return result['token']?.toString();
      }
      return null;
    } catch (e, st) {
      Log.error(e, st, reason: 'EditOrderHeaderService._fetchFcmToken');
      return null;
    }
  }

  static Future<void> _callCloudFunction({
    required String functionName,
    required Map<String, dynamic> params,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast2')
          .httpsCallable(functionName);
      await callable.call(params);
    } on FirebaseException catch (e) {
      Log.warning(
        'Cloud Function "$functionName" skipped (Firebase: ${e.code})',
        tag: 'EditOrderHeader',
      );
    }
  }
}
