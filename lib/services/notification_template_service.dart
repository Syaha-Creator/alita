import 'package:flutter/foundation.dart';

class NotificationTemplateService {
  static const String _appName = "Alita Pricelist";

  // === ORDER LETTER NOTIFICATION TEMPLATES ===

  /// Template for when order letter is created (Local notification to creator)
  static Map<String, String> orderLetterCreated({
    required String noSp,
    String? customerName,
    double? totalAmount,
  }) {
    String title = "📋 Order Letter Berhasil Dibuat";
    String body = "Nomor SP: $noSp telah dibuat";

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
    required String noSp,
    required String approvalLevel,
    String? customerName,
    double? totalAmount,
  }) {
    final displayLevel = getApprovalLevelDisplayName(approvalLevel);
    String title = "🔔 Approval Order Letter Baru";
    String body = "Nomor SP: $noSp memerlukan persetujuan Anda";
    body += "\n📊 Level: $displayLevel";

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
    required String noSp,
    required String approverName,
    required String approvalAction,
    required String approvalLevel,
    String? comment,
    String? customerName,
    double? totalAmount,
  }) {
    String emoji = approvalAction.toLowerCase() == 'approve' ? '✅' : '❌';
    String action =
        approvalAction.toLowerCase() == 'approve' ? 'Disetujui' : 'Ditolak';
    final displayLevel = getApprovalLevelDisplayName(approvalLevel);

    String title = "$emoji Order Letter $action";
    String body = "Nomor SP: $noSp telah $action oleh $approverName";
    body += "\n📊 Level: $displayLevel";

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

  /// Template for approval status update with next level pending
  static Map<String, String> approvalStatusUpdateWithNextLevel({
    required String noSp,
    required String approverName,
    required String approvedLevel,
    required String nextLevel,
    String? customerName,
    double? totalAmount,
  }) {
    final displayApprovedLevel = getApprovalLevelDisplayName(approvedLevel);
    final displayNextLevel = getApprovalLevelDisplayName(nextLevel);

    String title = "✅ Order Letter Disetujui - Menunggu Level Berikutnya";
    String body = "Nomor SP: $noSp telah disetujui oleh $approverName";
    body += "\n📊 Level: $displayApprovedLevel";

    body += "\n⏳ Sedang menunggu approval dari $displayNextLevel";

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
    required String noSp,
    String? customerName,
    double? totalAmount,
  }) {
    String title = "🎉 Order Letter Selesai";
    String body = "Nomor SP: $noSp telah mendapat semua persetujuan";

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
    String? noSp,
    String? orderId, // Keep for backward compatibility, but prefer noSp
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

    // Prefer noSp over orderId, but keep both for navigation compatibility
    final finalNoSp = noSp ?? orderId;
    if (finalNoSp != null) {
      data['no_sp'] = finalNoSp;
      data['order_id'] = finalNoSp; // Keep for navigation handler compatibility
    }
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
    final levelLower = level.toLowerCase().trim();
    switch (levelLower) {
      case 'direct leader':
        return 'Atasan Langsung';
      case 'indirect leader':
        return 'Atasan Tidak Langsung';
      case 'controller':
        return 'Controller';
      case 'analyst 1':
        return 'Analyst 1';
      case 'analyst 2':
        return 'Analyst 2';
      case 'analyst':
        return 'Analyst';
      case 'user':
        return 'User';
      default:
        // Handle partial matches for Analyst 1, Analyst 2
        if (levelLower.contains('analyst 1')) {
          return 'Analyst 1';
        }
        if (levelLower.contains('analyst 2')) {
          return 'Analyst 2';
        }
        if (levelLower.contains('direct leader')) {
          return 'Atasan Langsung';
        }
        if (levelLower.contains('indirect leader')) {
          return 'Atasan Tidak Langsung';
        }
        // Return original if contains 'level' or is already formatted
        if (levelLower.contains('level') || level.contains(' ')) {
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
      if (kDebugMode) {
        print('=== NOTIFICATION TEMPLATE: $templateType ===');
      }
      if (kDebugMode) {
        print('Title: ${template['title']}');
      }
      if (kDebugMode) {
        print('Body: ${template['body']}');
      }
      if (data != null) {
        if (kDebugMode) {
          print('Data: $data');
        }
      }
      if (kDebugMode) {
        print('=====================================');
      }
    }
  }
}
