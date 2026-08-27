import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/checkout/presentation/order_success_route_args.dart';

void main() {
  group('OrderSuccessRouteArgs', () {
    test('needsPaperRetry when expect Paper but URL empty', () {
      const args = OrderSuccessRouteArgs(
        noSp: '261101ABCD',
        expectPaperPayment: true,
        orderLetterId: 11866,
        paperPaymentAmount: 1500000,
        paperCreatorId: 42,
      );
      expect(args.needsPaperRetry, isTrue);
      expect(args.hasPaperPay, isFalse);
      expect(args.canRetryPaper, isTrue);
    });

    test('needsPaperRetry false when URL present', () {
      const args = OrderSuccessRouteArgs(
        noSp: '261101ABCD',
        paperInvoiceUrl: 'https://paper.id/invoice/1',
        expectPaperPayment: true,
        orderLetterId: 1,
        paperPaymentAmount: 100,
        paperCreatorId: 1,
      );
      expect(args.needsPaperRetry, isFalse);
      expect(args.hasPaperPay, isTrue);
      expect(args.canRetryPaper, isFalse);
    });

    test('needsPaperRetry false for MM (no Paper expected)', () {
      const args = OrderSuccessRouteArgs(noSp: '261101MM01');
      expect(args.needsPaperRetry, isFalse);
      expect(args.canRetryPaper, isFalse);
    });

    test('canRetryPaper false when orderLetterId missing', () {
      const args = OrderSuccessRouteArgs(
        noSp: '261101ABCD',
        expectPaperPayment: true,
        paperPaymentAmount: 100,
        paperCreatorId: 1,
      );
      expect(args.needsPaperRetry, isTrue);
      expect(args.canRetryPaper, isFalse);
    });
  });
}
