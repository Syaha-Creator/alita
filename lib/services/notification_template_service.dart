import 'package:flutter/foundation.dart';

class NotificationTemplateService {
  static const String _appName = "Alita Pricelist";

  // === ORDER LETTER NOTIFICATION TEMPLATES ===

  /// Template for when order letter is created (Local notification to creator)
  static Map<String, String> orderLetterCreated({
    required String orderId,
    String? customerName,
    double? totalAmount,
  }) {
    String title = "📋 Order Letter Berhasil Dibuat";
    String body = "Order #$orderId telah dibuat";

    if (customerName != null && customerName.isNotEmpty) {
      body += " untuk $customerName";
    }

    if (totalAmount != null) {
      body += "\n💰 Total: ${_formatCurrency(totalAmount)}";
    }

    body += "\n⏳ Menunggu approval atasan";

    return {
      'title': title,
      'body': body,
    };
  }

  /// Template for new approval request to leader (FCM to approver)
  static Map<String, String> newApprovalRequest({
    required String orderId,
    required String approvalLevel,
    String? customerName,
    double? totalAmount,
  }) {
    String title = "🔔 Approval Order Letter Baru";
    String body = "Order #$orderId memerlukan persetujuan Anda";
    body += "\n📊 Level: $approvalLevel";

    if (customerName != null && customerName.isNotEmpty) {
      body += "\n👤 Customer: $customerName";
    }

    if (totalAmount != null) {
      body += "\n💰 Total: ${_formatCurrency(totalAmount)}";
    }

    body += "\n⚡ Silakan buka aplikasi untuk review";

    return {
      'title': title,
      'body': body,
    };
  }

  // === APPROVAL STATUS NOTIFICATION TEMPLATES ===

  /// Template for approval status update to creator (FCM to creator)
  static Map<String, String> approvalStatusUpdate({
    required String orderId,
    required String approverName,
    required String approvalAction, // 'approve' or 'reject'
    required String approvalLevel,
    String? comment,
    String? customerName,
    double? totalAmount,
  }) {
    String emoji = approvalAction.toLowerCase() == 'approve' ? '✅' : '❌';
    String action =
        approvalAction.toLowerCase() == 'approve' ? 'Disetujui' : 'Ditolak';

    String title = "$emoji Order Letter $action";
    String body = "Order #$orderId telah $action oleh $approverName";
    body += "\n📊 Level: $approvalLevel";

    if (comment != null && comment.isNotEmpty) {
      body += "\n💬 Komentar: $comment";
    }

    if (customerName != null && customerName.isNotEmpty) {
      body += "\n👤 Customer: $customerName";
    }

    if (totalAmount != null) {
      body += "\n💰 Total: ${_formatCurrency(totalAmount)}";
    }

    return {
      'title': title,
      'body': body,
    };
  }

  /// Template for final approval completion
  static Map<String, String> finalApprovalCompleted({
    required String orderId,
    String? customerName,
    double? totalAmount,
  }) {
    String title = "🎉 Order Letter Selesai";
    String body = "Order #$orderId telah mendapat semua persetujuan";

    if (customerName != null && customerName.isNotEmpty) {
      body += "\n👤 Customer: $customerName";
    }

    if (totalAmount != null) {
      body += "\n💰 Total: ${_formatCurrency(totalAmount)}";
    }

    body += "\n📦 Siap untuk diproses lebih lanjut";

    return {
      'title': title,
      'body': body,
    };
  }

  // === TEST NOTIFICATION TEMPLATES ===

  /// Template for test notifications
  static Map<String, String> testNotification({
    required String testType,
    String? additionalInfo,
  }) {
    String title = "🧪 Test Notification - $testType";
    String body = "Ini adalah test notifikasi untuk $_appName";

    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      body += "\n📝 Info: $additionalInfo";
    }

    body += "\n✅ Test berhasil dijalankan";

    return {
      'title': title,
      'body': body,
    };
  }

  // === ERROR NOTIFICATION TEMPLATES ===

  /// Template for error notifications
  static Map<String, String> errorNotification({
    required String errorType,
    String? errorMessage,
  }) {
    String title = "⚠️ Error - $errorType";
    String body = "Terjadi kesalahan dalam sistem $_appName";

    if (errorMessage != null && errorMessage.isNotEmpty) {
      body += "\n❌ Error: $errorMessage";
    }

    body += "\n🔄 Silakan coba lagi atau hubungi support";

    return {
      'title': title,
      'body': body,
    };
  }

  // === UTILITY METHODS ===

  /// Format currency to Indonesian Rupiah
  static String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      double millions = amount / 1000000;
      if (millions == millions.floor()) {
        return "Rp ${millions.toInt()}jt";
      } else {
        return "Rp ${millions.toStringAsFixed(1)}jt";
      }
    } else if (amount >= 1000) {
      double thousands = amount / 1000;
      if (thousands == thousands.floor()) {
        return "Rp ${thousands.toInt()}rb";
      } else {
        return "Rp ${thousands.toStringAsFixed(1)}rb";
      }
    } else {
      return "Rp ${amount.toStringAsFixed(0)}";
    }
  }

  /// Generate notification data payload
  static Map<String, dynamic> generateNotificationData({
    required String type,
    String? orderId,
    String? approvalLevel,
    String? approverUserId,
    String? creatorUserId,
    String? approvalAction,
    String? comment,
    String? customerName,
    double? totalAmount,
    String? orderDetails,
    Map<String, dynamic>? additionalData,
  }) {
    Map<String, dynamic> data = {
      'type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'app_name': _appName,
    };

    // Add optional fields if provided
    if (orderId != null) data['order_id'] = orderId;
    if (approvalLevel != null) data['approval_level'] = approvalLevel;
    if (approverUserId != null) data['approver_user_id'] = approverUserId;
    if (creatorUserId != null) data['creator_user_id'] = creatorUserId;
    if (approvalAction != null) data['approval_action'] = approvalAction;
    if (comment != null) data['comment'] = comment;
    if (customerName != null) data['customer_name'] = customerName;
    if (totalAmount != null) data['total_amount'] = totalAmount.toString();
    if (orderDetails != null) data['order_details'] = orderDetails;

    // Add additional data if provided
    if (additionalData != null) {
      data.addAll(additionalData);
    }

    return data;
  }

  /// Get approval level display name
  static String getApprovalLevelDisplayName(String level) {
    switch (level.toLowerCase()) {
      case 'direct leader':
        return 'Atasan Langsung';
      case 'indirect leader':
        return 'Atasan Tidak Langsung';
      case 'controller':
        return 'Controller';
      case 'analyst':
        return 'Analyst';
      default:
        if (level.toLowerCase().contains('level')) {
          return level;
        }
        return 'Level $level';
    }
  }

  /// Log notification template (for debugging)
  static void logNotificationTemplate({
    required String templateType,
    required Map<String, String> template,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      print('=== NOTIFICATION TEMPLATE: $templateType ===');
      print('Title: ${template['title']}');
      print('Body: ${template['body']}');
      if (data != null) {
        print('Data: $data');
      }
      print('=====================================');
    }
  }
}
