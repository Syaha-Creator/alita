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

  /// GET diskon toko by `kode_toko` (address_number toko, query param).
  static String get storeDiscounts => '$_base/store_discounts';
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

/// Structured exception for checkout step failures.
///
/// Carries enough context (step, endpoint, status, response, payload keys)
/// so the error dialog can pinpoint *exactly* which API call failed.
class CheckoutStepException implements Exception {
  final int step;
  final String stepName;
  final String endpoint;
  final int statusCode;
  final String responseBody;
  final List<String> payloadKeys;
  final String? message;

  const CheckoutStepException({
    required this.step,
    required this.stepName,
    required this.endpoint,
    required this.statusCode,
    this.responseBody = '',
    this.payloadKeys = const [],
    this.message,
  });

  @override
  String toString() {
    final buf = StringBuffer()
      ..writeln('Step $step: $stepName')
      ..writeln('Endpoint: $endpoint')
      ..writeln('Status: $statusCode');
    if (message != null) {
      buf.writeln('Pesan: $message');
    }
    if (payloadKeys.isNotEmpty) {
      buf.writeln('Payload keys: ${payloadKeys.join(', ')}');
    }
    if (responseBody.isNotEmpty) {
      final preview = responseBody.length > 300
          ? '${responseBody.substring(0, 300)}…'
          : responseBody;
      buf.writeln('Response: $preview');
    }
    return buf.toString().trimRight();
  }
}
