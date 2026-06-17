import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/app_config.dart';
import '../utils/log.dart';
import 'api_client.dart';

class DeviceTokenService {
  DeviceTokenService._();

  static final ApiClient _api = ApiClient.instance;

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

      if (records.any((r) => r.token == fcmToken)) return true;

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

  /// Deletes the local Firebase token on logout. Server-side cleanup
  /// is handled by the backend when the token becomes stale.
  static Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      Log.warning('DeviceToken.deleteLocal: $e', tag: 'DeviceToken');
    }
  }

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

  static Future<bool> _postToken({
    required String userId,
    required String fcmToken,
    required String accessToken,
  }) async {
    final res = await _api.post(
      '/device_tokens',
      token: accessToken,
      body: {
        'user_id': int.parse(userId),
        'token': fcmToken,
        'app_name': AppConfig.appName,
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) return true;

    Log.warning(
      'POST /device_tokens failed (${res.statusCode}): ${res.body}',
      tag: 'DeviceToken',
    );
    return false;
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
