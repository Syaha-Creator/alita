import '../../../../core/config/app_config.dart';

/// Public endpoint constants for the checkout flow.
class CheckoutEndpoints {
  CheckoutEndpoints._();

  static String get _base => AppConfig.apiBaseUrl;

  static String get attendanceList => '$_base/attendance_list';
  static String get orderLetters => '$_base/order_letters';
  static String get orderLetterContacts => '$_base/order_letter_contacts';
  static String get orderLetterPayments => '$_base/order_letter_payments';
  static String get orderLetterDetails => '$_base/order_letter_details';
  static String get orderLetterDiscounts => '$_base/order_letter_discounts';
  static String get leaderByUser => '$_base/leaderbyuser';
}

/// A single pending detail row (used for retry flow).
class PendingDetail {
  final Map<String, dynamic> payload;
  final List<Map<String, dynamic>> discounts;
  final String label;

  const PendingDetail({
    required this.payload,
    required this.discounts,
    required this.label,
  });
}

/// A detail that was successfully POSTed, paired with its backend ID.
class SucceededDetail {
  final PendingDetail pending;
  final int detailId;

  const SucceededDetail({required this.pending, required this.detailId});
}

/// Result from createOrderLetter.
class CreateOrderResult {
  final int orderLetterId;
  final String noSp;

  const CreateOrderResult({
    required this.orderLetterId,
    required this.noSp,
  });
}
