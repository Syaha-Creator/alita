import 'package:url_launcher/url_launcher.dart';

/// Service untuk mengirim pesan WhatsApp ke nomor predefined.
class WhatsAppService {
  static const String _phoneNumber = '+62 852-1867-5494';

  /// Mengirim pesan WhatsApp dengan brand, area, dan channel.
  static Future<void> sendMessage({
    required String brand,
    required String area,
    required String channel,
  }) async {
    final message = _buildMessage(brand: brand, area: area, channel: channel);
    final url = _buildWhatsAppUrl(message);

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      throw Exception('Failed to open WhatsApp: $e');
    }
  }

  /// Membuat isi pesan WhatsApp.
  static String _buildMessage({
    required String brand,
    required String area,
    required String channel,
  }) {
    return 'Halo Pak Arik, saya ingin menanyakan tentang Pricelist brand $brand pada area $area dan channel $channel yang tidak tersedia. Mohon informasi lebih lanjut.';
  }

  /// Membuat URL WhatsApp dengan nomor dan pesan.
  static String _buildWhatsAppUrl(String message) {
    final encodedMessage = Uri.encodeComponent(message);
    final cleanPhoneNumber = _phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return 'https://wa.me/ $cleanPhoneNumber?text=$encodedMessage';
  }
}
