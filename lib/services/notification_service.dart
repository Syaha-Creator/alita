import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import '../config/app_constant.dart';
import '../config/dependency_injection.dart';
import '../config/firebase_credentials.dart';
import '../features/approval/data/models/device_token_model.dart';
import '../navigation/navigation_service.dart';
import 'auth_service.dart';
import 'device_token_service.dart';
import 'leader_service.dart';
import 'local_notification_service.dart';
import 'notification_template_service.dart';
import 'order_letter_service.dart';

/// Unified Notification Service
/// Menggabungkan Local Notifications dan Firebase Cloud Messaging
/// Menyediakan interface yang powerful dan mudah digunakan
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final DeviceTokenService _deviceTokenService = DeviceTokenService();

  bool _isInitialized = false;
  String? _currentFcmToken;

  /// Initialize notification service (setup handlers, tidak perlu user login)
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('NotificationService already initialized');
      }
      return;
    }

    try {
      // Initialize local notifications
      await _localNotificationService.initialize(
        onTap: (payload) => handleNotificationTap(payload: payload),
      );

      // Initialize Firebase Messaging (setup handlers)
      await _initializeFirebaseMessaging();

      // Request notification permissions
      await _requestPermissions();

      // Get FCM token (tapi belum save ke backend)
      await _getFcmToken();

      _isInitialized = true;

      if (kDebugMode) {
        print('NotificationService initialized successfully');
      }

      // Jika user sudah login, langsung register token
      await _registerTokenIfLoggedIn();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission for iOS
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print(
            'Firebase Messaging permission status: ${settings.authorizationStatus}');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is terminated)
      FirebaseMessaging.onMessageOpenedApp
          .listen(_handleBackgroundMessageOpened);

      // Check if app was opened from notification
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessageOpened(initialMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Messaging: $e');
      }
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // For Android, permissions are handled automatically
      // For iOS, already requested in _initializeFirebaseMessaging
      if (kDebugMode) {
        print('Notification permissions requested');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permissions: $e');
      }
    }
  }

  /// Update token in backend (helper method)
  Future<void> _updateTokenInBackend(String token) async {
    try {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId != null) {
        await _deviceTokenService.checkAndUpdateToken(
          currentUserId.toString(),
          token,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating token in backend: $e');
      }
    }
  }

  /// Get FCM token (hanya ambil, belum save ke backend)
  Future<void> _getFcmToken() async {
    try {
      // Get FCM token
      _currentFcmToken = await FirebaseMessaging.instance.getToken();

      if (_currentFcmToken != null) {
        if (kDebugMode) {
          print('FCM Token: ${_currentFcmToken!.substring(0, 20)}...');
        }

        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _currentFcmToken = newToken;
          if (kDebugMode) {
            print('FCM Token refreshed: ${newToken.substring(0, 20)}...');
          }
          // Update token in backend jika user sudah login
          _updateTokenInBackend(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  /// Register FCM token ke backend (hanya jika user sudah login)
  Future<void> registerTokenToBackend() async {
    if (_currentFcmToken == null) {
      if (kDebugMode) {
        print('FCM Token is null, cannot register to backend');
      }
      return;
    }

    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) {
      if (kDebugMode) {
        print('User not logged in, skipping token registration');
      }
      return;
    }

    try {
      await _deviceTokenService.checkAndUpdateToken(
        currentUserId.toString(),
        _currentFcmToken!,
      );
      if (kDebugMode) {
        print('FCM Token registered to backend for user: $currentUserId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering FCM token to backend: $e');
      }
    }
  }

  /// Register token jika user sudah login (untuk dipanggil saat app start)
  Future<void> _registerTokenIfLoggedIn() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      await registerTokenToBackend();
    }
  }

  Future<auth.AutoRefreshingAuthClient?> _createFirebaseAuthClient() async {
    try {
      final credentials = auth.ServiceAccountCredentials.fromJson(
          FirebaseCredentials.serviceAccount);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      return await auth.clientViaServiceAccount(credentials, scopes);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating Firebase auth client: $e');
      }
      return null;
    }
  }

  /// Handle foreground message (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message received: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // Show local notification when app is in foreground
    if (message.notification != null) {
      _localNotificationService.showSimpleNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle background message opened (when user taps notification)
  void _handleBackgroundMessageOpened(RemoteMessage message) {
    if (kDebugMode) {
      print('Background message opened: ${message.messageId}');
      print('Data: ${message.data}');
    }

    handleNotificationTap(data: message.data);
  }

  /// Handle notification navigation based on payload/data
  void handleNotificationTap({Map<String, dynamic>? data, String? payload}) {
    _handleNotificationNavigation(data, payload: payload);
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic>? data,
      {String? payload}) {
    final notificationType = data?['notification_type'] ?? data?['type'];
    final orderIdString = data?['order_id'] ?? data?['orderId'] ?? payload;

    if (kDebugMode) {
      print('Notification navigation data: $data, payload: $payload');
    }

    if (orderIdString != null && orderIdString.isNotEmpty) {
      final int? orderId = int.tryParse(orderIdString);
      if (orderId != null) {
        Future.microtask(() {
          NavigationService.pushWithExtra(
            RoutePaths.orderLetterDocument,
            extra: orderId,
          );
        });
        return;
      }
    }

    if (kDebugMode) {
      print(
          'Unable to navigate: missing or invalid order_id for notification type $notificationType');
    }
  }

  // ==================== PUBLIC METHODS ====================

  /// Send notification to specific user(s) via Firebase Cloud Messaging
  /// using service account credentials stored in environment variables.
  Future<bool> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? notificationType,
  }) async {
    try {
      // Collect all unique device tokens for the target users
      final Set<String> targetTokens = <String>{};
      for (final userId in userIds) {
        final List<DeviceTokenModel> deviceTokens =
            await _deviceTokenService.getDeviceTokens(userId);
        for (final deviceToken in deviceTokens) {
          if (deviceToken.token.isNotEmpty) {
            targetTokens.add(deviceToken.token);
          }
        }
      }

      if (targetTokens.isEmpty) {
        if (kDebugMode) {
          print('No device tokens found for users: $userIds');
        }
        return false;
      }

      final auth.AutoRefreshingAuthClient? firebaseClient =
          await _createFirebaseAuthClient();

      if (firebaseClient == null) {
        if (kDebugMode) {
          print('Unable to create Firebase auth client.');
        }
        return false;
      }

      final Uri endpoint = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/${FirebaseCredentials.projectId}/messages:send');

      // Prepare data payload (FCM data expects string values)
      final Map<String, String> dataPayload = {};
      if (notificationType != null && notificationType.isNotEmpty) {
        dataPayload['notification_type'] = notificationType;
      }
      if (data != null) {
        data.forEach((key, value) {
          if (value != null) {
            dataPayload[key] = value.toString();
          }
        });
      }

      bool allSuccess = true;

      try {
        for (final token in targetTokens) {
          final Map<String, dynamic> payload = {
            'message': {
              'token': token,
              'notification': {
                'title': title,
                'body': body,
              },
              if (dataPayload.isNotEmpty) 'data': dataPayload,
            },
          };

          final http.Response response = await firebaseClient.post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );

          final bool success =
              response.statusCode >= 200 && response.statusCode < 300;

          if (!success) {
            allSuccess = false;
            if (kDebugMode) {
              print(
                  'Failed to send FCM to token $token: ${response.statusCode} - ${response.body}');
            }
          } else if (kDebugMode) {
            print('FCM sent successfully to token $token');
          }
        }
      } finally {
        firebaseClient.close();
      }

      return allSuccess;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      return false;
    }
  }

  /// Send notification to leaders when order letter is created
  Future<bool> notifyLeadersOnOrderLetterCreated({
    required String orderId,
    required String noSp,
    String? customerName,
    double? totalAmount,
    List<int>? leaderIds,
  }) async {
    try {
      // Get leader IDs if not provided
      List<int> targetLeaderIds = leaderIds ?? [];

      if (targetLeaderIds.isEmpty) {
        final currentUserId = await AuthService.getCurrentUserId();
        if (currentUserId != null) {
          final leaderService = locator<LeaderService>();
          final leaderData = await leaderService.getLeaderByUser();

          if (leaderData != null) {
            // Get direct leader (priority for approval)
            if (leaderData.directLeader != null) {
              targetLeaderIds.add(leaderData.directLeader!.id);
            }
            // Optionally add indirect leader
            if (leaderData.indirectLeader != null) {
              targetLeaderIds.add(leaderData.indirectLeader!.id);
            }
          }
        }
      }

      if (targetLeaderIds.isEmpty) {
        if (kDebugMode) {
          print('No leader IDs found for notification');
        }
        return false;
      }

      // Get notification template
      final notificationTemplate =
          NotificationTemplateService.newApprovalRequest(
        noSp: noSp,
        approvalLevel: 'Direct Leader',
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Send notification to each leader
      bool allSuccess = true;
      for (final leaderId in targetLeaderIds) {
        final success = await sendNotificationToUsers(
          userIds: [leaderId.toString()],
          title: notificationTemplate['title']!,
          body: notificationTemplate['body']!,
          data: NotificationTemplateService.generateNotificationData(
            type: 'approval_request',
            noSp: noSp,
            orderId: orderId, // Keep for backward compatibility
            approvalLevel: 'Direct Leader',
            customerName: customerName,
            totalAmount: totalAmount,
          ),
          notificationType: 'approval_request',
        );

        if (!success) {
          allSuccess = false;
        }
      }

      // Also show local notification to creator
      final creatorNotification =
          NotificationTemplateService.orderLetterCreated(
        noSp: noSp,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      await _localNotificationService.showSimpleNotification(
        title: creatorNotification['title']!,
        body: creatorNotification['body']!,
        payload: orderId, // Keep orderId in payload for navigation
      );

      return allSuccess;
    } catch (e) {
      if (kDebugMode) {
        print('Error notifying leaders on order letter created: $e');
      }
      return false;
    }
  }

  /// Notify after approval action
  /// Handles notification to creator and next approver if applicable
  Future<void> notifyOnApproval({
    required int orderLetterId,
    required int approvedLevelId,
    required String approverName,
    required String approvalLevel,
    required bool isFinalApproval,
    String? orderId,
    String? noSp,
    String? customerName,
    double? totalAmount,
    int? creatorUserId,
  }) async {
    try {
      // Get order letter info if not provided
      String finalOrderId = orderId ?? orderLetterId.toString();

      if (creatorUserId == null ||
          noSp == null ||
          customerName == null ||
          totalAmount == null) {
        // Try to get from order letter service
        final orderLetterService = locator<OrderLetterService>();
        final orderLetters = await orderLetterService.getOrderLetters();
        final orderLetter = orderLetters.firstWhere(
          (ol) {
            final id = ol['id'] ?? ol['order_letter_id'];
            return id == orderLetterId ||
                id.toString() == orderLetterId.toString();
          },
          orElse: () => <String, dynamic>{},
        );

        if (orderLetter.isNotEmpty) {
          creatorUserId ??= orderLetter['creator'] ?? orderLetter['creator_id'];
          noSp ??= orderLetter['no_sp'] ?? orderLetter['no_sp_number'];
          customerName ??= orderLetter['customer_name'];
          if (totalAmount == null) {
            final total = orderLetter['total'] ?? orderLetter['total_amount'];
            totalAmount =
                total != null ? double.tryParse(total.toString()) : null;
          }
          finalOrderId = orderId ??
              orderLetter['id']?.toString() ??
              orderLetter['order_letter_id']?.toString() ??
              orderLetterId.toString();
        }
      }

      // Ensure we have noSp
      final finalNoSp = noSp ?? finalOrderId;

      if (isFinalApproval) {
        // Final approval - notify creator that all approvals are done
        final notificationTemplate =
            NotificationTemplateService.finalApprovalCompleted(
          noSp: finalNoSp,
          customerName: customerName,
          totalAmount: totalAmount,
        );

        if (creatorUserId != null) {
          await sendNotificationToUsers(
            userIds: [creatorUserId.toString()],
            title: notificationTemplate['title']!,
            body: notificationTemplate['body']!,
            data: NotificationTemplateService.generateNotificationData(
              type: 'final_approval',
              noSp: finalNoSp,
              orderId: finalOrderId, // Keep for navigation compatibility
              customerName: customerName,
              totalAmount: totalAmount,
            ),
            notificationType: 'final_approval',
          );
        }

        // Also show local notification
        await showLocalNotification(
          title: notificationTemplate['title']!,
          body: notificationTemplate['body']!,
          payload: finalOrderId,
        );
      } else {
        // Not final - notify creator about status and notify next approver
        final nextLevelInfo = await _getNextApprovalLevel(
          orderLetterId,
          approvedLevelId,
        );

        if (nextLevelInfo != null) {
          final nextLevelName = nextLevelInfo['level_name'] as String;
          final nextApproverId = nextLevelInfo['approver_id'] as int?;

          // Notify creator that current level approved, waiting for next level
          final creatorNotification =
              NotificationTemplateService.approvalStatusUpdateWithNextLevel(
            noSp: finalNoSp,
            approverName: approverName,
            approvedLevel: approvalLevel,
            nextLevel: nextLevelName,
            customerName: customerName,
            totalAmount: totalAmount,
          );

          if (creatorUserId != null) {
            await sendNotificationToUsers(
              userIds: [creatorUserId.toString()],
              title: creatorNotification['title']!,
              body: creatorNotification['body']!,
              data: NotificationTemplateService.generateNotificationData(
                type: 'approval_status_update',
                noSp: finalNoSp,
                orderId: finalOrderId,
                approvalLevel: approvalLevel,
                approvalAction: 'approve',
                customerName: customerName,
                totalAmount: totalAmount,
              ),
              notificationType: 'approval_status_update',
            );
          }

          // Notify next approver about new approval request
          if (nextApproverId != null) {
            final nextApproverNotification =
                NotificationTemplateService.newApprovalRequest(
              noSp: finalNoSp,
              approvalLevel: nextLevelName,
              customerName: customerName,
              totalAmount: totalAmount,
            );

            await sendNotificationToUsers(
              userIds: [nextApproverId.toString()],
              title: nextApproverNotification['title']!,
              body: nextApproverNotification['body']!,
              data: NotificationTemplateService.generateNotificationData(
                type: 'approval_request',
                noSp: finalNoSp,
                orderId: finalOrderId,
                approvalLevel: nextLevelName,
                customerName: customerName,
                totalAmount: totalAmount,
              ),
              notificationType: 'approval_request',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending approval notification: $e');
      }
    }
  }

  /// Get next approval level information
  Future<Map<String, dynamic>?> _getNextApprovalLevel(
    int orderLetterId,
    int currentLevelId,
  ) async {
    try {
      final orderLetterService = locator<OrderLetterService>();
      final discounts = await orderLetterService.getOrderLetterDiscounts(
        orderLetterId: orderLetterId,
      );

      // Find next pending level
      int? nextLevelId;
      String? nextLevelName;
      int? nextApproverId;
      String? nextApproverName;

      for (final discount in discounts) {
        final levelId = discount['approver_level_id'] as int?;
        final approved = discount['approved'];
        final approverId = discount['approver'] as int?;
        final approverLevel = discount['approver_level'] as String?;

        if (levelId != null &&
            levelId > currentLevelId &&
            (approved == null || approved == false)) {
          // This is a pending level higher than current
          if (nextLevelId == null || levelId < nextLevelId) {
            // Take the lowest pending level (next in sequence)
            nextLevelId = levelId;
            nextLevelName = approverLevel ?? 'Level $levelId';
            nextApproverId = approverId;
            nextApproverName = discount['approver_name'] as String?;
          }
        }
      }

      if (nextLevelId != null) {
        return {
          'level_id': nextLevelId,
          'level_name': nextLevelName ?? 'Level $nextLevelId',
          'approver_id': nextApproverId,
          'approver_name': nextApproverName,
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting next approval level: $e');
      }
      return null;
    }
  }

  /// Show local notification (for immediate feedback)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotificationService.showSimpleNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Get current FCM token
  String? getCurrentFcmToken() {
    return _currentFcmToken;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

/// Top-level function for handling background messages
/// Must be top-level or static function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }

  // Show local notification for background messages
  final localNotificationService = LocalNotificationService();
  await localNotificationService.initialize();

  if (message.notification != null) {
    await localNotificationService.showSimpleNotification(
      title: message.notification!.title ?? 'New Notification',
      body: message.notification!.body ?? '',
      payload: message.data.toString(),
    );
  }
}
