import 'package:flutter/foundation.dart';
import '../config/dependency_injection.dart';
import 'order_letter_notification_service.dart';
import 'auth_service.dart';

class NotificationTestService {
  final OrderLetterNotificationService _notificationService =
      locator<OrderLetterNotificationService>();

  // Test notification service dengan data dummy
  Future<bool> testNotificationService() async {
    try {
      if (kDebugMode) {
        print('=== TESTING NOTIFICATION SERVICE ===');
      }

      // Get current user ID
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) {
        if (kDebugMode) {
          print('No current user ID found');
        }
        return false;
      }

      if (kDebugMode) {
        print('Current User ID: $currentUserId');
      }

      // Test notification
      final result = await _notificationService.testNotificationService(
        creatorUserId: currentUserId.toString(),
        orderId: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
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

  // Test notification dengan data spesifik
  Future<bool> testNotificationWithCustomData({
    required String orderId,
    String? customerName,
    double? totalAmount,
  }) async {
    try {
      if (kDebugMode) {
        print('=== TESTING CUSTOM NOTIFICATION ===');
        print('Order ID: $orderId');
        print('Customer Name: $customerName');
        print('Total Amount: $totalAmount');
      }

      // Get current user ID
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) {
        if (kDebugMode) {
          print('No current user ID found');
        }
        return false;
      }

      // Send notification
      final result = await _notificationService.notifyOrderLetterCreated(
        creatorUserId: currentUserId.toString(),
        orderId: orderId,
        orderDetails: 'Test order for notification testing',
        customerName: customerName ?? 'Test Customer',
        totalAmount: totalAmount ?? 1000000.0,
      );

      if (kDebugMode) {
        print('Custom notification result: $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing custom notification: $e');
      }
      return false;
    }
  }

  // Test multiple notifications
  Future<bool> testMultipleNotifications() async {
    try {
      if (kDebugMode) {
        print('=== TESTING MULTIPLE NOTIFICATIONS ===');
      }

      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) {
        if (kDebugMode) {
          print('No current user ID found');
        }
        return false;
      }

      bool allSuccess = true;
      final testOrders = [
        {'id': 'TEST-001', 'customer': 'Customer A', 'amount': 500000.0},
        {'id': 'TEST-002', 'customer': 'Customer B', 'amount': 750000.0},
        {'id': 'TEST-003', 'customer': 'Customer C', 'amount': 1200000.0},
      ];

      for (final order in testOrders) {
        if (kDebugMode) {
          print('Testing order: ${order['id']}');
        }

        final result = await _notificationService.notifyOrderLetterCreated(
          creatorUserId: currentUserId.toString(),
          orderId: order['id'] as String,
          orderDetails: 'Test order ${order['id']}',
          customerName: order['customer'] as String?,
          totalAmount: order['amount'] as double?,
        );

        if (!result) {
          allSuccess = false;
          if (kDebugMode) {
            print('Failed to send notification for ${order['id']}');
          }
        }

        // Add delay between tests
        await Future.delayed(const Duration(seconds: 2));
      }

      if (kDebugMode) {
        if (allSuccess) {
          print('All test notifications sent successfully');
        } else {
          print('Some test notifications failed');
        }
      }

      return allSuccess;
    } catch (e) {
      if (kDebugMode) {
        print('Error testing multiple notifications: $e');
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
        'current_user_id': currentUserId?.toString() ?? 'Not logged in',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    } catch (e) {
      return {
        'service_available': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    }
  }
}
