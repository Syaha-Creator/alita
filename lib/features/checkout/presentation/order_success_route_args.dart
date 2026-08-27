/// Typed `extra` for `/success` (order confirmation).
class OrderSuccessRouteArgs {
  const OrderSuccessRouteArgs({
    required this.noSp,
    this.paperInvoiceUrl,
    this.expectPaperPayment = false,
    this.orderLetterId,
    this.paperPaymentAmount,
    this.paperCreatorId,
  });

  final String noSp;

  /// Non-null/non-empty when Paper.id invoice was created successfully.
  final String? paperInvoiceUrl;

  /// True for Direct (S1) checkout that should have a Paper invoice.
  final bool expectPaperPayment;

  /// Needed to recreate Paper invoice with the same inputs after soft-fail.
  final int? orderLetterId;
  final double? paperPaymentAmount;
  final int? paperCreatorId;

  /// Direct SP succeeded but Paper invoice URL is missing → show recreate CTA.
  bool get needsPaperRetry =>
      expectPaperPayment && (paperInvoiceUrl == null || paperInvoiceUrl!.trim().isEmpty);

  bool get hasPaperPay => (paperInvoiceUrl?.trim() ?? '').isNotEmpty;

  bool get canRetryPaper =>
      needsPaperRetry &&
      orderLetterId != null &&
      orderLetterId! > 0 &&
      (paperPaymentAmount ?? 0) > 0;
}
