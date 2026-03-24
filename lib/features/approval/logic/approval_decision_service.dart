import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../core/enums/order_status.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/app_telemetry.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/name_matcher.dart';
import '../../history/data/models/order_history.dart';
import 'approval_inbox_provider.dart';

class ApprovalDecisionResult {
  final bool headerRejected;
  final bool headerApproved;
  final int processedCount;

  const ApprovalDecisionResult({
    required this.headerRejected,
    required this.headerApproved,
    required this.processedCount,
  });
}

class ApprovalDecisionService {
  ApprovalDecisionService._();

  static final ApiClient _api = ApiClient.instance;

  /// Robustly parse [approver_level_id] which the API may send as int, String,
  /// or null. Returns [fallback] (default 99) when unparseable so the caller
  /// treats unknown levels conservatively.
  static int parseLevel(dynamic value, [int fallback = 99]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Index-based prior approval check: all discounts BEFORE [myIndex]
  /// in the list must be approved. Uses list ordering from the API which
  /// is always sequential (User → Supervisor → RSM → Analyst).
  static bool arePriorApprovedByIndex({
    required List<Map<String, dynamic>> discountsInDetail,
    required int myIndex,
  }) {
    for (int i = 0; i < myIndex; i++) {
      if (OrderStatusX.fromDynamic(discountsInDetail[i]['approved']) !=
          OrderStatus.approved) {
        return false;
      }
    }
    return true;
  }

  /// Sinkron dengan aturan inbox / [ApprovalDetailPage]: giliran user dan prior approved.
  static bool orderHistoryNeedsMyApproval({
    required OrderHistory order,
    required int userId,
    required String myName,
  }) {
    if (userId <= 0 && myName.trim().isEmpty) return false;

    final headerEnum = OrderStatusX.fromRaw(order.status);
    final headerTerminal = headerEnum == OrderStatus.rejected ||
        headerEnum == OrderStatus.approved;
    if (headerTerminal) return false;

    var anyDiscountRejected = false;
    for (final detail in order.details) {
      final maps = detail.discounts
          .map(
            (d) => <String, dynamic>{
              'approved': d.approvedStatus,
              'approver_id': d.approverId,
              'approver_name': d.approverName,
            },
          )
          .toList();
      for (final disc in maps) {
        if (OrderStatusX.fromDynamic(disc['approved']) == OrderStatus.rejected) {
          anyDiscountRejected = true;
        }
      }
    }
    if (anyDiscountRejected) return false;

    for (final detail in order.details) {
      final discountMaps = detail.discounts
          .map(
            (d) => <String, dynamic>{
              'approved': d.approvedStatus,
              'approver_id': d.approverId,
              'approver_name': d.approverName,
            },
          )
          .toList();

      for (var i = 0; i < discountMaps.length; i++) {
        final disc = discountMaps[i];
        final approverId = disc['approver_id']?.toString() ?? '';
        final approverName = disc['approver_name'] as String? ?? '';
        final discEnum = OrderStatusX.fromDynamic(disc['approved']);

        final isMe = (userId > 0 && approverId == userId.toString()) ||
            (myName.isNotEmpty &&
                NameMatcher.softMatch(approverName, myName));

        if (isMe &&
            discEnum == OrderStatus.pending &&
            arePriorApprovedByIndex(
              discountsInDetail: discountMaps,
              myIndex: i,
            )) {
          return true;
        }
      }
    }
    return false;
  }

  static int? _orderLetterIdFromData(Map<String, dynamic> orderData) {
    final letter = orderData['order_letter'];
    if (letter is! Map) return null;
    final raw = letter['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  /// Collects every discount row across all details that belongs to the
  /// current user AND is still Pending.
  ///
  /// Matches by [myUserId] (primary, exact) or [myName] (fallback, fuzzy)
  /// so no discount is missed even if one matcher fails.
  static List<Map<String, dynamic>> collectPendingDiscounts({
    required Map<String, dynamic> orderData,
    required String myName,
    int myUserId = 0,
  }) {
    final details = orderData['order_letter_details'] as List<dynamic>? ?? [];
    final result = <Map<String, dynamic>>[];
    final seenIds = <int>{};

    for (final detail in details) {
      final discounts =
          (detail as Map<String, dynamic>)['order_letter_discount']
                  as List<dynamic>? ??
              [];
      final discountMaps =
          discounts.map((d) => d as Map<String, dynamic>).toList();

      // Track discount IDs that will be approved in this batch,
      // so cascading same-user levels (e.g. SPV + RSM = 1 person)
      // are all collected in a single pass.
      final batchIds = <int>{};

      for (int i = 0; i < discountMaps.length; i++) {
        final discMap = discountMaps[i];
        final discountId =
            (discMap['order_letter_discount_id'] as num?)?.toInt() ?? 0;
        final approverId = discMap['approver_id']?.toString() ?? '';
        final approverName = discMap['approver_name'] as String? ?? '';
        final status = discMap['approved'];
        final isPending =
            OrderStatusX.fromDynamic(status) == OrderStatus.pending;

        if (!isPending) continue;

        final isMe = (myUserId > 0 && approverId == myUserId.toString()) ||
            (myName.isNotEmpty && NameMatcher.softMatch(approverName, myName));

        if (!isMe || discountId <= 0 || !seenIds.add(discountId)) continue;

        // Check all prior discounts: must be approved OR already
        // collected in this batch (same user, will be approved together).
        bool allPriorOk = true;
        for (int j = 0; j < i; j++) {
          final prior = discountMaps[j];
          final priorStatus = OrderStatusX.fromDynamic(prior['approved']);
          if (priorStatus == OrderStatus.approved) continue;
          final priorId =
              (prior['order_letter_discount_id'] as num?)?.toInt() ?? 0;
          if (priorId > 0 && batchIds.contains(priorId)) continue;
          allPriorOk = false;
          break;
        }

        if (allPriorOk) {
          result.add(discMap);
          batchIds.add(discountId);
        }
      }
    }

    return result;
  }

  static int resolveOrderId(Map<String, dynamic> orderData) {
    final order = orderData['order_letter'] as Map<String, dynamic>? ?? {};
    return (order['id'] as num?)?.toInt() ??
        (order['order_letter_id'] as num?)?.toInt() ??
        (orderData['order_letter_id'] as num?)?.toInt() ??
        0;
  }

  static Future<void> approveOneDiscount({
    required Map<String, dynamic> disc,
    required bool isApproved,
    required String token,
    required int userId,
    double? latitude,
    double? longitude,
    String? lokasiApproval,
  }) async {
    final int discountId =
        (disc['order_letter_discount_id'] as num?)?.toInt() ?? 0;
    final int levelId = parseLevel(disc['approver_level_id'], 2);

    // 1) POST approval log
    final postBody = <String, dynamic>{
      'order_letter_discount_id': discountId,
      'leader': userId,
      'job_level_id': levelId,
      'location': 'Lokasi terdeteksi via sistem',
      'lokasi_approval': lokasiApproval ?? 'Lokasi tidak terdeteksi',
    };
    if (latitude != null && longitude != null) {
      postBody['latitude'] = latitude;
      postBody['longitude'] = longitude;
    }
    final postRes = await _api.post(
      '/order_letter_approves',
      token: token,
      body: postBody,
    );
    if (postRes.statusCode != 200 && postRes.statusCode != 201) {
      throw Exception(
        'Gagal mencatat log persetujuan (ID $discountId, '
        'Status: ${postRes.statusCode})',
      );
    }

    // 2) PUT discount status
    final putBody = <String, dynamic>{
      'approved': isApproved,
      'lokasi_approval': lokasiApproval ?? 'Lokasi tidak terdeteksi',
    };
    if (latitude != null && longitude != null) {
      putBody['latitude'] = latitude;
      putBody['longitude'] = longitude;
    }
    final putRes = await _api.put(
      '/order_letter_discounts/$discountId',
      token: token,
      body: putBody,
    );
    if (putRes.statusCode != 200 && putRes.statusCode != 201) {
      throw Exception(
        'Gagal mengupdate status diskon (ID $discountId, '
        'Status: ${putRes.statusCode})',
      );
    }
  }

  /// Processes ALL [pendingDiscs] sequentially, then updates the SP
  /// header status based on the collective outcome.
  ///
  /// For rejection: every pending discount belonging to this user is
  /// rejected first, then the SP header is set to 'Rejected'.
  /// For approval: every discount is approved, then a final check
  /// determines whether all approvers across the SP have approved.
  static Future<ApprovalDecisionResult> processCascade({
    required List<Map<String, dynamic>> pendingDiscs,
    required bool isApproved,
    required String token,
    required int userId,
    required int orderId,
    required ApprovalInboxNotifier notifier,
    double? latitude,
    double? longitude,
    String? lokasiApproval,
  }) async {
    // Process ALL pending discounts — no early break
    for (final disc in pendingDiscs) {
      await approveOneDiscount(
        disc: disc,
        isApproved: isApproved,
        token: token,
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        lokasiApproval: lokasiApproval,
      );
    }

    // After all discounts processed, update header status
    var headerRejected = false;
    var headerApproved = false;

    if (!isApproved) {
      await notifier.updateOrderLetterStatus(
        orderId,
        OrderStatus.rejected.apiValue,
      );
      headerRejected = true;
    } else {
      final isAllApproved = await notifier.isAllDiscountsApproved(orderId);
      if (isAllApproved) {
        await notifier.updateOrderLetterStatus(
          orderId,
          OrderStatus.approved.apiValue,
        );
        headerApproved = true;
      }
    }

    return ApprovalDecisionResult(
      headerRejected: headerRejected,
      headerApproved: headerApproved,
      processedCount: pendingDiscs.length,
    );
  }

  // ── Sequential Approval Notification ─────────────────────────────

  /// Finds the next pending approver across all details/discounts,
  /// fetches their FCM token from the Ruby API, and triggers a
  /// Cloud Function to send the push notification.
  ///
  /// If no pending approver remains (fully approved), sends a
  /// completion notification to the SP creator instead.
  static Future<void> triggerNextApprovalNotification({
    required Map<String, dynamic> orderData,
    required String spNumber,
    required String token,
    required String senderName,
    required int currentUserId,
  }) async {
    try {
      final nextApprover = _findNextPendingApprover(
        orderData,
        excludeUserId: currentUserId,
      );

      if (nextApprover != null) {
        final approverId = nextApprover['approver_id']?.toString() ?? '';
        if (approverId.isEmpty) return;

        final fcmToken = await _fetchFcmToken(
          userId: approverId,
          accessToken: token,
        );
        if (fcmToken == null || fcmToken.isEmpty) return;

        final oid = _orderLetterIdFromData(orderData);
        await _callCloudFunction(
          functionName: 'sendApprovalNotification',
          params: {
            'token': fcmToken,
            'sp_number': spNumber,
            'sender_name': senderName,
            if (oid != null) 'order_letter_id': oid,
          },
        );

        AppTelemetry.event('approval_notification_sent', data: {
          'type': 'next_approver',
          'sp_number': spNumber,
        });
      } else {
        // Semua sudah approve → kirim notif ke creator
        final order = orderData['order_letter'] as Map<String, dynamic>? ?? {};
        final creatorId =
            order['creator']?.toString() ?? order['user_id']?.toString() ?? '';
        if (creatorId.isEmpty) return;

        final fcmToken = await _fetchFcmToken(
          userId: creatorId,
          accessToken: token,
        );
        if (fcmToken == null || fcmToken.isEmpty) return;

        final oid = _orderLetterIdFromData(orderData);
        await _callCloudFunction(
          functionName: 'sendApprovalNotification',
          params: {
            'token': fcmToken,
            'sp_number': spNumber,
            'sender_name': 'Sistem',
            'type': 'fully_approved',
            if (oid != null) 'order_letter_id': oid,
          },
        );

        AppTelemetry.event('approval_notification_sent', data: {
          'type': 'fully_approved',
          'sp_number': spNumber,
        });
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'triggerNextApprovalNotification');
      AppTelemetry.error('approval_notification_failed', data: {
        'sp_number': spNumber,
        'reason': e.toString(),
      });
    }
  }

  /// Sends a push to the SP creator when the order is rejected.
  static Future<void> triggerRejectionNotification({
    required Map<String, dynamic> orderData,
    required String spNumber,
    required String token,
    required String senderName,
  }) async {
    if (spNumber.isEmpty) return;
    try {
      final order = orderData['order_letter'] as Map<String, dynamic>? ?? {};
      final creatorId =
          order['creator']?.toString() ?? order['user_id']?.toString() ?? '';
      if (creatorId.isEmpty) return;

      final fcmToken = await _fetchFcmToken(
        userId: creatorId,
        accessToken: token,
      );
      if (fcmToken == null || fcmToken.isEmpty) return;

      final oid = _orderLetterIdFromData(orderData);
      await _callCloudFunction(
        functionName: 'sendApprovalNotification',
        params: {
          'token': fcmToken,
          'sp_number': spNumber,
          'sender_name': senderName,
          'type': 'rejected',
          if (oid != null) 'order_letter_id': oid,
        },
      );

      AppTelemetry.event('approval_notification_sent', data: {
        'type': 'rejected',
        'sp_number': spNumber,
      });
    } catch (e, st) {
      Log.error(e, st, reason: 'triggerRejectionNotification');
      AppTelemetry.error('approval_notification_failed', data: {
        'sp_number': spNumber,
        'reason': e.toString(),
      });
    }
  }

  /// Scans all order_letter_details → order_letter_discount to find
  /// the next approver whose status is still "Pending", sorted by
  /// approver_level_id ascending. Returns null if none remain.
  ///
  /// [excludeUserId]: Skip discounts belonging to the user who just
  /// approved, because local orderData is stale and still shows their
  /// discounts as "Pending" even though the server already updated them.
  static Map<String, dynamic>? _findNextPendingApprover(
    Map<String, dynamic> orderData, {
    int excludeUserId = 0,
  }) {
    final details = orderData['order_letter_details'] as List<dynamic>? ?? [];
    final pending = <Map<String, dynamic>>[];
    final excludeId = excludeUserId > 0 ? excludeUserId.toString() : '';

    for (final detail in details) {
      final discounts =
          (detail as Map<String, dynamic>)['order_letter_discount']
                  as List<dynamic>? ??
              [];
      for (final disc in discounts) {
        final discMap = disc as Map<String, dynamic>;
        final discEnum = OrderStatusX.fromDynamic(discMap['approved']);
        if (discEnum != OrderStatus.pending) continue;

        // Skip stale entries for the user who just approved
        if (excludeId.isNotEmpty &&
            discMap['approver_id']?.toString() == excludeId) {
          continue;
        }

        pending.add(discMap);
      }
    }

    if (pending.isEmpty) return null;

    pending.sort((a, b) {
      final aLevel = parseLevel(a['approver_level_id']);
      final bLevel = parseLevel(b['approver_level_id']);
      return aLevel.compareTo(bLevel);
    });

    return pending.first;
  }

  /// Fetches the FCM device token for a given user from the Ruby API.
  static Future<String?> _fetchFcmToken({
    required String userId,
    required String accessToken,
  }) async {
    try {
      final res = await _api.get(
        '/device_tokens',
        token: accessToken,
        queryParams: {'user_id': userId},
      );

      if (res.statusCode != 200) {
        Log.warning(
          'FCM token fetch failed (status ${res.statusCode})',
          tag: 'ApprovalDecisionService',
        );
        return null;
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final result = body['result'];
      if (result is List && result.isNotEmpty) {
        return (result.first as Map<String, dynamic>)['token']?.toString();
      } else if (result is Map) {
        return result['token']?.toString();
      }
      return null;
    } catch (e, st) {
      Log.error(e, st, reason: 'ApprovalDecision._fetchFcmToken');
      return null;
    }
  }

  /// Invokes a Firebase Cloud Function by name with the given params.
  /// Silently no-ops when Firebase Core has not been initialized.
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
        tag: 'ApprovalDecisionService',
      );
    }
  }
}
