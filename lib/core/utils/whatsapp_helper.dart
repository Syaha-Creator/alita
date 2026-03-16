import 'package:url_launcher/url_launcher.dart';

/// Generic WhatsApp helper for URL building and chat launching.
class WhatsAppHelper {
  /// Open WhatsApp chat directly to a phone number.
  static Future<bool> openChatByPhone(String phone) async =>
      openChat(phone: phone);

  /// Open WhatsApp chat with optional pre-filled message text.
  static Future<bool> openChat({
    required String phone,
    String? message,
  }) async {
    final uri = buildChatUri(phone: phone, message: message);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Build wa.me URI with normalized Indonesian phone format.
  static Uri buildChatUri({
    required String phone,
    String? message,
  }) {
    final normalizedPhone = normalizePhone(phone);
    return Uri.https(
      'wa.me',
      '/$normalizedPhone',
      message != null && message.trim().isNotEmpty ? {'text': message} : null,
    );
  }

  /// Normalize local phone to international format accepted by wa.me.
  static String normalizePhone(String phone) {
    String formatted = phone.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (formatted.startsWith('0')) {
      formatted = '62${formatted.substring(1)}';
    } else if (formatted.startsWith('+62')) {
      formatted = formatted.replaceFirst('+', '');
    }
    return formatted;
  }

  /// Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Should start with country code and have at least 10 digits
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }
}
