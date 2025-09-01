import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'device_token_service.dart';
import 'notification_template_service.dart';
import 'auth_service.dart';

/// Unified Notification Service - Handles ALL notification scenarios consistently
/// This service replaces the need for multiple separate notification services
class UnifiedNotificationService {
  late final NotificationService _notificationService;
  late final DeviceTokenService _deviceTokenService;

  UnifiedNotificationService() {
    _notificationService = NotificationService();
    _deviceTokenService = DeviceTokenService();
  }

  // ===== ORDER LETTER CREATION NOTIFICATIONS =====

  /// Handle complete order letter creation notification flow
  /// 1. Local notification to creator
  /// 2. FCM notification ONLY to Direct Leader (first level)
  Future<bool> handleOrderLetterCreation({
    required String creatorUserId,
    required String orderId,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 UNIFIED: Starting order letter creation notification flow');
        print('📋 Order ID: $orderId');
        print('👤 Creator: $creatorUserId');
      }

      // Step 1: Send local notification to creator
      final localSuccess = await _sendLocalNotificationToCreator(
        orderId: orderId,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      if (!localSuccess) {
        if (kDebugMode) {
          print('❌ UNIFIED: Failed to send local notification to creator');
        }
        return false;
      }

      // Step 2: Send FCM notification ONLY to Direct Leader (first level)
      final fcmSuccess = await _sendInitialFCMToDirectLeader(
        creatorUserId: creatorUserId,
        orderId: orderId,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      if (kDebugMode) {
        if (fcmSuccess) {
          print(
              '✅ UNIFIED: Order letter creation notification flow completed successfully');
          print('📱 Local notification: ✅ Sent to creator');
          print('📲 FCM notification: ✅ Sent to Direct Leader (first level)');
          print(
              '⏳ Waiting for Direct Leader approval before notifying next level...');
        } else {
          print(
              '⚠️ UNIFIED: Order letter creation notification flow partially completed');
          print('📱 Local notification: ✅ Sent to creator');
          print('📲 FCM notification: ❌ Failed to send to Direct Leader');
        }
      }

      return localSuccess; // Return true if at least local notification was sent
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ UNIFIED: Error in order letter creation notification flow: $e');
      }
      return false;
    }
  }

  // ===== APPROVAL FLOW NOTIFICATIONS =====

  /// Handle complete approval flow notification
  /// 1. Notify creator about approval status
  /// 2. If approved, notify next level approver (sequential)
  Future<bool> handleApprovalFlow({
    required String orderLetterId,
    required String approverUserId,
    required String approverName,
    required String approvalAction, // 'approve' or 'reject'
    required String approvalLevel,
    String? comment,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 UNIFIED: Starting approval flow notification');
        print('📋 Order ID: $orderLetterId');
        print('👤 Approver: $approverName (ID: $approverUserId)');
        print('✅ Action: $approvalAction');
        print('📊 Level: $approvalLevel');
      }

      // Step 1: Get creator user ID
      final creatorUserId = await _getCreatorUserId(orderLetterId);
      if (creatorUserId == null) {
        if (kDebugMode) {
          print(
              '❌ UNIFIED: Could not find creator user ID for order letter: $orderLetterId');
        }
        return false;
      }

      // Step 2: Notify creator about approval status
      final creatorNotificationSuccess = await _notifyCreatorAboutApproval(
        creatorUserId: creatorUserId,
        orderLetterId: orderLetterId,
        approverName: approverName,
        approvalAction: approvalAction,
        approvalLevel: approvalLevel,
        comment: comment,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      // Step 3: If approved, check if there's next level approver
      bool nextLevelNotificationSuccess = false;
      if (approvalAction.toLowerCase() == 'approve') {
        nextLevelNotificationSuccess = await _notifyNextLevelApprover(
          creatorUserId: creatorUserId,
          orderLetterId: orderLetterId,
          currentApprovalLevel: approvalLevel,
          customerName: customerName,
          totalAmount: totalAmount,
        );
      }

      if (kDebugMode) {
        print('✅ UNIFIED: Approval flow notification completed');
        print(
            '📱 Creator notification: ${creatorNotificationSuccess ? "✅ Sent" : "❌ Failed"}');
        if (approvalAction.toLowerCase() == 'approve') {
          print(
              '📲 Next level notification: ${nextLevelNotificationSuccess ? "✅ Sent" : "❌ Failed"}');
        }
      }

      return creatorNotificationSuccess; // Return true if creator was notified
    } catch (e) {
      if (kDebugMode) {
        print('❌ UNIFIED: Error in approval flow notification: $e');
      }
      return false;
    }
  }

  // ===== PRIVATE HELPER METHODS =====

  /// Send local notification to creator
  Future<bool> _sendLocalNotificationToCreator({
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
        print('✅ UNIFIED: Local notification sent to creator successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UNIFIED: Error sending local notification to creator: $e');
      }
      return false;
    }
  }

  /// Send FCM notification ONLY to Direct Leader (first level)
  Future<bool> _sendInitialFCMToDirectLeader({
    required String creatorUserId,
    required String orderId,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      // Get all leader user IDs for the creator
      final leaderUserIds =
          await _deviceTokenService.getLeaderUserIds(creatorUserId);

      if (leaderUserIds.isEmpty) {
        if (kDebugMode) {
          print(
              '❌ UNIFIED: No leader user IDs found for creator: $creatorUserId');
        }
        return false;
      }

      if (kDebugMode) {
        print(
            '📋 UNIFIED: Found ${leaderUserIds.length} total approval levels:');
        for (int i = 0; i < leaderUserIds.length; i++) {
          print(
              '   Level $i: ${_getApprovalLevelName(i)} (User ID: ${leaderUserIds[i]})');
        }
      }

      // ONLY send notification to the FIRST level leader (Direct Leader)
      final firstLeaderUserId = leaderUserIds.first;
      final approvalLevel = _getApprovalLevelName(0); // Level 0 = Direct Leader

      if (kDebugMode) {
        print(
            '🚀 UNIFIED: Sending initial notification ONLY to first level leader: $firstLeaderUserId at level $approvalLevel');
        print(
            '⏳ UNIFIED: Other leaders (${leaderUserIds.length - 1}) will be notified after approvals');
        print(
            '📋 UNIFIED: Sequential flow: Direct Leader → Indirect Leader → Controller → Analyst');
      }

      // Get leader's device token
      final leaderTokens =
          await _deviceTokenService.getDeviceTokens(firstLeaderUserId);
      if (leaderTokens.isEmpty) {
        if (kDebugMode) {
          print(
              '❌ UNIFIED: No device token found for leader: $firstLeaderUserId');
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
      );

      // Log template for debugging
      NotificationTemplateService.logNotificationTemplate(
        templateType: 'NEW_APPROVAL_REQUEST_INITIAL',
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
          print(
              '✅ UNIFIED: Initial FCM notification sent successfully to Direct Leader: $firstLeaderUserId');
          print(
              '⏳ UNIFIED: Waiting for approval before notifying next level...');
        } else {
          print(
              '❌ UNIFIED: Failed to send initial FCM notification to Direct Leader: $firstLeaderUserId');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ UNIFIED: Error sending initial FCM notification to Direct Leader: $e');
      }
      return false;
    }
  }

  /// Get creator user ID from order letter
  Future<String?> _getCreatorUserId(String orderLetterId) async {
    try {
      // This would typically come from your order letter data
      // For now, we'll use the current user ID as a fallback
      // In production, you should get this from the order letter data
      final currentUserId = await AuthService.getCurrentUserId();
      return currentUserId?.toString();
    } catch (e) {
      if (kDebugMode) {
        print('❌ UNIFIED: Error getting creator user ID: $e');
      }
      return null;
    }
  }

  /// Notify creator about approval status
  Future<bool> _notifyCreatorAboutApproval({
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
      if (kDebugMode) {
        print('📤 UNIFIED: Notifying creator about approval status...');
        print('👤 Creator User ID: $creatorUserId');
        print('📋 Order ID: $orderLetterId');
        print('✅ Approval Action: $approvalAction');
        print('📊 Approval Level: $approvalLevel');
      }

      // Get creator's device token
      final creatorTokens =
          await _deviceTokenService.getDeviceTokens(creatorUserId);
      if (creatorTokens.isEmpty) {
        if (kDebugMode) {
          print('❌ UNIFIED: No device token found for creator: $creatorUserId');
        }
        return false;
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
          print('✅ UNIFIED: Creator notification sent successfully');
        } else {
          print('❌ UNIFIED: Failed to send creator notification');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UNIFIED: Error notifying creator about approval: $e');
      }
      return false;
    }
  }

  /// Notify next level approver (sequential flow)
  Future<bool> _notifyNextLevelApprover({
    required String creatorUserId,
    required String orderLetterId,
    required String currentApprovalLevel,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 UNIFIED: Checking for next level approver...');
        print('📊 UNIFIED: Current approval level: $currentApprovalLevel');
      }

      // Get all leader user IDs
      final leaderUserIds =
          await _deviceTokenService.getLeaderUserIds(creatorUserId);
      if (leaderUserIds.isEmpty) {
        if (kDebugMode) {
          print('❌ UNIFIED: No leader users found for creator: $creatorUserId');
        }
        return false;
      }

      if (kDebugMode) {
        print(
            '📋 UNIFIED: Found ${leaderUserIds.length} total approval levels:');
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
              '❌ UNIFIED: Could not determine current approval level index for: $currentApprovalLevel');
        }
        return false;
      }

      // Check if there's a next level
      final nextLevelIndex = currentLevelIndex + 1;
      if (nextLevelIndex >= leaderUserIds.length) {
        if (kDebugMode) {
          print('🎉 UNIFIED: No next level approver - FINAL APPROVAL REACHED!');
          print('✅ UNIFIED: Order letter has been approved by all levels');
        }
        return false;
      }

      final nextLevelUserId = leaderUserIds[nextLevelIndex];
      final nextLevelName = _getApprovalLevelName(nextLevelIndex);

      if (kDebugMode) {
        print('🚀 UNIFIED: Moving to next approval level:');
        print('   Current: Level $currentLevelIndex - $currentApprovalLevel');
        print(
            '   Next: Level $nextLevelIndex - $nextLevelName (User ID: $nextLevelUserId)');
        print(
            '📋 UNIFIED: Sequential flow: Direct Leader → Indirect Leader → Controller → Analyst');
      }

      // Send notification to next level approver
      final success = await _notifyNextLevelApproverDirect(
        nextLevelUserId: nextLevelUserId,
        creatorUserId: creatorUserId,
        orderLetterId: orderLetterId,
        approvalLevel: nextLevelName,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UNIFIED: Error checking next level approver: $e');
      }
      return false;
    }
  }

  /// Send notification directly to next level approver
  Future<bool> _notifyNextLevelApproverDirect({
    required String nextLevelUserId,
    required String creatorUserId,
    required String orderLetterId,
    required String approvalLevel,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print(
            '📤 UNIFIED: Sending notification to next level approver: $nextLevelUserId');
        print('📱 UNIFIED: Attempting to get device token...');
      }

      // Get next level approver's device token
      final nextLevelTokens =
          await _deviceTokenService.getDeviceTokens(nextLevelUserId);
      if (nextLevelTokens.isEmpty) {
        if (kDebugMode) {
          print(
              '❌ UNIFIED: No device token found for next level approver: $nextLevelUserId');
          print('⚠️ UNIFIED: Sequential approval flow will be interrupted');
        }
        return false;
      }

      if (kDebugMode) {
        print(
            '✅ UNIFIED: Device token found for next level approver: $nextLevelUserId');
        print(
            '📲 UNIFIED: Token: ${nextLevelTokens.first.token.substring(0, 20)}...');
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
          print(
              '✅ UNIFIED: Next level approver notification sent successfully!');
          print('📋 UNIFIED: Sequential approval flow continues...');
          print(
              '⏳ UNIFIED: Waiting for approval from: $approvalLevel (User ID: $nextLevelUserId)');
        } else {
          print(
              '❌ UNIFIED: Failed to send notification to next level approver');
          print(
              '⚠️ UNIFIED: Sequential approval flow interrupted at level: $approvalLevel');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ UNIFIED: Error sending notification to next level approver: $e');
      }
      return false;
    }
  }

  // ===== UTILITY METHODS =====

  /// Get approval level name by index
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
        return 'Level $index';
    }
  }

  /// Get approval level index by name
  int _getApprovalLevelIndex(String levelName) {
    final lowerLevelName = levelName.toLowerCase();

    if (lowerLevelName.contains('direct')) return 0;
    if (lowerLevelName.contains('indirect')) return 1;
    if (lowerLevelName.contains('controller')) return 2;
    if (lowerLevelName.contains('analyst')) return 3;

    // Try to extract level number from "Level X" format
    if (lowerLevelName.contains('level')) {
      final regex = RegExp(r'level\s*(\d+)', caseSensitive: false);
      final match = regex.firstMatch(levelName);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }

    return -1; // Unknown level
  }

  // ===== TEST METHODS =====

  /// Test the unified notification service
  Future<bool> testService() async {
    try {
      if (kDebugMode) {
        print('🧪 UNIFIED: Testing unified notification service...');
      }

      // Test with dummy data
      final result = await handleOrderLetterCreation(
        creatorUserId: 'test_user_123',
        orderId: 'test_order_456',
        customerName: 'Test Customer',
        totalAmount: 1500000.0,
      );

      if (kDebugMode) {
        print('🧪 UNIFIED: Test result: ${result ? "✅ Success" : "❌ Failed"}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UNIFIED: Test failed with error: $e');
      }
      return false;
    }
  }

  /// Get service status and information
  Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      return {
        'service_name': 'UnifiedNotificationService',
        'status': 'active',
        'features': [
          'Order Letter Creation Notifications',
          'Approval Flow Notifications',
          'Sequential Approval Flow',
          'Standardized Templates',
          'Local + FCM Notifications',
        ],
        'template_service': 'NotificationTemplateService',
        'notification_service': 'NotificationService',
        'device_token_service': 'DeviceTokenService',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'service_name': 'UnifiedNotificationService',
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
