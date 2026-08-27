/// Response from `POST /order_letter_payment/{payper_id|paper_id_staging}`.
class PaperIdPaymentResult {
  const PaperIdPaymentResult({
    required this.paymentId,
    required this.orderLetterId,
    required this.paperIdStatus,
    required this.paperIdInvoiceId,
    required this.paperIdInvoiceUrl,
    this.paperIdPdfUrl,
    this.paperIdPdfUrlShort,
    this.paymentNumber,
  });

  final int paymentId;
  final int orderLetterId;
  final String paperIdStatus;
  final String paperIdInvoiceId;
  final String paperIdInvoiceUrl;
  final String? paperIdPdfUrl;
  final String? paperIdPdfUrlShort;
  final String? paymentNumber;

  factory PaperIdPaymentResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    final map = result is Map<String, dynamic>
        ? result
        : (result is Map
            ? Map<String, dynamic>.from(result)
            : <String, dynamic>{});

    return PaperIdPaymentResult(
      paymentId: _asInt(map['id']),
      orderLetterId: _asInt(map['order_letter_id']),
      paperIdStatus: map['paper_id_status']?.toString() ?? '',
      paperIdInvoiceId: map['paper_id_invoice_id']?.toString() ?? '',
      paperIdInvoiceUrl: map['paper_id_invoice_url']?.toString() ?? '',
      paperIdPdfUrl: map['paper_id_pdf_url']?.toString(),
      paperIdPdfUrlShort: map['paper_id_pdf_url_short']?.toString(),
      paymentNumber: map['payment_number']?.toString(),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
