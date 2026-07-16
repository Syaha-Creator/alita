/// Centralised configuration for checkout / payment flows.
abstract final class CheckoutConfig {
  /// Metode pembayaran → opsi bank/channel.
  static const Map<String, List<String>> paymentChannelsMap = {
    'Debit / QRIS': [
      'BCA',
      'Mandiri',
      'BNI',
      'BRI',
      'CIMB Niaga',
      'BSI',
      'Mega',
      'Danamon',
      'Permata',
      'Lainnya',
    ],
    'CC Full Payment': [
      'EDC BCA',
      'Blibli',
    ],
    'CC Cicilan': [
      'EDC BCA',
      'Blibli',
    ],
    'Leasing': [
      'HCI',
      'Kredit Plus',
      'BAF',
      'Spektra',
      'Lainnya',
    ],
    'PayLater': [
      'Kredivo',
      'Shopee PayLater',
      'Indodana',
      'Akulaku',
      'BCA Paylater',
    ],
    'Lainnya': [],
  };

  static List<String> get paymentMethods => paymentChannelsMap.keys.toList();

  /// Input teks bebas untuk channel: metode [Lainnya] atau sub-channel [Lainnya].
  static bool usesCustomChannelText(String? method, String? channel) =>
      method == 'Lainnya' || channel == 'Lainnya';

  /// Nilai `payment_bank` yang dikirim ke API.
  static String resolvePaymentBank({
    required String? method,
    required String? bank,
    required String otherChannelText,
  }) {
    if (usesCustomChannelText(method, bank)) {
      final custom = otherChannelText.trim();
      if (custom.isNotEmpty) return custom;
    }
    return bank ?? '';
  }

  /// Nilai `payment_method` yang dikirim ke API.
  static String resolvePaymentMethod(String? method) =>
      method == 'Lainnya' ? 'other' : (method ?? '');
}
