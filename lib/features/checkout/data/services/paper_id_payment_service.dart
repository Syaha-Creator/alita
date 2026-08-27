import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/utils/app_telemetry.dart';
import '../../../../core/utils/log.dart';
import '../models/checkout_models.dart';
import '../models/paper_id_payment_result.dart';
import '../utils/checkout_channel_resolver.dart';

/// Creates an `order_letter_payments` row + Paper.id invoice via Alita API.
///
/// Path: [CheckoutEndpoints.orderLetterPaymentPaperId] (staging vs prod via
/// [AppConfig.appEnv] / `PAPER_PAYMENT_PATH`).
///
/// TODO(paper-retry): if order succeeds but this call fails, define a
/// dedicated "recreate Paper invoice" path with backend (avoid duplicate
/// payments / duplicate invoices).
class PaperIdPaymentService {
  PaperIdPaymentService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  String get _paperEndpointLabel =>
      '/order_letter_payment/${AppConfig.paperPaymentPath}';

  Future<PaperIdPaymentResult> createPaperPayment({
    required int orderLetterId,
    required String noSp,
    required double paymentAmount,
    required int creatorId,
    required String token,
    String note = '',
  }) async {
    final sw = Stopwatch()..start();
    final body = <String, dynamic>{
      'order_letter_id': orderLetterId,
      'payment_method': 'Paper.id',
      'payment_bank': 'Paper.id',
      'payment_number': CheckoutChannelResolver.paperPaymentNumber(noSp),
      'payment_amount': paymentAmount,
      'creator': creatorId,
      'note': note.trim().isEmpty ? 'Payment via Paper.id' : note.trim(),
    };

    final response = await _api.post(
      CheckoutEndpoints.orderLetterPaymentPaperId,
      token: token,
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      sw.stop();
      AppTelemetry.error(
        'checkout_paper_payment_failed',
        data: {
          'status_code': response.statusCode,
          'duration_ms': sw.elapsedMilliseconds,
          'order_letter_id': orderLetterId,
          'app_env': AppConfig.appEnv,
          'paper_path': AppConfig.paperPaymentPath,
        },
        tag: 'CheckoutPaper',
      );
      throw CheckoutStepException(
        step: 3,
        stepName: 'Pembayaran Paper.id',
        endpoint: _paperEndpointLabel,
        statusCode: response.statusCode,
        responseBody: response.body,
        payloadKeys: body.keys.toList(),
      );
    }

    Map<String, dynamic> decoded;
    try {
      final raw = jsonDecode(response.body);
      decoded = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
    } on Object catch (e, s) {
      Log.error(e, s, reason: 'PaperIdPaymentService.decode');
      throw CheckoutStepException(
        step: 3,
        stepName: 'Pembayaran Paper.id',
        endpoint: _paperEndpointLabel,
        statusCode: response.statusCode,
        responseBody: response.body,
        message: 'Response Paper.id tidak valid',
      );
    }

    final status = decoded['status']?.toString().toLowerCase();
    if (status != null && status.isNotEmpty && status != 'success') {
      throw CheckoutStepException(
        step: 3,
        stepName: 'Pembayaran Paper.id',
        endpoint: _paperEndpointLabel,
        statusCode: response.statusCode,
        responseBody: response.body,
        message: decoded['message']?.toString(),
      );
    }

    final result = PaperIdPaymentResult.fromJson(decoded);
    if (result.paperIdInvoiceUrl.trim().isEmpty) {
      throw CheckoutStepException(
        step: 3,
        stepName: 'Pembayaran Paper.id',
        endpoint: _paperEndpointLabel,
        statusCode: response.statusCode,
        responseBody: response.body,
        message: 'paper_id_invoice_url kosong',
      );
    }

    sw.stop();
    AppTelemetry.event(
      'checkout_paper_payment_ok',
      data: {
        'duration_ms': sw.elapsedMilliseconds,
        'order_letter_id': orderLetterId,
        'paper_status': result.paperIdStatus,
        'app_env': AppConfig.appEnv,
      },
      tag: 'CheckoutPaper',
    );
    return result;
  }
}
