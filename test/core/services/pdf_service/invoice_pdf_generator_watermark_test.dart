import 'package:alitapricelist/core/services/pdf_service/invoice_pdf_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoicePdfGenerator.resolveWatermarkSpec', () {
    test('not all approved yet → waiting approval, regardless of payments',
        () {
      final spec = InvoicePdfGenerator.resolveWatermarkSpec(
        [
          {'approved': true},
          {'approved': false},
        ],
        [
          {'payment_amount': 1000000, 'verified': true},
        ],
        1000000,
      );

      expect(spec.assetPath, 'assets/images/approval.png');
    });

    test(
      'regression: fully approved but NOT paid must NOT show PAID stamp',
      () {
        final spec = InvoicePdfGenerator.resolveWatermarkSpec(
          [
            {'approved': true},
            {'approved': true},
          ],
          [],
          1000000,
        );

        expect(spec.assetPath, isNot('assets/images/paid.png'));
        expect(spec.assetPath, 'assets/images/approve.png');
      },
    );

    test('approved + payment pending verification → waiting verification',
        () {
      final spec = InvoicePdfGenerator.resolveWatermarkSpec(
        [
          {'approved': true},
        ],
        [
          {'payment_amount': 1000000, 'verified': null},
        ],
        1000000,
      );

      expect(spec.assetPath, 'assets/images/verification.png');
    });

    test('approved + fully paid & verified → paid stamp', () {
      final spec = InvoicePdfGenerator.resolveWatermarkSpec(
        [
          {'approved': true},
        ],
        [
          {'payment_amount': 1000000, 'verified': true},
        ],
        1000000,
      );

      expect(spec.assetPath, 'assets/images/paid.png');
    });

    test('approved + partially paid & verified → dp stamp', () {
      final spec = InvoicePdfGenerator.resolveWatermarkSpec(
        [
          {'approved': true},
        ],
        [
          {'payment_amount': 300000, 'verified': true},
        ],
        1000000,
      );

      expect(spec.assetPath, 'assets/images/dp.png');
    });

    test(
      'approved + all payments rejected (verified:false) → unpaid stamp',
      () {
        final spec = InvoicePdfGenerator.resolveWatermarkSpec(
          [
            {'approved': true},
          ],
          [
            {'payment_amount': 1000000, 'verified': false},
          ],
          1000000,
        );

        expect(spec.assetPath, 'assets/images/unpaid.png');
      },
    );
  });
}
