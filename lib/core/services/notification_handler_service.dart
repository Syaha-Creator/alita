import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  static GlobalKey<ScaffoldMessengerState>? _scaffoldKey;
  static GoRouter? _router;

  /// Request notification permission (iOS/Android).
  /// Call after Firebase is initialized.
  static Future<NotificationSettings> requestPermission() async {
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

  /// Initialize: permission + onMessage + onMessageOpenedApp.
  /// Call from main() after Firebase.initializeApp().
  static Future<void> init() async {
    await requestPermission();

    // Foreground: show notification or in-app hint
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _onForegroundMessage(message);
    });

    // Tap when app in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromMessage(message);
    });
  }

  /// Call once when the app widget is built (e.g. post-frame).
  /// If the app was opened from a notification (killed state), navigates.
  static Future<void> handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      _navigateFromMessage(message);
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notifikasi';
    final body = message.notification?.body ?? '';

    if (_scaffoldKey?.currentContext != null) {
      ScaffoldMessenger.of(_scaffoldKey!.currentContext!).showSnackBar(
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

    switch (type) {
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
