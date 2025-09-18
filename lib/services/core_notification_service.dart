import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'device_token_service.dart';
import 'notification_template_service.dart';
import 'push_notif_service.dart';
import 'auth_service.dart';

/// Core Notification Service - Unified service that handles ALL notification functionality
/// This service consolidates 9 different notification services into one comprehensive solution
///
/// Features:
/// - Firebase Cloud Messaging (FCM)
/// - Local Notifications
/// - Order Letter Creation Flow
/// - Approval Flow Notifications
/// - Template-based notifications
/// - Device token management
/// - Multi-device support
class CoreNotificationService {
  static final CoreNotificationService _instance =
      CoreNotificationService._internal();
  factory CoreNotificationService() => _instance;
  CoreNotificationService._internal();

  // Firebase Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Local Notifications
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Dependencies
  late final DeviceTokenService _deviceTokenService;

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('🚀 Initializing CoreNotificationService...');
      }

      // Initialize dependencies
      _deviceTokenService = DeviceTokenService();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ CoreNotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing CoreNotificationService: $e');
      }
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
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
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      if (kDebugMode) {
        print('📱 Local notifications initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing local notifications: $e');
      }
      rethrow;
    }
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission
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
        print('🔔 FCM Permission: ${settings.authorizationStatus}');
      }

      // Get device token
      String? deviceToken = await _firebaseMessaging.getToken();
      if (deviceToken != null) {
        if (kDebugMode) {
          print('📱 Device Token: ${deviceToken.substring(0, 20)}...');
        }

        // Auto sync with API
        _syncDeviceTokenWithAPI(deviceToken);
      }

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('🔄 Token refreshed: ${newToken.substring(0, 20)}...');
        }
        _syncDeviceTokenWithAPI(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessageHandler);

      // Handle app opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

      // Check initial message
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpened(initialMessage);
      }

      if (kDebugMode) {
        print('🔥 Firebase messaging initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Firebase messaging: $e');
      }
      rethrow;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    try {
      const List<AndroidNotificationChannel> channels = [
        AndroidNotificationChannel(
          'alita_notifications',
          'Alita Notifications',
          description: 'General notifications for Alita app',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
        AndroidNotificationChannel(
          'alita_fcm_notifications',
          'Alita FCM Notifications',
          description: 'Firebase Cloud Messaging notifications',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
        AndroidNotificationChannel(
          'alita_order_notifications',
          'Order Notifications',
          description: 'Order letter related notifications',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
        AndroidNotificationChannel(
          'alita_approval_notifications',
          'Approval Notifications',
          description: 'Approval related notifications',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
      ];

      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        for (final channel in channels) {
          await androidImplementation.createNotificationChannel(channel);
        }
      }

      if (kDebugMode) {
        print('📺 Created ${channels.length} notification channels');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating notification channels: $e');
      }
    }
  }

  // ===== ORDER LETTER CREATION FLOW =====

  /// Handle complete order letter creation notification flow
  /// 1. Local notification to creator
  /// 2. FCM notification to Direct Leader (first level)
  Future<bool> handleOrderLetterCreation({
    required String creatorUserId,
    required String orderId,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('📋 === ORDER LETTER CREATION FLOW ===');
        print('Creator: $creatorUserId');
        print('Order ID: $orderId');
        print('Customer: $customerName');
        print('Amount: $totalAmount');
      }

      // Step 1: Send local notification to creator
      await _sendOrderLetterCreatedLocalNotification(
        orderId: orderId,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Step 2: Get direct leader (first level only)
      final leaderUserIds =
          await _deviceTokenService.getLeaderUserIds(creatorUserId);
      if (leaderUserIds.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No leaders found for creator: $creatorUserId');
        }
        return true; // Still success since local notification was sent
      }

      // Send to DIRECT LEADER ONLY (first in list)
      final directLeaderUserId = leaderUserIds.first;
      final success = await _sendOrderLetterApprovalRequest(
        leaderUserId: directLeaderUserId,
        creatorUserId: creatorUserId,
        orderId: orderId,
        approvalLevel: 'Direct Leader',
        customerName: customerName,
        totalAmount: totalAmount,
      );

      if (kDebugMode) {
        print(success
            ? '✅ Order letter creation flow completed'
            : '❌ Failed to notify direct leader');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in order letter creation flow: $e');
      }
      return false;
    }
  }

  /// Send local notification to creator when order letter is created
  Future<void> _sendOrderLetterCreatedLocalNotification({
    required String orderId,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      final template = NotificationTemplateService.orderLetterCreated(
        orderId: orderId,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: template['title']!,
        body: template['body']!,
        channelId: 'alita_order_notifications',
        payload: 'order_letter_created:$orderId',
      );

      if (kDebugMode) {
        print('📱 Local notification sent to creator');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending local notification to creator: $e');
      }
    }
  }

  /// Send FCM notification for approval request
  Future<bool> _sendOrderLetterApprovalRequest({
    required String leaderUserId,
    required String creatorUserId,
    required String orderId,
    required String approvalLevel,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      // Get leader's device tokens
      final leaderTokens =
          await _deviceTokenService.getDeviceTokens(leaderUserId);
      if (leaderTokens.isEmpty) {
        if (kDebugMode) {
          print('❌ No device tokens found for leader: $leaderUserId');
        }
        return false;
      }

      // Create notification template
      final template = NotificationTemplateService.newApprovalRequest(
        orderId: orderId,
        approvalLevel: NotificationTemplateService.getApprovalLevelDisplayName(
            approvalLevel),
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Create notification data
      final notificationData =
          NotificationTemplateService.generateNotificationData(
        type: 'new_order_letter_approval',
        orderId: orderId,
        approvalLevel: approvalLevel,
        creatorUserId: creatorUserId,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Send to all leader's devices
      final success = await _sendFCMToMultipleDevices(
        deviceTokens: leaderTokens.map((t) => t.token).toList(),
        title: template['title']!,
        body: template['body']!,
        data: notificationData,
      );

      if (kDebugMode) {
        print(success
            ? '🔔 FCM sent to leader successfully'
            : '❌ Failed to send FCM to leader');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending approval request: $e');
      }
      return false;
    }
  }

  // ===== APPROVAL FLOW NOTIFICATIONS =====

  /// Handle approval flow notifications (when someone approves/rejects)
  Future<bool> handleApprovalFlowNotification({
    required String orderLetterId,
    required String approverUserId,
    required String approverName,
    required String approvalAction, // 'approve' or 'reject'
    required String approvalLevel,
    String? comment,
    String? orderDetails,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 === APPROVAL FLOW NOTIFICATION ===');
        print('Order: $orderLetterId');
        print('Approver: $approverName ($approverUserId)');
        print('Action: $approvalAction');
        print('Level: $approvalLevel');
      }

      // Step 1: Get creator user ID
      final creatorUserId = await _getCreatorUserId(orderLetterId);
      if (creatorUserId == null) {
        if (kDebugMode) {
          print('❌ Could not find creator for order: $orderLetterId');
        }
        return false;
      }

      // Step 2: Notify creator about approval status
      await _notifyCreatorAboutApproval(
        creatorUserId: creatorUserId,
        orderLetterId: orderLetterId,
        approverName: approverName,
        approvalAction: approvalAction,
        approvalLevel: approvalLevel,
        comment: comment,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Step 3: If approved, check for next level
      if (approvalAction.toLowerCase() == 'approve') {
        await _notifyNextLevelApprover(
          creatorUserId: creatorUserId,
          orderLetterId: orderLetterId,
          currentApprovalLevel: approvalLevel,
          customerName: customerName,
          totalAmount: totalAmount,
        );
      }

      if (kDebugMode) {
        print('✅ Approval flow notification completed');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in approval flow notification: $e');
      }
      return false;
    }
  }

  /// Get creator user ID from order letter
  Future<String?> _getCreatorUserId(String orderLetterId) async {
    try {
      // In a real implementation, this would query your database
      // For now, use current user as fallback
      final currentUserId = await AuthService.getCurrentUserId();
      return currentUserId?.toString();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting creator user ID: $e');
      }
      return null;
    }
  }

  /// Notify creator about approval status
  Future<void> _notifyCreatorAboutApproval({
    required String creatorUserId,
    required String orderLetterId,
    required String approverName,
    required String approvalAction,
    required String approvalLevel,
    String? comment,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      // Get creator's device tokens
      final creatorTokens =
          await _deviceTokenService.getDeviceTokens(creatorUserId);
      if (creatorTokens.isEmpty) {
        if (kDebugMode) {
          print('❌ No device tokens found for creator: $creatorUserId');
        }
        return;
      }

      // Create notification template
      final template = NotificationTemplateService.approvalStatusUpdate(
        orderId: orderLetterId,
        approverName: approverName,
        approvalAction: approvalAction,
        approvalLevel: NotificationTemplateService.getApprovalLevelDisplayName(
            approvalLevel),
        comment: comment,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Create notification data
      final notificationData =
          NotificationTemplateService.generateNotificationData(
        type: 'approval_status_update',
        orderId: orderLetterId,
        approvalLevel: approvalLevel,
        approvalAction: approvalAction,
        customerName: customerName,
        totalAmount: totalAmount,
        comment: comment,
        additionalData: {'approver_name': approverName},
      );

      // Send FCM to creator
      await _sendFCMToMultipleDevices(
        deviceTokens: creatorTokens.map((t) => t.token).toList(),
        title: template['title']!,
        body: template['body']!,
        data: notificationData,
      );

      if (kDebugMode) {
        print('📱 Creator notified about approval status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error notifying creator: $e');
      }
    }
  }

  /// Notify next level approver (if exists)
  Future<void> _notifyNextLevelApprover({
    required String creatorUserId,
    required String orderLetterId,
    required String currentApprovalLevel,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      // Get all leader user IDs
      final leaderUserIds =
          await _deviceTokenService.getLeaderUserIds(creatorUserId);
      if (leaderUserIds.isEmpty) return;

      // Find current level index
      final currentLevelIndex = _getApprovalLevelIndex(currentApprovalLevel);
      if (currentLevelIndex == -1) return;

      // Check if there's a next level
      final nextLevelIndex = currentLevelIndex + 1;
      if (nextLevelIndex >= leaderUserIds.length) {
        if (kDebugMode) {
          print('🎉 Final approval reached for order: $orderLetterId');
        }
        // Send final approval notification to creator
        await _sendFinalApprovalNotification(
          creatorUserId: creatorUserId,
          orderLetterId: orderLetterId,
          customerName: customerName,
          totalAmount: totalAmount,
        );
        return;
      }

      // Send to next level approver
      final nextLevelUserId = leaderUserIds[nextLevelIndex];
      final nextLevelName = _getApprovalLevelName(nextLevelIndex);

      await _sendOrderLetterApprovalRequest(
        leaderUserId: nextLevelUserId,
        creatorUserId: creatorUserId,
        orderId: orderLetterId,
        approvalLevel: nextLevelName,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      if (kDebugMode) {
        print('🚀 Next level approver notified: $nextLevelName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error notifying next level approver: $e');
      }
    }
  }

  /// Send final approval notification to creator
  Future<void> _sendFinalApprovalNotification({
    required String creatorUserId,
    required String orderLetterId,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      // Get creator's device tokens
      final creatorTokens =
          await _deviceTokenService.getDeviceTokens(creatorUserId);
      if (creatorTokens.isEmpty) return;

      // Create final approval template
      final template = NotificationTemplateService.finalApprovalCompleted(
        orderId: orderLetterId,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Create notification data
      final notificationData =
          NotificationTemplateService.generateNotificationData(
        type: 'final_approval_completed',
        orderId: orderLetterId,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Send FCM to creator
      await _sendFCMToMultipleDevices(
        deviceTokens: creatorTokens.map((t) => t.token).toList(),
        title: template['title']!,
        body: template['body']!,
        data: notificationData,
      );

      if (kDebugMode) {
        print('🎉 Final approval notification sent to creator');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending final approval notification: $e');
      }
    }
  }

  // ===== CORE NOTIFICATION METHODS =====

  /// Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'alita_notifications',
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'alita_notifications',
        'Alita Notifications',
        channelDescription: 'General notifications for Alita app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing local notification: $e');
      }
    }
  }

  /// Send FCM to single device
  Future<bool> _sendFCMToDevice({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get server key
      String serverKey = await PushNotificationService.getAccessToken();

      // FCM API URL
      String url =
          "https://fcm.googleapis.com/v1/projects/alita-pricelist/messages:send";

      // Headers
      var headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      };

      // Message payload
      Map<String, dynamic> message = {
        "message": {
          "token": deviceToken,
          "notification": {"body": body, "title": title},
          "data": data ?? {},
          "android": {
            "priority": "high",
            "notification": {
              "channel_id": "alita_fcm_notifications",
              "default_sound": true,
              "default_vibrate_timings": true,
            },
          },
          "apns": {
            "headers": {"apns-priority": "10"},
            "payload": {
              "aps": {"sound": "default", "badge": 1},
            },
          },
        }
      };

      // Send request
      final Dio dio = Dio();
      final Response response = await dio.post(
        url,
        data: message,
        options: Options(headers: headers),
      );

      bool success = response.statusCode == 200;

      if (kDebugMode) {
        print(success
            ? '✅ FCM sent successfully'
            : '❌ FCM failed: ${response.statusCode}');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending FCM: $e');
      }
      return false;
    }
  }

  /// Send FCM to multiple devices
  Future<bool> _sendFCMToMultipleDevices({
    required List<String> deviceTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (deviceTokens.isEmpty) return false;

    bool allSuccess = true;
    for (String token in deviceTokens) {
      final success = await _sendFCMToDevice(
        deviceToken: token,
        title: title,
        body: body,
        data: data,
      );
      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  // ===== PUBLIC API METHODS =====

  /// Show simple local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Send FCM notification to specific user
  Future<bool> sendFCMToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userTokens = await _deviceTokenService.getDeviceTokens(userId);
      if (userTokens.isEmpty) return false;

      return await _sendFCMToMultipleDevices(
        deviceTokens: userTokens.map((t) => t.token).toList(),
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending FCM to user: $e');
      }
      return false;
    }
  }

  /// Test notification functionality
  Future<bool> testNotification({
    String testType = 'General',
    String? additionalInfo,
  }) async {
    try {
      final template = NotificationTemplateService.testNotification(
        testType: testType,
        additionalInfo: additionalInfo,
      );

      await showLocalNotification(
        title: template['title']!,
        body: template['body']!,
        payload: 'test:$testType',
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error testing notification: $e');
      }
      return false;
    }
  }

  // ===== UTILITY METHODS =====

  /// Get approval level index from name
  int _getApprovalLevelIndex(String levelName) {
    switch (levelName.toLowerCase()) {
      case 'direct leader':
        return 0;
      case 'indirect leader':
        return 1;
      case 'controller':
        return 2;
      case 'analyst':
        return 3;
      default:
        return -1;
    }
  }

  /// Get approval level name from index
  String _getApprovalLevelName(int index) {
    switch (index) {
      case 0:
        return 'Direct Leader';
      case 1:
        return 'Indirect Leader';
      case 2:
        return 'Controller';
      case 3:
        return 'Analyst';
      default:
        return 'Level ${index + 1}';
    }
  }

  /// Sync device token with API
  Future<void> _syncDeviceTokenWithAPI(String deviceToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId == null) return;

      await _deviceTokenService.checkAndUpdateToken(
        userId.toString(),
        deviceToken,
      );

      if (kDebugMode) {
        print('🔄 Device token synced with API');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing device token: $e');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📨 Foreground message: ${message.notification?.title}');
    }

    // Show local notification for foreground messages
    if (message.notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? 'You have a new message',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification opened
  void _handleNotificationOpened(RemoteMessage message) {
    if (kDebugMode) {
      print('🔓 Notification opened: ${message.data}');
    }
    // Handle navigation based on notification data
    // This can be expanded based on your app's navigation needs
  }

  /// Handle local notification tapped
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('👆 Local notification tapped: ${response.payload}');
    }
    // Handle local notification tap
    // This can be expanded based on your app's navigation needs
  }

  /// Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'service_name': 'CoreNotificationService',
      'status': _isInitialized ? 'initialized' : 'not_initialized',
      'features': [
        'Firebase Cloud Messaging (FCM)',
        'Local Notifications',
        'Order Letter Creation Flow',
        'Approval Flow Notifications',
        'Template-based Notifications',
        'Multi-device Support',
        'Device Token Management',
      ],
      'replaces_services': [
        'NotificationService',
        'LocalNotificationService',
        'UnifiedNotificationService',
        'ApprovalNotificationService',
        'ApprovalFlowNotificationService',
        'OrderLetterNotificationService',
        'SendNotificationService',
      ],
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Top-level function for handling background messages
Future<void> _firebaseMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('🔔 Background message: ${message.messageId}');
  }
  // Handle background message
  // You can show local notification here if needed
}
