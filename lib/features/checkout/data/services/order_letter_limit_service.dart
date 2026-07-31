import 'dart:convert';

import '../../../../core/services/api_client.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/retry.dart';

/// Fetches the remaining discount-approval limit ("plafon") for an
/// Analyst-level approver from `GET /order_letter_limits?user_id=`.
///
/// Used by [AnalystLimitAutoApprover] to decide whether an order's
/// Analyst-level (`approver_level_id: 4`) discount rows can be auto-approved
/// at checkout submission time instead of waiting for manual approval.
class OrderLetterLimitService {
  OrderLetterLimitService({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// Returns the analyst's remaining approval limit (`result.available`),
  /// or `null` if the call fails/times out/response is malformed.
  ///
  /// Callers MUST treat `null` as "unknown" and fall back to the normal
  /// manual-approval flow (fail-safe, never fail-open) — this endpoint is
  /// an optimization, not a gate that should ever block checkout.
  Future<double?> fetchAvailableLimit(int analystUserId) async {
    try {
      final response = await retry(
        () => _api.get(
          '/order_letter_limits',
          queryParams: {'user_id': analystUserId.toString()},
          timeout: const Duration(seconds: 10),
        ),
        maxAttempts: 2,
        tag: 'OrderLetterLimitService',
      );

      if (response.statusCode != 200) {
        Log.warning(
          'order_letter_limits HTTP ${response.statusCode} '
          'untuk analyst user_id=$analystUserId',
          tag: 'OrderLetterLimitService',
        );
        return null;
      }

      final decoded = json.decode(response.body);
      final result = decoded is Map ? decoded['result'] : null;
      if (result is! Map) return null;

      final available = result['available'];
      if (available == null) return null;
      return double.tryParse(available.toString());
    } on Exception catch (e, st) {
      Log.error(e, st, reason: 'OrderLetterLimitService.fetchAvailableLimit');
      return null;
    }
  }
}
