import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void Function(String? payload)? _onTapCallback;

  Future<void> initialize({void Function(String? payload)? onTap}) async {
    try {
      _onTapCallback = onTap;

      // Initialize settings for Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Initialize settings for iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      if (kDebugMode) {
        print('Local Notification Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Local Notification Service: $e');
      }
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
      // Channel for general notifications
      const AndroidNotificationChannel generalChannel =
          AndroidNotificationChannel(
        'alita_notifications',
        'Alita Notifications',
        description: 'Channel for Alita app notifications',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

      // Channel for FCM notifications
      const AndroidNotificationChannel fcmChannel = AndroidNotificationChannel(
        'alita_fcm_notifications',
        'Alita FCM Notifications',
        description: 'Channel for Firebase Cloud Messaging notifications',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

      // Create channels
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(generalChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(fcmChannel);

      if (kDebugMode) {
        print('Notification channels created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating notification channels: $e');
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    _onTapCallback?.call(response.payload);
  }

  // Show simple notification
  Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'alita_notifications',
        'Alita Notifications',
        channelDescription: 'Channel for Alita app notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      if (kDebugMode) {
        print('Simple notification shown: $title - $body');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing simple notification: $e');
      }
    }
  }

  // Show notification with custom icon
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'alita_custom_notifications',
        'Alita Custom Notifications',
        channelDescription: 'Channel for Alita custom notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/logo'),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        1, // Notification ID
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      if (kDebugMode) {
        print('Custom notification shown: $title - $body');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing custom notification: $e');
      }
    }
  }

  // Show scheduled notification
  Future<void> showScheduledNotification({
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'alita_scheduled_notifications',
        'Alita Scheduled Notifications',
        channelDescription: 'Channel for Alita scheduled notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        2, // Notification ID
        title,
        body,
        tz.TZDateTime.now(tz.local).add(delay),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      if (kDebugMode) {
        print('Scheduled notification set for: ${delay.inSeconds} seconds');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  // Show notification with action buttons
  Future<void> showActionNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'alita_action_notifications',
        'Alita Action Notifications',
        channelDescription: 'Channel for Alita action notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        actions: [
          AndroidNotificationAction('action_1', 'Action 1'),
          AndroidNotificationAction('action_2', 'Action 2'),
        ],
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        3, // Notification ID
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      if (kDebugMode) {
        print('Action notification shown: $title - $body');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing action notification: $e');
      }
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      if (kDebugMode) {
        print('All notifications cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling notifications: $e');
      }
    }
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      if (kDebugMode) {
        print('Notification $id cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling notification $id: $e');
      }
    }
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      if (kDebugMode) {
        print('Pending notifications: ${pendingNotifications.length}');
      }
      return pendingNotifications;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending notifications: $e');
      }
      return [];
    }
  }
}
