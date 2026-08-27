import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/checkout/data/utils/checkout_channel_resolver.dart';
import 'package:alitapricelist/features/checkout/data/models/paper_id_payment_result.dart';

void main() {
  group('CheckoutChannelResolver', () {
    test('S1 when division 25 present', () {
      expect(
        CheckoutChannelResolver.resolve(divisions: [
          {'id': 25},
          {'id': 26},
        ]),
        CheckoutChannelResolver.channelS1,
      );
    });

    test('SO when division 24 + address_number', () {
      expect(
        CheckoutChannelResolver.resolve(
          divisions: [
            {'id': 24},
          ],
          userAddressNumber: '12345',
        ),
        CheckoutChannelResolver.channelSo,
      );
    });

    test('MM when only division 26', () {
      expect(
        CheckoutChannelResolver.resolve(divisions: [
          {'id': 26},
        ]),
        CheckoutChannelResolver.channelMm,
      );
    });

    test('usesManualCheckoutPayment only for MM', () {
      expect(
        CheckoutChannelResolver.usesManualCheckoutPayment('MM'),
        isTrue,
      );
      expect(
        CheckoutChannelResolver.usesManualCheckoutPayment(''),
        isFalse,
      );
      expect(
        CheckoutChannelResolver.usesManualCheckoutPayment('S1'),
        isFalse,
      );
    });

    test('showsCheckoutPaymentSection for MM and Direct, not SO', () {
      expect(CheckoutChannelResolver.showsCheckoutPaymentSection('MM'), isTrue);
      expect(CheckoutChannelResolver.showsCheckoutPaymentSection('S1'), isTrue);
      expect(CheckoutChannelResolver.showsCheckoutPaymentSection(''), isTrue);
      expect(CheckoutChannelResolver.showsCheckoutPaymentSection('SO'), isFalse);
    });

    test('canOptInPaperIdPayment for S1 and empty, not MM/SO', () {
      expect(CheckoutChannelResolver.canOptInPaperIdPayment('S1'), isTrue);
      expect(CheckoutChannelResolver.canOptInPaperIdPayment(''), isTrue);
      expect(CheckoutChannelResolver.canOptInPaperIdPayment('MM'), isFalse);
      expect(CheckoutChannelResolver.canOptInPaperIdPayment('SO'), isFalse);
    });

    test('usesPaperIdPayment aliases canOptInPaperIdPayment', () {
      expect(CheckoutChannelResolver.usesPaperIdPayment('S1'), isTrue);
      expect(CheckoutChannelResolver.usesPaperIdPayment(''), isTrue);
      expect(CheckoutChannelResolver.usesPaperIdPayment('MM'), isFalse);
      expect(CheckoutChannelResolver.usesPaperIdPayment('SO'), isFalse);
    });

    test('paperPaymentNumber prefixes INV/', () {
      expect(
        CheckoutChannelResolver.paperPaymentNumber('2611013G32'),
        'INV/2611013G32',
      );
    });
  });

  group('PaperIdPaymentResult', () {
    test('parses nested result from API response', () {
      final parsed = PaperIdPaymentResult.fromJson({
        'status': 'success',
        'result': {
          'id': 7301,
          'order_letter_id': 8656,
          'paper_id_status': 'UNPAID',
          'paper_id_invoice_id': 'ebd63024-ed2d-475a-88af-dc34f46eeb6e',
          'paper_id_invoice_url': 'https://stg-v2.paper.id/Vkh1ws1',
          'payment_number': 'INV/2611013G32',
        },
      });

      expect(parsed.paymentId, 7301);
      expect(parsed.orderLetterId, 8656);
      expect(parsed.paperIdStatus, 'UNPAID');
      expect(parsed.paperIdInvoiceUrl, 'https://stg-v2.paper.id/Vkh1ws1');
      expect(parsed.paymentNumber, 'INV/2611013G32');
    });
  });
}
