import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/log.dart';

/// Handles FCM notification display and tap navigation.
///
/// - [init]: request permission, subscribe to [onMessage] / [onMessageOpenedApp].
/// - [registerNavigateCallback]: provide GoRouter so tap / getInitialMessage can navigate.
/// - [registerScaffoldMessengerKey]: optional, to show SnackBar when message received in foreground.
/// - [handleInitialMessage]: call once when app is ready; navigates if app was opened from a notification.
/// Top-level entry point for FCM when app is in background or terminated.
/// Must not use Flutter/UI or heavy dependencies (runs in separate isolate).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Minimal work; logging via print to avoid Flutter/Crashlytics in isolate.
  // ignore: avoid_print
  print('[FCM] Background message: ${message.messageId}');
}

class NotificationHandlerService {
  NotificationHandlerService._();

  static bool _firebaseReady = false;
  static GlobalKey<ScaffoldMessengerState>? _scaffoldKey;
  static GoRouter? _router;
  static VoidCallback? _onApprovalDataChanged;

  /// Mark Firebase as ready so FCM calls are safe.
  /// Call from main() after Firebase.initializeApp() succeeds.
  static void setFirebaseReady() => _firebaseReady = true;

  /// Request notification permission (iOS/Android).
  /// Call after Firebase is initialized.
  static Future<NotificationSettings?> requestPermission() async {
    if (!_firebaseReady) return null;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings;
  }

  /// Register the router so tap / initial message can navigate.
  static void registerNavigateCallback(GoRouter router) {
    _router = router;
  }

  /// Optional: register to show SnackBar when a message is received in foreground.
  static void registerScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldKey = key;
  }

  /// Register a callback to refresh approval data when a relevant FCM
  /// notification arrives while the app is in the foreground.
  static void registerApprovalRefreshCallback(VoidCallback callback) {
    _onApprovalDataChanged = callback;
  }

  /// Initialize: permission + onMessage + onMessageOpenedApp.
  /// Call from main() after Firebase.initializeApp().
  static Future<void> init() async {
    if (!_firebaseReady) return;

    await requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _onForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromMessage(message);
    });
  }

  /// Call once when the app widget is built (e.g. post-frame).
  /// If the app was opened from a notification (killed state), navigates.
  static Future<void> handleInitialMessage() async {
    if (!_firebaseReady) return;

    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      _navigateFromMessage(message);
    }
  }

  static const _approvalTypes = {
    'approval', 'approval_inbox', 'next_approver', 'fully_approved',
  };

  static void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notifikasi';
    final body = message.notification?.body ?? '';

    // Auto-refresh approval data when relevant notification arrives
    final type =
        (message.data['type'] ?? message.data['screen'] ?? '')
            .toString()
            .toLowerCase();
    if (_approvalTypes.contains(type)) {
      _onApprovalDataChanged?.call();
    }

    final ctx = _scaffoldKey?.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(body.isEmpty ? title : '$title\n$body'),
        ),
      );
    }
  }

  static void _navigateFromMessage(RemoteMessage message) {
    final router = _router;
    if (router == null) return;

    final data = message.data;
    if (data.isEmpty) {
      return;
    }

    final type = (data['type'] ?? data['screen'] ?? '').toString().toLowerCase();

    Map<String, dynamic>? parseOrderData() {
      final raw = data['order_data'] ?? data['order_wrap'] ?? data['payload'];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is String && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (e, st) {
          Log.error(e, st, reason: 'FCM: failed to decode order_data JSON');
        }
      }
      return null;
    }

    switch (type) {
      case 'approval_detail':
        final orderData = parseOrderData();
        if (orderData != null) {
          router.go('/approval_detail', extra: orderData);
          break;
        }
        router.go('/approval_inbox');
        break;
      case 'approval':
      case 'approval_inbox':
      case 'next_approver':
      case 'fully_approved':
        router.go('/approval_inbox');
        break;
      case 'order':
      case 'order_history':
        router.go('/');
        break;
      default:
        router.go('/');
    }
  }
}
