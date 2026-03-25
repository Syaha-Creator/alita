import 'dart:convert';

import '../../../../core/services/api_client.dart';
import '../../../../core/services/api_session_expired.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/log.dart';

/// Map hasil API (`order_letter` + `order_letter_details` + payments) untuk
/// [OrderHistory.fromApiJson] atau [ApprovalDetailPage].
Future<Map<String, dynamic>?> fetchOrderLetterResultWrap(int orderId) async {
  if (orderId <= 0) return null;
  try {
    final directResponse =
        await ApiClient.instance.get('/order_letters/$orderId');
    if (directResponse.statusCode == 401 ||
        directResponse.statusCode == 403) {
      throw ApiSessionExpiredException('GET /order_letters/$orderId');
    }
    if (directResponse.statusCode == 200) {
      final parsed = _parseResultMap(directResponse.body);
      if (parsed != null) return parsed;
    }

    final userId = await StorageService.loadUserId();
    final listResponse = await ApiClient.instance.get(
      '/order_letters',
      queryParams: {
        'user_id': userId.toString(),
        'order_letter_id': orderId.toString(),
      },
    );

    if (listResponse.statusCode == 401 || listResponse.statusCode == 403) {
      throw const ApiSessionExpiredException('GET /order_letters (by id)');
    }
    if (listResponse.statusCode == 200) {
      final body = jsonDecode(listResponse.body);
      final result = body is Map<String, dynamic> ? body['result'] : null;
      if (result is List) {
        for (final row in result) {
          final map = row is Map<String, dynamic>
              ? row
              : Map<String, dynamic>.from(row as Map);
          final letter = map['order_letter'] as Map?;
          final idRaw = letter?['id'];
          if (idRaw != null && int.tryParse(idRaw.toString()) == orderId) {
            return map;
          }
        }
      }
    }
  } catch (e, st) {
    if (e is ApiSessionExpiredException) rethrow;
    Log.error(e, st, reason: 'fetchOrderLetterResultWrap');
  }
  return null;
}

Map<String, dynamic>? _parseResultMap(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;

    final result = decoded['result'];
    if (result is Map<String, dynamic>) {
      return result;
    }
    if (decoded['order_letter'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  } catch (e, st) {
    Log.error(e, st, reason: 'order_letter_fetch._parseResultMap');
    return null;
  }
}
