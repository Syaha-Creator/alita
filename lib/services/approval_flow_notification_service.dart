import 'package:flutter/foundation.dart';
import 'device_token_service.dart';
import 'notification_service.dart';
import 'auth_service.dart';
import 'notification_template_service.dart';

class ApprovalFlowNotificationService {
  late final DeviceTokenService _deviceTokenService;
  late final NotificationService _notificationService;

  ApprovalFlowNotificationService() {
    // Initialize services without circular dependency
    _deviceTokenService = DeviceTokenService();
    _notificationService = NotificationService();
  }

  // Handle approval flow notifications
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
        print('=== APPROVAL FLOW NOTIFICATION SERVICE ===');
        print('Handling approval flow notification...');
        print('Order Letter ID: $orderLetterId');
        print('Approver User ID: $approverUserId');
        print('Approver Name: $approverName');
        print('Approval Action: $approvalAction');
        print('Approval Level: $approvalLevel');
      }

      // Step 1: Get creator user ID from order letter
      final creatorUserId = await _getCreatorUserId(orderLetterId);
      if (creatorUserId == null) {
        if (kDebugMode) {
          print(
              'Could not find creator user ID for order letter: $orderLetterId');
        }
        return false;
      }

      if (kDebugMode) {
        print('Creator User ID: $creatorUserId');
      }

      // Step 2: Send notification to creator about approval status
      await _notifyCreatorAboutApproval(
        creatorUserId: creatorUserId,
        orderLetterId: orderLetterId,
        approverName: approverName,
        approvalAction: approvalAction,
        approvalLevel: approvalLevel,
        comment: comment,
        orderDetails: orderDetails,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Step 3: If approved, check if there's next level approver
      if (approvalAction.toLowerCase() == 'approve') {
        final hasNextLevel = await _notifyNextLevelApprover(
          creatorUserId: creatorUserId,
          orderLetterId: orderLetterId,
          currentApprovalLevel: approvalLevel,
          orderDetails: orderDetails,
          customerName: customerName,
          totalAmount: totalAmount,
        );

        if (kDebugMode) {
          if (hasNextLevel) {
            print('Next level approver notified successfully');
          } else {
            print('No next level approver or final approval reached');
          }
        }
      }

      if (kDebugMode) {
        print('Approval flow notification completed successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in approval flow notification: $e');
      }
      return false;
    }
  }

  // Get creator user ID from order letter
  Future<String?> _getCreatorUserId(String orderLetterId) async {
    try {
      // This would typically come from your order letter data
      // For now, we'll use the current user ID as a fallback
      final currentUserId = await AuthService.getCurrentUserId();
      return currentUserId?.toString();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting creator user ID: $e');
      }
      return null;
    }
  }

  // Notify creator about approval status
  Future<void> _notifyCreatorAboutApproval({
    required String creatorUserId,
    required String orderLetterId,
    required String approverName,
    required String approvalAction,
    required String approvalLevel,
    String? comment,
    String? orderDetails,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('Notifying creator about approval status...');
      }

      // Get creator's device token
      final creatorTokens =
          await _deviceTokenService.getDeviceTokens(creatorUserId);
      if (creatorTokens.isEmpty) {
        if (kDebugMode) {
          print('No device token found for creator: $creatorUserId');
        }
        return;
      }

      // Use standardized notification template
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

      // Generate standardized notification data
      final notificationData =
          NotificationTemplateService.generateNotificationData(
        type: 'approval_status_update',
        orderId: orderLetterId,
        approvalLevel: approvalLevel,
        approvalAction: approvalAction,
        customerName: customerName,
        totalAmount: totalAmount,
        comment: comment,
        additionalData: {
          'approver_name': approverName,
        },
      );

      // Log template for debugging
      NotificationTemplateService.logNotificationTemplate(
        templateType: 'APPROVAL_STATUS_UPDATE',
        template: template,
        data: notificationData,
      );

      // Send FCM notification to creator
      final success = await _notificationService.sendRealFCMToDevice(
        creatorTokens.first.token,
        title: template['title']!,
        body: template['body']!,
        data: notificationData,
      );

      if (kDebugMode) {
        if (success) {
          print('Creator notification sent successfully');
        } else {
          print('Failed to send creator notification');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error notifying creator: $e');
      }
    }
  }

  // Notify next level approver (if exists)
  Future<bool> _notifyNextLevelApprover({
    required String creatorUserId,
    required String orderLetterId,
    required String currentApprovalLevel,
    String? orderDetails,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Checking for next level approver...');
        print('📊 Current approval level: $currentApprovalLevel');
      }

      // Get all leader user IDs
      final leaderUserIds =
          await _deviceTokenService.getLeaderUserIds(creatorUserId);
      if (leaderUserIds.isEmpty) {
        if (kDebugMode) {
          print('❌ No leader users found for creator: $creatorUserId');
        }
        return false;
      }

      if (kDebugMode) {
        print('📋 Found ${leaderUserIds.length} total approval levels:');
        for (int i = 0; i < leaderUserIds.length; i++) {
          print(
              '   Level $i: ${_getApprovalLevelName(i)} (User ID: ${leaderUserIds[i]})');
        }
      }

      // Find current approval level index
      final currentLevelIndex = _getApprovalLevelIndex(currentApprovalLevel);
      if (currentLevelIndex == -1) {
        if (kDebugMode) {
          print(
              '❌ Could not determine current approval level index for: $currentApprovalLevel');
        }
        return false;
      }

      // Check if there's a next level
      final nextLevelIndex = currentLevelIndex + 1;
      if (nextLevelIndex >= leaderUserIds.length) {
        if (kDebugMode) {
          print('🎉 No next level approver - FINAL APPROVAL REACHED!');
          print('✅ Order letter has been approved by all levels');
        }
        return false;
      }

      final nextLevelUserId = leaderUserIds[nextLevelIndex];
      final nextLevelName = _getApprovalLevelName(nextLevelIndex);

      if (kDebugMode) {
        print('🚀 Moving to next approval level:');
        print('   Current: Level $currentLevelIndex - $currentApprovalLevel');
        print(
            '   Next: Level $nextLevelIndex - $nextLevelName (User ID: $nextLevelUserId)');
        print(
            '📋 Sequential flow: Direct Leader → Indirect Leader → Controller → Analyst');
      }

      // Send notification to next level approver
      final success = await _notifyNextLevelApproverDirect(
        nextLevelUserId: nextLevelUserId,
        creatorUserId: creatorUserId,
        orderLetterId: orderLetterId,
        approvalLevel: nextLevelName,
        orderDetails: orderDetails,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking next level approver: $e');
      }
      return false;
    }
  }

  // Send notification directly to next level approver
  Future<bool> _notifyNextLevelApproverDirect({
    required String nextLevelUserId,
    required String creatorUserId,
    required String orderLetterId,
    required String approvalLevel,
    String? orderDetails,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print(
            '📤 Sending notification to next level approver: $nextLevelUserId');
        print('📱 Attempting to get device token...');
      }

      // Get next level approver's device token
      final nextLevelTokens =
          await _deviceTokenService.getDeviceTokens(nextLevelUserId);
      if (nextLevelTokens.isEmpty) {
        if (kDebugMode) {
          print(
              '❌ No device token found for next level approver: $nextLevelUserId');
          print('⚠️ Sequential approval flow will be interrupted');
        }
        return false;
      }

      if (kDebugMode) {
        print('✅ Device token found for next level approver: $nextLevelUserId');
        print('📲 Token: ${nextLevelTokens.first.token.substring(0, 20)}...');
      }

      // Use standardized notification template
      final template = NotificationTemplateService.newApprovalRequest(
        orderId: orderLetterId,
        approvalLevel: NotificationTemplateService.getApprovalLevelDisplayName(
            approvalLevel),
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Generate standardized notification data
      final notificationData =
          NotificationTemplateService.generateNotificationData(
        type: 'new_order_letter_approval',
        orderId: orderLetterId,
        approvalLevel: approvalLevel,
        creatorUserId: creatorUserId,
        customerName: customerName,
        totalAmount: totalAmount,
        orderDetails: orderDetails,
      );

      // Log template for debugging
      NotificationTemplateService.logNotificationTemplate(
        templateType: 'NEW_APPROVAL_REQUEST_NEXT_LEVEL',
        template: template,
        data: notificationData,
      );

      // Send FCM notification
      final success = await _notificationService.sendRealFCMToDevice(
        nextLevelTokens.first.token,
        title: template['title']!,
        body: template['body']!,
        data: notificationData,
      );

      if (kDebugMode) {
        if (success) {
          print('✅ Next level approver notification sent successfully!');
          print('📋 Sequential approval flow continues...');
          print(
              '⏳ Waiting for approval from: $approvalLevel (User ID: $nextLevelUserId)');
        } else {
          print('❌ Failed to send notification to next level approver');
          print(
              '⚠️ Sequential approval flow interrupted at level: $approvalLevel');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending next level approver notification: $e');
      }
      return false;
    }
  }

  // Get approval level index from level name
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
        // Try to extract number from level name
        if (levelName.toLowerCase().contains('level')) {
          final regex = RegExp(r'level\s*(\d+)', caseSensitive: false);
          final match = regex.firstMatch(levelName);
          if (match != null) {
            return int.parse(match.group(1)!) - 1;
          }
        }
        return -1;
    }
  }

  // Get approval level name from index
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

  // Test method for approval flow
  Future<bool> testApprovalFlow({
    required String orderLetterId,
    required String approverUserId,
    required String approverName,
    required String approvalAction,
    required String approvalLevel,
    String? comment,
  }) async {
    try {
      if (kDebugMode) {
        print('Testing approval flow notification...');
      }

      final result = await handleApprovalFlowNotification(
        orderLetterId: orderLetterId,
        approverUserId: approverUserId,
        approverName: approverName,
        approvalAction: approvalAction,
        approvalLevel: approvalLevel,
        comment: comment,
        orderDetails: 'Test order for approval flow',
        customerName: 'Test Customer',
        totalAmount: 1000000.0,
      );

      if (kDebugMode) {
        print('Approval flow test result: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing approval flow: $e');
      }
      return false;
    }
  }
}
