import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_token_service.dart';
import 'send_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission for notifications
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // Get the device token (FCM registration token)
      String? deviceToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('Device Token (FCM): $deviceToken');
        print('Token Length: ${deviceToken?.length}');
        print('Token Format: ${deviceToken?.substring(0, 20)}...');
      }

      // Auto sync device token with API
      if (deviceToken != null) {
        _syncDeviceTokenWithAPI(deviceToken);
      }

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('Device Token refreshed: $newToken');
        }
        // Here you can send the new token to your server
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
          print('Message notification: ${message.notification}');
        }

        // Show local notification when app is in foreground
        _showLocalNotification(message);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessageHandler);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('App opened from notification: ${message.data}');
        }
        // Handle navigation or other actions when app is opened from notification
      });

      // Check initial message when app is opened from terminated state
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print(
              'App opened from terminated state with message: ${initialMessage.data}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notification service: $e');
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('Local notification tapped: ${response.payload}');
        }
      },
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    try {
      if (kDebugMode) {
        print('Attempting to show local notification...');
        print('Message notification: ${message.notification}');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        final title = message.notification!.title ?? 'New Message';
        final body = message.notification!.body ?? 'You have a new message';

        if (kDebugMode) {
          print('Showing local notification: $title - $body');
        }

        _localNotifications
            .show(
          message.hashCode,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'alita_fcm_notifications',
              'Alita FCM Notifications',
              channelDescription:
                  'Channel for Firebase Cloud Messaging notifications',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              enableVibration: true,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        )
            .then((_) {
          if (kDebugMode) {
            print('Local notification shown successfully');
          }
        }).catchError((error) {
          if (kDebugMode) {
            print('Error showing local notification: $error');
          }
        });
      } else {
        if (kDebugMode) {
          print('Message notification is null, cannot show local notification');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _showLocalNotification: $e');
      }
    }
  }

  // Get device token (FCM registration token)
  Future<String?> getDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('Getting device token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device token: $e');
      }
      return null;
    }
  }

  // Get current device token
  Future<String?> getCurrentDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('Current device token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current device token: $e');
      }
      return null;
    }
  }

  // Delete device token
  Future<void> deleteDeviceToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      if (kDebugMode) {
        print('Device token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting device token: $e');
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  // Auto sync device token with API
  Future<void> _syncDeviceTokenWithAPI(String deviceToken) async {
    try {
      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId == null) {
        if (kDebugMode) {
          print('No user ID found, cannot sync device token');
        }
        return;
      }

      if (kDebugMode) {
        print('Syncing device token for user: $userId');
        print('Device token: ${deviceToken.substring(0, 20)}...');
      }

      // Import DeviceTokenService
      final deviceTokenService = DeviceTokenService();

      // Check and update token
      final success = await deviceTokenService.checkAndUpdateToken(
        userId.toString(),
        deviceToken,
      );

      if (kDebugMode) {
        if (success) {
          print('Device token synced with API successfully');
        } else {
          print('Failed to sync device token with API');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing device token with API: $e');
      }
    }
  }

  // Test FCM notification to specific device (for testing)
  Future<bool> testFCMToDevice(
    String deviceToken, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('Testing FCM to device: ${deviceToken.substring(0, 20)}...');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
      }

      // This is a test method - in production, FCM should be sent through backend
      // For now, we'll simulate the FCM sending process
      if (kDebugMode) {
        print(
            'FCM test notification prepared for device: ${deviceToken.substring(0, 20)}...');
        print(
            'Note: This is a test - actual FCM delivery requires backend server');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing FCM to device: $e');
      }
      return false;
    }
  }

  // Test FCM notification to multiple devices (for testing)
  Future<bool> testFCMToMultipleDevices(
    List<String> deviceTokens, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('Testing FCM to ${deviceTokens.length} devices');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
      }

      for (String token in deviceTokens) {
        await testFCMToDevice(token, title: title, body: body, data: data);
      }

      if (kDebugMode) {
        print('FCM test notifications prepared for all devices successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing FCM to multiple devices: $e');
      }
      return false;
    }
  }

  // Send FCM notification to specific device
  Future<bool> sendFCMToDevice(
    String deviceToken, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('Sending FCM to device: $deviceToken');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
      }

      // This would typically be done through your backend server
      // For now, we'll just log the attempt
      if (kDebugMode) {
        print(
            'FCM notification prepared for device: ${deviceToken.substring(0, 20)}...');
        print('Note: Actual FCM sending should be done through backend server');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM to device: $e');
      }
      return false;
    }
  }

  // Send FCM notification to multiple devices
  Future<bool> sendFCMToMultipleDevices(
    List<String> deviceTokens, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('Sending FCM to ${deviceTokens.length} devices');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
      }

      for (String token in deviceTokens) {
        await sendFCMToDevice(token, title: title, body: body, data: data);
      }

      if (kDebugMode) {
        print('FCM notifications sent to all devices successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM to multiple devices: $e');
      }
      return false;
    }
  }

  // Send real FCM notification to specific device using backend service
  Future<bool> sendRealFCMToDevice(
    String deviceToken, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('Sending REAL FCM to device: ${deviceToken.substring(0, 20)}...');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
      }

      // Use backend service for FCM sending
      final success = await SendNotificationService.sendNotificationUsingApi(
        token: deviceToken,
        title: title,
        body: body,
        data: data,
      );

      if (success) {
        if (kDebugMode) {
          print(
              'FCM sent successfully to device: ${deviceToken.substring(0, 20)}...');
        }
        return true;
      } else {
        if (kDebugMode) {
          print(
              'FCM failed to send to device: ${deviceToken.substring(0, 20)}...');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending real FCM: $e');
      }
      return false;
    }
  }

  // Send real FCM notification to multiple devices using backend service
  Future<bool> sendRealFCMToMultipleDevices(
    List<String> deviceTokens, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('Sending REAL FCM to ${deviceTokens.length} devices');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
      }

      // Use backend service for FCM sending to multiple devices
      final success =
          await SendNotificationService.sendNotificationToMultipleDevices(
        tokens: deviceTokens,
        title: title,
        body: body,
        data: data,
      );

      if (success) {
        if (kDebugMode) {
          print('FCM sent successfully to all ${deviceTokens.length} devices');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('FCM failed to send to some devices');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending real FCM to multiple devices: $e');
      }
      return false;
    }
  }

  // Test local notification
  Future<void> testLocalNotification() async {
    try {
      if (kDebugMode) {
        print('Testing local notification...');
      }

      await _localNotifications.show(
        999, // Test notification ID
        'Test Notification',
        'This is a test notification from local notification service',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alita_fcm_notifications',
            'Alita FCM Notifications',
            channelDescription:
                'Channel for Firebase Cloud Messaging notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'test_notification',
      );

      if (kDebugMode) {
        print('Test local notification shown successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing test local notification: $e');
      }
    }
  }

  // Test local notification with custom message
  Future<void> testLocalNotificationWithCustomMessage({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (kDebugMode) {
        print('Testing local notification with custom message...');
        print('Title: $title');
        print('Body: $body');
      }

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique notification ID
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alita_notifications',
            'Alita Notifications',
            channelDescription: 'Channel for local notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload ?? 'custom_notification',
      );

      if (kDebugMode) {
        print('Custom local notification shown successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing custom local notification: $e');
      }
    }
  }

  // Legacy method for backward compatibility
  Future<String?> getToken() async {
    return getDeviceToken();
  }
}

// This needs to be a top-level function
Future<void> _firebaseMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification}');
  }
  // Handle background message here
  // You can show local notification here if needed
}
