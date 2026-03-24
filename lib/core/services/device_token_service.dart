import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/log.dart';
import 'api_client.dart';

/// Handles device token (FCM) registration against the Ruby/Rails backend.
///
/// Flow:
/// 1. GET existing tokens for user → compare with current FCM token
/// 2. If match found → skip (already registered)
/// 3. If old tokens exist but differ → DELETE old + POST new
/// 4. If none exist → POST new
class DeviceTokenService {
  DeviceTokenService._();

  static final ApiClient _api = ApiClient.instance;

  // ── Public API ──────────────────────────────────────────────

  /// Ensures the current FCM token is registered on the backend for [userId].
  /// Returns `true` on success, `false` on failure. Never throws.
  static Future<bool> syncFcmToken({
    required String userId,
    required String accessToken,
  }) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        Log.warning('FCM token kosong — skip sync', tag: 'DeviceToken');
        return false;
      }

      final records = await _getTokenRecords(
        userId: userId,
        accessToken: accessToken,
      );

      // Token already registered → nothing to do
      if (records.any((r) => r.token == fcmToken)) {
        return true;
      }

      // Old tokens exist → delete them first so POST doesn't hit unique constraint
      for (final old in records) {
        await _deleteById(id: old.id, accessToken: accessToken);
      }

      return await _postToken(
        userId: userId,
        fcmToken: fcmToken,
        accessToken: accessToken,
      );
    } catch (e) {
      Log.warning('syncFcmToken failed: $e', tag: 'DeviceToken');
      return false;
    }
  }

  /// Removes all device tokens for [userId] from the backend,
  /// then deletes the local Firebase token. Silently swallows errors.
  static Future<void> deleteToken({
    required String userId,
    required String accessToken,
  }) async {
    try {
      final records = await _getTokenRecords(
        userId: userId,
        accessToken: accessToken,
      );

      for (final record in records) {
        await _deleteById(id: record.id, accessToken: accessToken);
      }
    } catch (e) {
      Log.warning('DeviceToken.deleteFromServer: $e', tag: 'DeviceToken');
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      Log.warning('DeviceToken.deleteLocal: $e', tag: 'DeviceToken');
    }
  }

  // ── Private helpers ─────────────────────────────────────────

  /// GETs token records for [userId]. Returns id + token pairs.
  static Future<List<_TokenRecord>> _getTokenRecords({
    required String userId,
    required String accessToken,
  }) async {
    try {
      final res = await _api.get(
        '/device_tokens',
        token: accessToken,
        queryParams: {'user_id': userId},
      );

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) return [];

      final result = data['result'];
      if (result is List) {
        return result
            .whereType<Map<String, dynamic>>()
            .map(_TokenRecord.fromJson)
            .where((r) => r.token.isNotEmpty)
            .toList();
      } else if (result is Map<String, dynamic>) {
        final r = _TokenRecord.fromJson(result);
        return r.token.isNotEmpty ? [r] : [];
      }
    } catch (e) {
      Log.warning('GET /device_tokens failed: $e', tag: 'DeviceToken');
    }
    return [];
  }

  /// POSTs a new FCM token to `/device_tokens`.
  static Future<bool> _postToken({
    required String userId,
    required String fcmToken,
    required String accessToken,
  }) async {
    final res = await _api.post(
      '/device_tokens',
      token: accessToken,
      body: {'user_id': int.parse(userId), 'token': fcmToken},
    );

    if (res.statusCode == 200 || res.statusCode == 201) return true;

    Log.warning(
      'POST /device_tokens failed (${res.statusCode}): ${res.body}',
      tag: 'DeviceToken',
    );
    return false;
  }

  /// DELETEs a single token record by its server-side [id].
  static Future<void> _deleteById({
    required String id,
    required String accessToken,
  }) async {
    if (id.isEmpty) return;
    try {
      final res = await _api.delete(
        '/device_tokens/$id',
        token: accessToken,
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        Log.warning(
          'DELETE /device_tokens/$id failed (${res.statusCode}): ${res.body}',
          tag: 'DeviceToken',
        );
      }
    } catch (e) {
      Log.warning('DELETE /device_tokens/$id error: $e', tag: 'DeviceToken');
    }
  }
}

/// Lightweight record from the GET /device_tokens response.
class _TokenRecord {
  final String id;
  final String token;

  const _TokenRecord({required this.id, required this.token});

  factory _TokenRecord.fromJson(Map<String, dynamic> json) => _TokenRecord(
        id: json['id']?.toString() ?? '',
        token: json['token']?.toString() ?? '',
      );
}
