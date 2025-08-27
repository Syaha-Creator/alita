import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'device_token_service.dart';

class ApprovalNotificationService {
  final NotificationService _notificationService = NotificationService();
  final DeviceTokenService _deviceTokenService = DeviceTokenService();

  // Send local notification when order letter is created
  Future<void> notifyOrderLetterCreated() async {
    try {
      if (kDebugMode) {
        print('Sending order letter created notification...');
      }

      await _notificationService.testLocalNotificationWithCustomMessage(
        title: 'Surat Pesanan telah berhasil dibuat',
        body: 'Mohon tunggu untuk approval atasan yang terkait',
        payload: 'order_letter_created',
      );

      if (kDebugMode) {
        print('Order letter created notification sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending order letter created notification: $e');
      }
    }
  }

  // Send both local notification and FCM to superiors when order letter is created
  Future<bool> notifyOrderLetterCreatedWithFCM({
    required String creatorUserId,
    required String orderId,
    String? orderDetails,
  }) async {
    try {
      if (kDebugMode) {
        print('Sending order letter created notification with FCM...');
        print('Creator User ID: $creatorUserId');
        print('Order ID: $orderId');
      }

      // Step 1: Send local notification to creator
      await notifyOrderLetterCreated();

      // Step 2: Get leader user IDs (atasan)
      final leaderUserIds = await getSequentialApprovalFlow(creatorUserId);

      if (leaderUserIds.isEmpty) {
        if (kDebugMode) {
          print('No leader users found for creator: $creatorUserId');
        }
        return false;
      }

      if (kDebugMode) {
        print('Found ${leaderUserIds.length} leader users: $leaderUserIds');
      }

      // Step 3: Send FCM notifications to all leaders
      final success = await notifyAllLeadersInSequence(
        creatorUserId: creatorUserId,
        orderId: orderId,
        leaderUserIds: leaderUserIds,
        orderDetails: orderDetails,
      );

      if (kDebugMode) {
        if (success) {
          print('Order letter created notification with FCM sent successfully');
        } else {
          print('Failed to send order letter created notification with FCM');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending order letter created notification with FCM: $e');
      }
      return false;
    }
  }

  // Send FCM notification to creator when approval status changes
  Future<bool> notifyApprovalStatusUpdate({
    required String creatorUserId,
    required String approvalLevel,
    required String status,
    required String orderId,
  }) async {
    try {
      if (kDebugMode) {
        print('Sending approval status update notification to creator...');
        print('Creator User ID: $creatorUserId');
        print('Approval Level: $approvalLevel');
        print('Status: $status');
        print('Order ID: $orderId');
      }

      // Get creator's device token
      final creatorTokens =
          await _deviceTokenService.getDeviceTokens(creatorUserId);
      if (creatorTokens.isEmpty) {
        if (kDebugMode) {
          print('No device token found for creator');
        }
        return false;
      }

      // Send FCM notification
      final success = await _notificationService.sendRealFCMToDevice(
        creatorTokens.first.token,
        title: 'Status Approval Diperbarui',
        body: 'Approval level $approvalLevel telah $status',
        data: {
          'type': 'approval_status_update',
          'approval_level': approvalLevel,
          'status': status,
          'order_id': orderId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (kDebugMode) {
        if (success) {
          print('Approval status update notification sent successfully');
        } else {
          print('Failed to send approval status update notification');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending approval status update notification: $e');
      }
      return false;
    }
  }

  // Send FCM notification to next level leader
  Future<bool> notifyNextLevelApproval({
    required String nextLeaderUserId,
    required String creatorUserId,
    required String orderId,
    required String approvalLevel,
    String? orderDetails,
  }) async {
    try {
      if (kDebugMode) {
        print('Sending next level approval notification...');
        print('Next Leader User ID: $nextLeaderUserId');
        print('Creator User ID: $creatorUserId');
        print('Order ID: $orderId');
        print('Approval Level: $approvalLevel');
      }

      // Get next leader's device token
      final nextLeaderTokens =
          await _deviceTokenService.getDeviceTokens(nextLeaderUserId);
      if (nextLeaderTokens.isEmpty) {
        if (kDebugMode) {
          print('No device token found for next leader: $nextLeaderUserId');
        }
        return false;
      }

      // Send FCM notification
      final success = await _notificationService.sendRealFCMToDevice(
        nextLeaderTokens.first.token,
        title: 'Approval Baru Menunggu',
        body: 'Ada order letter yang memerlukan approval Anda',
        data: {
          'type': 'new_approval_request',
          'approval_level': approvalLevel,
          'order_id': orderId,
          'creator_id': creatorUserId,
          'order_details': orderDetails ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (kDebugMode) {
        if (success) {
          print(
              'Next level approval notification sent successfully to $nextLeaderUserId');
        } else {
          print(
              'Failed to send next level approval notification to $nextLeaderUserId');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending next level approval notification: $e');
      }
      return false;
    }
  }

  // Get sequential approval flow for a user
  Future<List<String>> getSequentialApprovalFlow(String userId) async {
    try {
      if (kDebugMode) {
        print('Getting sequential approval flow for user: $userId');
      }

      final leaderUserIds = await _deviceTokenService.getLeaderUserIds(userId);
      if (kDebugMode) {
        print('Found ${leaderUserIds.length} leader users: $leaderUserIds');
      }

      return leaderUserIds;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sequential approval flow: $e');
      }
      return [];
    }
  }

  // Send notification to all leaders in sequence
  Future<bool> notifyAllLeadersInSequence({
    required String creatorUserId,
    required String orderId,
    required List<String> leaderUserIds,
    String? orderDetails,
  }) async {
    try {
      if (kDebugMode) {
        print('Sending notifications to all leaders in sequence...');
        print('Creator User ID: $creatorUserId');
        print('Order ID: $orderId');
        print('Leader User IDs: $leaderUserIds');
      }

      bool allSuccess = true;
      for (int i = 0; i < leaderUserIds.length; i++) {
        final leaderId = leaderUserIds[i];
        final approvalLevel = _getApprovalLevelName(i);

        if (kDebugMode) {
          print('Notifying leader $leaderId at level $approvalLevel');
        }

        final success = await notifyNextLevelApproval(
          nextLeaderUserId: leaderId,
          creatorUserId: creatorUserId,
          orderId: orderId,
          approvalLevel: approvalLevel,
          orderDetails: orderDetails,
        );

        if (!success) {
          allSuccess = false;
          if (kDebugMode) {
            print('Failed to notify leader $leaderId');
          }
        }

        // Add delay between notifications
        if (i < leaderUserIds.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (kDebugMode) {
        if (allSuccess) {
          print('All leader notifications sent successfully');
        } else {
          print('Some leader notifications failed');
        }
      }

      return allSuccess;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notifications to all leaders: $e');
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
}
