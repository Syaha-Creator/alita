/// Centralised configuration for checkout / payment flows.
abstract final class CheckoutConfig {
  /// Payment method → available bank/channel options.
  static const Map<String, List<String>> paymentChannelsMap = {
    'Transfer Bank': [
      'BCA',
      'Mandiri',
      'BNI',
      'BRI',
      'CIMB Niaga',
      'Permata',
      'BSI',
      'Bank Jago',
    ],
    'Kartu Kredit': ['BCA Card', 'Visa', 'Mastercard', 'JCB', 'Amex'],
    'E-Wallet': ['GoPay', 'OVO', 'Dana', 'ShopeePay', 'LinkAja'],
    'QRIS': ['QRIS BCA', 'QRIS Mandiri', 'QRIS BNI', 'QRIS BRI', 'QRIS Nobu'],
    'PayLater': [
      'Kredivo',
      'Shopee PayLater',
      'GoPay Later',
      'Indodana',
      'Akulaku',
      'Home Credit',
      'BCA Paylater',
    ],
    'Lainnya': [],
  };

  static List<String> get paymentMethods => paymentChannelsMap.keys.toList();
}
