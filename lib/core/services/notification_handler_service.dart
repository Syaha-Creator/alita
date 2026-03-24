import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../firebase_options.dart';
import '../../features/history/data/models/order_history.dart';
import '../utils/log.dart';

/// Handles FCM notification display and tap navigation.
///
/// - [init]: permission, local notification plugin, [onMessage] / [onMessageOpenedApp].
/// - [registerNavigateCallback]: provide GoRouter so tap / getInitialMessage can navigate.
/// - [handleInitialMessage]: call once when app is ready; navigates if app was opened from a notification.
///
/// Foreground FCM messages are shown via [flutter_local_notifications] (system tray, sound, tappable).

/// Top-level entry point for FCM when app is in background or terminated.
/// Runs in a separate isolate — must ensure Firebase is initialized.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // ignore: avoid_print
  print('[FCM] Background message: ${message.messageId}');
}

class NotificationHandlerService {
  NotificationHandlerService._();

  static bool _firebaseReady = false;
  static GoRouter? _router;
  static VoidCallback? _onApprovalDataChanged;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _androidChannelId = 'approval_channel';
  static const String _androidChannelName = 'Persetujuan';

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

  /// Register a callback to refresh approval data when a relevant FCM
  /// notification arrives while the app is in the foreground.
  static void registerApprovalRefreshCallback(VoidCallback callback) {
    _onApprovalDataChanged = callback;
  }

  static Future<void> _ensureLocalNotificationsPlugin() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: 'Notifikasi persetujuan Surat Pesanan',
        importance: Importance.high,
        playSound: true,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initialize: permission + local notifications + onMessage + onMessageOpenedApp.
  /// Call from main() after Firebase.initializeApp().
  static Future<void> init() async {
    if (!_firebaseReady) return;

    await requestPermission();
    await _ensureLocalNotificationsPlugin();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);
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
    'approval',
    'approval_inbox',
    'next_approver',
    'fully_approved',
    'rejected',
    'reminder',
  };

  static int _foregroundNotificationId(RemoteMessage message) {
    final no = message.data['order_letter_no']?.toString() ?? '';
    final type = message.data['type']?.toString() ?? '';
    var h = Object.hash(no, type, message.messageId ?? '');
    if (h == 0) {
      h = DateTime.now().millisecondsSinceEpoch;
    }
    return h.abs() % 2147483647;
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Notifikasi';
    final body = message.notification?.body ?? '';

    final type = (message.data['type'] ?? message.data['screen'] ?? '')
        .toString()
        .toLowerCase();
    if (_approvalTypes.contains(type)) {
      _onApprovalDataChanged?.call();
    }

    final payloadMap = <String, String>{
      for (final e in message.data.entries) e.key: e.value.toString(),
    };

    final androidDetails = const AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: 'Notifikasi persetujuan Surat Pesanan',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _localNotifications.show(
        _foregroundNotificationId(message),
        title,
        body.isEmpty ? title : body,
        details,
        payload: jsonEncode(payloadMap),
      );
    } catch (e, st) {
      Log.error(e, st, reason: 'FCM foreground local notification');
    }
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final data = <String, String>{
        for (final e in decoded.entries)
          e.key.toString(): e.value?.toString() ?? '',
      };
      _navigateFromDataMap(data);
    } catch (e, st) {
      Log.error(e, st, reason: 'FCM local notification tap payload');
    }
  }

  static void _navigateFromMessage(RemoteMessage message) {
    _navigateFromDataMap(
      message.data.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  static void _navigateFromDataMap(Map<String, String> data) {
    if (data.isEmpty) return;

    void runNavigation(GoRouter router) {
      final type =
          (data['type'] ?? data['screen'] ?? '').toString().toLowerCase();

      Map<String, dynamic>? parseOrderData() {
        final raw = data['order_data'] ?? data['order_wrap'] ?? data['payload'];
        if (raw == null || raw.trim().isEmpty) return null;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (e, st) {
          Log.error(e, st, reason: 'FCM: failed to decode order_data JSON');
        }
        return null;
      }

      int? parseOrderLetterId() {
        final raw = data['order_letter_id'] ?? data['order_id'];
        if (raw == null || raw.isEmpty) return null;
        return int.tryParse(raw);
      }

      void pushOrderDetailFromNotification() {
        final id = parseOrderLetterId();
        final no = data['order_letter_no'] ?? '';
        if (id != null && id > 0) {
          router.push(
            '/order_detail',
            extra: orderHistoryStubFromNotification(
              id: id,
              orderLetterNo: no,
            ),
          );
        } else {
          router.push('/order_history');
        }
      }

      void pushApprovalFromOrderId() {
        final id = parseOrderLetterId();
        if (id != null && id > 0) {
          router.push('/approval_from_order/$id');
        } else {
          router.push('/approval_inbox');
        }
      }

      switch (type) {
        case 'approval_detail':
          final orderData = parseOrderData();
          if (orderData != null) {
            router.push('/approval_detail', extra: orderData);
            break;
          }
          pushApprovalFromOrderId();
          break;
        case 'fully_approved':
        case 'rejected':
          pushOrderDetailFromNotification();
          break;
        case 'next_approver':
          pushApprovalFromOrderId();
          break;
        case 'approval':
        case 'approval_inbox':
        case 'reminder':
          router.push('/approval_inbox');
          break;
        case 'order':
        case 'order_history':
          router.push('/order_history');
          break;
        default:
          router.push('/');
      }
    }

    // Dua frame: pastikan ShellRoute + [MaterialApp.router] siap (cold start / tap tray).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = _router;
        if (router == null) return;
        runNavigation(router);
      });
    });
  }
}
