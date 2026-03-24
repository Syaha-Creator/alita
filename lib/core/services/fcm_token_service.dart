import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/log.dart';
import 'device_token_service.dart';

/// Orchestrates FCM token lifecycle:
/// - [syncToken]: delegates to [DeviceTokenService.syncFcmToken]
/// - [listenToRefresh]: subscribes to Firebase token rotation and re-syncs
/// - [deleteToken]: delegates to [DeviceTokenService.deleteToken]
///
/// All backend-specific logic (422 handling, POST/DELETE) lives in
/// [DeviceTokenService]. This class handles only the Firebase SDK layer
/// and refresh subscription management.
class FcmTokenService {
  FcmTokenService._();

  static StreamSubscription<String>? _refreshSub;

  /// Syncs the current FCM token to the backend.
  /// Delegates the actual POST + 422 handling to [DeviceTokenService].
  static Future<void> syncToken({
    required String userId,
    required String accessToken,
  }) async {
    await DeviceTokenService.syncFcmToken(
      userId: userId,
      accessToken: accessToken,
    );
  }

  /// Subscribes to token refresh events so any Google-rotated token
  /// is automatically reported to the backend.
  static void listenToRefresh({
    required String userId,
    required String accessToken,
  }) {
    _refreshSub?.cancel();
    try {
      _refreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await DeviceTokenService.syncFcmToken(
            userId: userId,
            accessToken: accessToken,
          );
        } catch (e, st) {
          Log.error(e, st, reason: 'FCM.onTokenRefresh');
        }
      });
    } catch (e, st) {
      Log.error(e, st, reason: 'FCM.listenToRefresh');
    }
  }

  /// Cancels the refresh subscription without touching the backend.
  /// Called by [AuthNotifier.logout] after [DeviceTokenService.deleteToken].
  static Future<void> cancelRefreshListener() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
  }
}
