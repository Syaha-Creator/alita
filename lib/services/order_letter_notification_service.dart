import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'device_token_service.dart';
import 'notification_template_service.dart';

class OrderLetterNotificationService {
  late final NotificationService _notificationService;
  late final DeviceTokenService _deviceTokenService;

  OrderLetterNotificationService() {
    // Initialize services without circular dependency
    _notificationService = NotificationService();
    _deviceTokenService = DeviceTokenService();
  }

  // Send notification when order letter is created
  Future<bool> notifyOrderLetterCreated({
    required String creatorUserId,
    required String orderId,
    String? orderDetails,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('=== ORDER LETTER NOTIFICATION SERVICE ===');
        print('Sending order letter created notification...');
        print('Creator User ID: $creatorUserId');
        print('Order ID: $orderId');
        print('Order Details: $orderDetails');
        print('Customer Name: $customerName');
        print('Total Amount: $totalAmount');
      }

      // Step 1: Send local notification to creator
      await _sendLocalNotificationToCreator(
        orderId: orderId,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Step 2: Get leader user IDs (atasan)
      final leaderUserIds =
          await _deviceTokenService.getLeaderUserIds(creatorUserId);

      if (leaderUserIds.isEmpty) {
        if (kDebugMode) {
          print('No leader users found for creator: $creatorUserId');
        }
        // Still return true since local notification was sent
        return true;
      }

      if (kDebugMode) {
        print('Found ${leaderUserIds.length} leader users: $leaderUserIds');
      }

      // Step 3: Send FCM notifications to all leaders
      final fcmSuccess = await _sendFCMNotificationsToLeaders(
        creatorUserId: creatorUserId,
        orderId: orderId,
        leaderUserIds: leaderUserIds,
        orderDetails: orderDetails,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      if (kDebugMode) {
        if (fcmSuccess) {
          print('Order letter notification completed successfully');
          print('- Local notification: ✅ Sent to creator');
          print('- FCM notification: ✅ Sent to Direct Leader (first level)');
          print(
              '📋 Next steps: Direct Leader must approve → Indirect Leader notified → Controller → Analyst');
        } else {
          print('Order letter notification partially completed');
          print('- Local notification: ✅ Sent to creator');
          print('- FCM notification: ❌ Failed to send to Direct Leader');
          print(
              '📋 Sequential flow will not start until Direct Leader is notified');
        }
      }

      return true; // Return true since local notification was sent successfully
    } catch (e) {
      if (kDebugMode) {
        print('Error in order letter notification service: $e');
      }
      return false;
    }
  }

  // Send local notification to creator
  Future<void> _sendLocalNotificationToCreator({
    required String orderId,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      // Use standardized notification template
      final template = NotificationTemplateService.orderLetterCreated(
        orderId: orderId,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Log template for debugging
      NotificationTemplateService.logNotificationTemplate(
        templateType: 'ORDER_LETTER_CREATED',
        template: template,
      );

      await _notificationService.testLocalNotificationWithCustomMessage(
        title: template['title']!,
        body: template['body']!,
        payload: 'order_letter_created_$orderId',
      );

      if (kDebugMode) {
        print('Local notification sent to creator successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending local notification to creator: $e');
      }
    }
  }

  // Send FCM notification ONLY to the first level leader (Direct Leader)
  // Other levels will be notified sequentially after each approval
  Future<bool> _sendFCMNotificationsToLeaders({
    required String creatorUserId,
    required String orderId,
    required List<String> leaderUserIds,
    String? orderDetails,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (leaderUserIds.isEmpty) {
        if (kDebugMode) {
          print('No leader user IDs found for creator: $creatorUserId');
        }
        return false;
      }

      if (kDebugMode) {
        print(
            'Found ${leaderUserIds.length} leaders for creator: $creatorUserId');
        print('Leader IDs: $leaderUserIds');
      }

      // ONLY send notification to the FIRST level leader (Direct Leader)
      // Other levels will be notified sequentially after each approval
      final firstLeaderUserId = leaderUserIds.first;
      final approvalLevel = _getApprovalLevelName(0); // Level 0 = Direct Leader

      if (kDebugMode) {
        print(
            '🚀 Sending initial notification ONLY to first level leader: $firstLeaderUserId at level $approvalLevel');
        print(
            '⏳ Other leaders (${leaderUserIds.length - 1}) will be notified after approvals');
        print(
            '📋 Sequential flow: Direct Leader → Indirect Leader → Controller → Analyst');
      }

      final success = await _sendFCMNotificationToLeader(
        leaderUserId: firstLeaderUserId,
        creatorUserId: creatorUserId,
        orderId: orderId,
        approvalLevel: approvalLevel,
        orderDetails: orderDetails,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      if (kDebugMode) {
        if (success) {
          print(
              '✅ Initial FCM notification sent successfully to Direct Leader: $firstLeaderUserId');
          print('⏳ Waiting for approval before notifying next level...');
        } else {
          print(
              '❌ Failed to send initial FCM notification to Direct Leader: $firstLeaderUserId');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending initial FCM notification to Direct Leader: $e');
      }
      return false;
    }
  }

  // Send FCM notification to specific leader
  Future<bool> _sendFCMNotificationToLeader({
    required String leaderUserId,
    required String creatorUserId,
    required String orderId,
    required String approvalLevel,
    String? orderDetails,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('Sending FCM to leader: $leaderUserId');
      }

      // Get leader's device token
      final leaderTokens =
          await _deviceTokenService.getDeviceTokens(leaderUserId);
      if (leaderTokens.isEmpty) {
        if (kDebugMode) {
          print('No device token found for leader: $leaderUserId');
        }
        return false;
      }

      // Use standardized notification template
      final template = NotificationTemplateService.newApprovalRequest(
        orderId: orderId,
        approvalLevel: NotificationTemplateService.getApprovalLevelDisplayName(
            approvalLevel),
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Generate standardized notification data
      final notificationData =
          NotificationTemplateService.generateNotificationData(
        type: 'new_order_letter_approval',
        orderId: orderId,
        approvalLevel: approvalLevel,
        creatorUserId: creatorUserId,
        customerName: customerName,
        totalAmount: totalAmount,
        orderDetails: orderDetails,
      );

      // Log template for debugging
      NotificationTemplateService.logNotificationTemplate(
        templateType: 'NEW_APPROVAL_REQUEST',
        template: template,
        data: notificationData,
      );

      // Send FCM notification
      final success = await _notificationService.sendRealFCMToDevice(
        leaderTokens.first.token,
        title: template['title']!,
        body: template['body']!,
        data: notificationData,
      );

      if (kDebugMode) {
        if (success) {
          print('FCM notification sent successfully to leader $leaderUserId');
        } else {
          print('Failed to send FCM notification to leader $leaderUserId');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM notification to leader $leaderUserId: $e');
      }
      return false;
    }
  }

  // Helper method to get approval level name
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

  // Test method to verify the service is working
  Future<bool> testNotificationService({
    required String creatorUserId,
    required String orderId,
  }) async {
    try {
      if (kDebugMode) {
        print('Testing order letter notification service...');
      }

      final result = await notifyOrderLetterCreated(
        creatorUserId: creatorUserId,
        orderId: orderId,
        orderDetails: 'Test order for notification service',
        customerName: 'Test Customer',
        totalAmount: 1000000.0,
      );

      if (kDebugMode) {
        print('Test result: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing notification service: $e');
      }
      return false;
    }
  }
}
