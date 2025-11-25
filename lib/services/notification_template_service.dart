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
    String title = "📋 Surat Pesanan Berhasil Dikirim!";

    String body = "";

    // Customer section
    if (customerName != null && customerName.isNotEmpty) {
      body += "👤 Customer: $customerName";
    } else {
      body += "👤 Customer: -";
    }

    // Nomor SP section
    body += "\n📄 Nomor SP: $noSp";

    // Status section
    body += "\n📊 Status:";
    body += "\n⏳ Sedang Menunggu Approval Atasan";

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
    String? creatorName,
    double? totalAmount,
  }) {
    String title = "🔔 Surat Pesanan butuh Approval";

    String body = "";

    // Customer section
    if (customerName != null && customerName.isNotEmpty) {
      body += "👤 Customer: $customerName";
    } else {
      body += "👤 Customer: -";
    }

    // Nomor SP section
    body += "\n📄 Nomor SP: $noSp";

    // Nama SC (Creator) section
    if (creatorName != null && creatorName.isNotEmpty) {
      body += "\n👨‍💼 Nama SC: $creatorName";
    } else {
      body += "\n👨‍💼 Nama SC: -";
    }

    // Status section
    body += "\n\n📊 Status:";
    body += "\n⏳ Menunggu Approval Anda..";
    body += "\n📱 Silahkan membuka aplikasi";

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

    return {
      'title': title,
      'body': body,
    };
  }

  /// Template for approval status update with next level pending
  /// approvalHistory: List of approved levels with format: {'level': 'Direct Leader', 'approverName': 'Muhammad Zen'}
  static Map<String, String> approvalStatusUpdateWithNextLevel({
    required String noSp,
    required String approverName,
    required String approvedLevel,
    required String nextLevel,
    List<Map<String, String>>? approvalHistory,
    String? nextApproverName,
    String? customerName,
    double? totalAmount,
  }) {
    final displayNextLevel = getApprovalLevelDisplayName(nextLevel);
    final displayNextApproverName = nextApproverName ?? displayNextLevel;

    String title =
        "✅ Surat Pesanan Disetujui - Menunggu Approval Selanjutnya...";

    String body = "";

    // Customer section
    if (customerName != null && customerName.isNotEmpty) {
      body += "👤 Customer: $customerName";
    } else {
      body += "👤 Customer: -";
    }

    // Nomor SP section
    body += "\n📄 Nomor SP: $noSp";

    // Status section with approval history
    body += "\n📊 Status:";

    // Show all approved levels (history)
    if (approvalHistory != null && approvalHistory.isNotEmpty) {
      for (final approval in approvalHistory) {
        final levelName = approval['level'] ?? '';
        final approver = approval['approverName'] ?? '';
        if (levelName.isNotEmpty && approver.isNotEmpty) {
          final displayLevel = getApprovalLevelDisplayName(levelName);
          body += "\n✅ Telah disetujui oleh $displayLevel ($approver)";
        }
      }
    } else {
      // Fallback: show only the current approval
      final displayApprovedLevel = getApprovalLevelDisplayName(approvedLevel);
      body += "\n✅ Telah disetujui oleh $displayApprovedLevel ($approverName)";
    }

    // Show next pending approval
    if (displayNextApproverName.isNotEmpty &&
        displayNextApproverName != displayNextLevel) {
      body +=
          "\n⏳ Sedang Menunggu Approval dari $displayNextLevel ($displayNextApproverName)";
    } else {
      body += "\n⏳ Sedang Menunggu Approval dari $displayNextLevel";
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
    String title = "🎉 Surat Pesanan Sudah Siap!";

    String body = "";

    // Customer section
    if (customerName != null && customerName.isNotEmpty) {
      body += "👤 Customer: $customerName";
    } else {
      body += "👤 Customer: -";
    }

    // Nomor SP section
    body += "\n📄 Nomor SP: $noSp";

    // Status section
    body += "\n📊 Status:";
    body += "\n✅ Approval Lengkap";
    body += "\n📦 Silahkan diproses lebih lanjut";

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
      case 'analyst':
        return 'Analyst';
      case 'analyst 1':
        return 'Controller'; // Backward compatibility: map Analyst 1 to Controller
      case 'analyst 2':
        return 'Analyst'; // Backward compatibility: map Analyst 2 to Analyst
      case 'user':
        return 'User';
      default:
        // Handle partial matches for backward compatibility
        if (levelLower.contains('analyst 1')) {
          return 'Controller'; // Backward compatibility
        }
        if (levelLower.contains('analyst 2')) {
          return 'Analyst'; // Backward compatibility
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
