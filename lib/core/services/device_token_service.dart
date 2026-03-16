import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/log.dart';
import 'api_client.dart';

/// Handles device token (FCM) registration against the Ruby backend
/// with smart 422 parsing.
///
/// Separated from [FcmTokenService] so the backend-interaction logic
/// (especially the 422 edge-case handling) lives in one testable place.
class DeviceTokenService {
  DeviceTokenService._();

  static final ApiClient _api = ApiClient.instance;

  /// Fetches the current FCM token from Firebase and POSTs it to the
  /// backend. Runs silently — never throws to the caller.
  ///
  /// Returns `true` if the token was successfully registered (including
  /// the case where the backend says it already exists — HTTP 422 with
  /// an 'already'/'duplicate'/'exists' message).
  /// Returns `false` on any genuine failure.
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

      return _postToken(
        userId: userId,
        fcmToken: fcmToken,
        accessToken: accessToken,
      );
    } catch (e, st) {
      Log.warning('syncFcmToken failed: $e', tag: 'DeviceToken');
      Log.error(e, st, reason: 'DeviceToken.syncFcmToken');
      return false;
    }
  }

  /// Removes the device token from the backend, then deletes the local
  /// Firebase token. Silently swallows errors.
  static Future<void> deleteToken({
    required String userId,
    required String accessToken,
  }) async {
    try {
      final res = await _api.delete(
        '/device_tokens',
        token: accessToken,
        queryParams: {'user_id': userId},
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        Log.warning(
          'delete failed (${res.statusCode}): ${res.body}',
          tag: 'DeviceToken',
        );
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'DeviceToken.deleteFromServer');
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      Log.error(e, st, reason: 'DeviceToken.deleteLocal');
    }
  }

  // ── Backend POST with smart 422 handling ──────────────────────

  /// POSTs the FCM token to `/device_tokens`.
  ///
  /// **422 smart parsing:**
  ///  - If the response body contains 'already', 'duplicate', or 'exists'
  ///    → treat as success (token was previously registered).
  ///  - If it contains 'not save' or 'failed'
  ///    → treat as real failure.
  static Future<bool> _postToken({
    required String userId,
    required String fcmToken,
    required String accessToken,
  }) async {
    final res = await _api.post(
      '/device_tokens',
      token: accessToken,
      body: {'user_id': userId, 'token': fcmToken},
    );

    if (res.statusCode == 200 || res.statusCode == 201) return true;

    if (res.statusCode == 422) {
      return _handle422(res.body);
    }

    Log.warning(
      'POST /device_tokens failed (${res.statusCode}): ${res.body}',
      tag: 'DeviceToken',
    );
    return false;
  }

  /// Parses a 422 response to decide whether the token sync
  /// actually succeeded (duplicate) or truly failed.
  static bool _handle422(String body) {
    final text = _extractMessageText(body);

    const successIndicators = ['already', 'duplicate', 'exists'];
    const failureIndicators = ['not save', 'failed'];

    for (final keyword in failureIndicators) {
      if (text.contains(keyword)) {
        Log.warning(
          '422 → real failure (matched "$keyword"): $text',
          tag: 'DeviceToken',
        );
        return false;
      }
    }

    for (final keyword in successIndicators) {
      if (text.contains(keyword)) {
        Log.warning(
          '422 → treated as success (matched "$keyword"): $text',
          tag: 'DeviceToken',
        );
        return true;
      }
    }

    Log.warning('422 → unrecognised message: $text', tag: 'DeviceToken');
    return false;
  }

  /// Extracts a combined lowercase string from the `message` and `error`
  /// fields of a JSON response body. Falls back to the raw body text.
  static String _extractMessageText(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final msg = data['message']?.toString().toLowerCase() ?? '';
        final err = data['error']?.toString().toLowerCase() ?? '';
        return '$msg $err'.trim();
      }
    } catch (_) {
      // not valid JSON
    }
    return body.toLowerCase();
  }
}
