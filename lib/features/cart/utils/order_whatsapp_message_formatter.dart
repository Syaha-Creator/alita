import '../data/cart_item.dart';
import '../../../../core/utils/app_formatters.dart';

/// Formatter for cart order message sent to WhatsApp.
class OrderWhatsAppMessageFormatter {
  OrderWhatsAppMessageFormatter._();

  static String format({
    required List<CartItem> items,
    required double total,
  }) {
    final buffer = StringBuffer()
      ..writeln('Halo Alita! 🛍️')
      ..writeln('Saya ingin memesan:')
      ..writeln();

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln(
        '${i + 1}. ${item.product.name} (x${item.quantity}) - ${_formatPrice(item.totalPrice)}',
      );
    }

    buffer
      ..writeln()
      ..writeln('─────────────────────')
      ..writeln('*Total Keseluruhan: ${_formatPrice(total)}*')
      ..writeln()
      ..writeln('Mohon info ketersediaan stoknya ya. Terima kasih! 🙏');

    return buffer.toString();
  }

  static String _formatPrice(double price) {
    return AppFormatters.currencyIdr(price);
  }
}
