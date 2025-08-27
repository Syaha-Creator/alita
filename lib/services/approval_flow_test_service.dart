import 'package:flutter/foundation.dart';
import '../config/dependency_injection.dart';
import 'approval_flow_notification_service.dart';
import 'auth_service.dart';

class ApprovalFlowTestService {
  final ApprovalFlowNotificationService _approvalFlowService =
      locator<ApprovalFlowNotificationService>();

  // Test approval flow with approve action
  Future<bool> testApprovalFlowApprove({
    required String orderLetterId,
    required String approverUserId,
    required String approverName,
    required String approvalLevel,
    String? comment,
  }) async {
    try {
      if (kDebugMode) {
        print('=== TESTING APPROVAL FLOW - APPROVE ===');
        print('Order Letter ID: $orderLetterId');
        print('Approver User ID: $approverUserId');
        print('Approver Name: $approverName');
        print('Approval Level: $approvalLevel');
        print('Comment: $comment');
      }

      final result = await _approvalFlowService.handleApprovalFlowNotification(
        orderLetterId: orderLetterId,
        approverUserId: approverUserId,
        approverName: approverName,
        approvalAction: 'approve',
        approvalLevel: approvalLevel,
        comment: comment,
        orderDetails: 'Test order for approval flow testing',
        customerName: 'Test Customer',
        totalAmount: 1500000.0,
      );

      if (kDebugMode) {
        print('Approval flow approve test result: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing approval flow approve: $e');
      }
      return false;
    }
  }

  // Test approval flow with reject action
  Future<bool> testApprovalFlowReject({
    required String orderLetterId,
    required String approverUserId,
    required String approverName,
    required String approvalLevel,
    String? comment,
  }) async {
    try {
      if (kDebugMode) {
        print('=== TESTING APPROVAL FLOW - REJECT ===');
        print('Order Letter ID: $orderLetterId');
        print('Approver User ID: $approverUserId');
        print('Approver Name: $approverName');
        print('Approval Level: $approvalLevel');
        print('Comment: $comment');
      }

      final result = await _approvalFlowService.handleApprovalFlowNotification(
        orderLetterId: orderLetterId,
        approverUserId: approverUserId,
        approverName: approverName,
        approvalAction: 'reject',
        approvalLevel: approvalLevel,
        comment: comment ?? 'Order ditolak karena tidak memenuhi kriteria',
        orderDetails: 'Test order for approval flow testing',
        customerName: 'Test Customer',
        totalAmount: 1500000.0,
      );

      if (kDebugMode) {
        print('Approval flow reject test result: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing approval flow reject: $e');
      }
      return false;
    }
  }

  // Test complete approval flow sequence
  Future<bool> testCompleteApprovalFlow({
    required String orderLetterId,
    required String creatorUserId,
  }) async {
    try {
      if (kDebugMode) {
        print('=== TESTING COMPLETE APPROVAL FLOW ===');
        print('Order Letter ID: $orderLetterId');
        print('Creator User ID: $creatorUserId');
      }

      bool allSuccess = true;
      final approvalLevels = [
        {
          'level': 'Direct Leader',
          'approver': 'Leader A',
          'user_id': 'leader_a_id'
        },
        {
          'level': 'Indirect Leader',
          'approver': 'Leader B',
          'user_id': 'leader_b_id'
        },
        {
          'level': 'Controller',
          'approver': 'Controller C',
          'user_id': 'controller_c_id'
        },
        {
          'level': 'Analyst',
          'approver': 'Analyst D',
          'user_id': 'analyst_d_id'
        },
      ];

      for (int i = 0; i < approvalLevels.length; i++) {
        final level = approvalLevels[i];

        if (kDebugMode) {
          print('\n--- Testing Level ${i + 1}: ${level['level']} ---');
        }

        // Test approve action
        final approveResult = await testApprovalFlowApprove(
          orderLetterId: orderLetterId,
          approverUserId: level['user_id']!,
          approverName: level['approver']!,
          approvalLevel: level['level']!,
          comment: 'Disetujui oleh ${level['approver']}',
        );

        if (!approveResult) {
          allSuccess = false;
          if (kDebugMode) {
            print('Failed to test approve for level: ${level['level']}');
          }
        }

        // Add delay between levels
        if (i < approvalLevels.length - 1) {
          if (kDebugMode) {
            print('Waiting 3 seconds before next level...');
          }
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      if (kDebugMode) {
        if (allSuccess) {
          print('\n✅ Complete approval flow test completed successfully');
        } else {
          print('\n❌ Some approval flow tests failed');
        }
      }

      return allSuccess;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing complete approval flow: $e');
      }
      return false;
    }
  }

  // Test approval flow with custom data
  Future<bool> testApprovalFlowWithCustomData({
    required String orderLetterId,
    required String approverUserId,
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
        print('=== TESTING APPROVAL FLOW WITH CUSTOM DATA ===');
        print('Order Letter ID: $orderLetterId');
        print('Approver User ID: $approverUserId');
        print('Approver Name: $approverName');
        print('Approval Action: $approvalAction');
        print('Approval Level: $approvalLevel');
        print('Comment: $comment');
        print('Order Details: $orderDetails');
        print('Customer Name: $customerName');
        print('Total Amount: $totalAmount');
      }

      final result = await _approvalFlowService.handleApprovalFlowNotification(
        orderLetterId: orderLetterId,
        approverUserId: approverUserId,
        approverName: approverName,
        approvalAction: approvalAction,
        approvalLevel: approvalLevel,
        comment: comment,
        orderDetails: orderDetails,
        customerName: customerName,
        totalAmount: totalAmount,
      );

      if (kDebugMode) {
        print('Custom approval flow test result: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing custom approval flow: $e');
      }
      return false;
    }
  }

  // Get service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final currentUserId = await AuthService.getCurrentUserId();

      return {
        'service_available': true,
        'service_name': 'ApprovalFlowNotificationService',
        'current_user_id': currentUserId?.toString() ?? 'Not logged in',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'features': [
          'Approval flow notifications',
          'Creator notifications',
          'Next level approver notifications',
          'Sequential approval handling',
        ],
      };
    } catch (e) {
      return {
        'service_available': false,
        'service_name': 'ApprovalFlowNotificationService',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    }
  }
}
