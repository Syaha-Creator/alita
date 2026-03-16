import '../../../../core/utils/whatsapp_helper.dart';
import '../data/cart_item.dart';
import 'order_whatsapp_message_formatter.dart';

/// Feature-specific sender for cart order messages to WhatsApp.
class CartWhatsAppOrderSender {
  CartWhatsAppOrderSender._();

  static const String defaultPhoneNumber = '6281234567890';

  static Future<bool> sendOrder({
    required List<CartItem> items,
    required double total,
    String? phoneNumber,
  }) async {
    if (items.isEmpty) return false;

    final message = OrderWhatsAppMessageFormatter.format(
      items: items,
      total: total,
    );

    return WhatsAppHelper.openChat(
      phone: phoneNumber ?? defaultPhoneNumber,
      message: message,
    );
  }
}
