import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/services/api_session_expired.dart';
import '../../../../core/utils/app_telemetry.dart';
import '../../../../core/utils/log.dart';
import '../../../checkout/data/models/approver_model.dart';
import '../models/order_history.dart';

/// Service untuk edit header [order_letters] dan reset approval discount
/// (kecuali User/SC level 1) kembali ke pending.
///
/// Alur:
///   1. PUT /order_letters/{id}       — update field header + status → pending
///   2. PUT /order_letter_discounts/{id}  — reset tiap baris L2+ (satu per satu)
///   3. Kirim notifikasi ke approver berikutnya (SPV / ASM)
class EditOrderHeaderService {
  EditOrderHeaderService({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  static const _timeout = Duration(seconds: 20);

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
  }) {
    final cleanNoPo = noPo?.trim();
    final cleanSalesCode = salesCode?.trim();
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
      'status': 'Pending',
    };
  }

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

  // ── POST ASM discount rows (Customer Baru) ───────────────────────

  /// Buat baris `order_letter_discounts` level ASM untuk setiap detail
  /// pada order yang dialihkan ke Customer Baru (tidak ada ASM sebelumnya).
  Future<void> postAsmDiscountRows({
    required OrderHistory order,
    required Approver asm,
    String? token,
  }) async {
    for (final detail in order.details) {
      if (detail.id <= 0) continue;
      final payload = {
        'order_letter_id': order.id,
        'order_letter_detail_id': detail.id,
        'discount': '0',
        'approver': asm.id,
        'approver_name': asm.fullName,
        'approver_level_id': 2,
        'approver_level': 'ASM',
        'approver_work_tittle': asm.jobLevelName,
        'approved': null,
        'approved_at': null,
      };
      final res = await _api.post(
        '/order_letter_discounts',
        token: token,
        body: payload,
        timeout: _timeout,
      );
      _assertOk(res.statusCode, 'POST ASM discount detail ${detail.id}', res.body);
      Log.info(
        'EditHeader: ASM discount row created for detail ${detail.id}',
        tag: 'EditOrderHeader',
      );
    }
  }

  // ── Orchestrator ─────────────────────────────────────────────────

  /// Jalankan semua step berurutan.
  Future<void> editAndReset({
    required OrderHistory order,
    required Map<String, dynamic> headerPayload,
    String? token,
  }) async {
    await patchHeader(
      orderLetterId: order.id,
      payload: headerPayload,
      token: token,
    );
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
      final preview = body.length > 200 ? '${body.substring(0, 200)}…' : body;
      throw Exception('Gagal $label (status $statusCode).\nResponse: $preview');
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
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final result = body['result'];
      if (result is List && result.isNotEmpty) {
        return (result.first as Map<String, dynamic>)['token']?.toString();
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
