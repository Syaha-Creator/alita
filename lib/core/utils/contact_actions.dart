import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_feedback.dart';
import 'platform_utils.dart';
import 'whatsapp_helper.dart';

/// Reusable actions for contact interactions.
class ContactActions {
  ContactActions._();

  static Future<void> copyText(
    BuildContext context, {
    required String text,
    required String successMessage,
    Duration duration = const Duration(seconds: 2),
  }) async {
    hapticTap();
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      AppFeedback.plain(context, successMessage, duration: duration);
    }
  }

  static Future<bool> openWhatsAppChat(
    String phone, {
    String? message,
  }) async {
    hapticTap();
    return WhatsAppHelper.openChat(phone: phone, message: message);
  }

  /// Initiate a phone call via the system dialer.
  static Future<bool> callPhone(String phone) async {
    hapticTap();
    final normalized = phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri(scheme: 'tel', path: normalized);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
