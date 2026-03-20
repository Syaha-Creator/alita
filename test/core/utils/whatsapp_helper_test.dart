import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/whatsapp_helper.dart';

void main() {
  group('WhatsAppHelper.normalizePhone', () {
    test('converts 0-prefix to 62-prefix', () {
      expect(WhatsAppHelper.normalizePhone('081234567890'), '6281234567890');
    });

    test('strips + from +62 prefix', () {
      expect(WhatsAppHelper.normalizePhone('+6281234567890'), '6281234567890');
    });

    test('keeps raw 62 prefix unchanged', () {
      expect(WhatsAppHelper.normalizePhone('6281234567890'), '6281234567890');
    });

    test('removes spaces and dashes', () {
      expect(WhatsAppHelper.normalizePhone('0812 3456-7890'), '6281234567890');
    });

    test('trims whitespace', () {
      expect(WhatsAppHelper.normalizePhone('  081234567890  '), '6281234567890');
    });

    test('handles non-Indonesian number', () {
      expect(WhatsAppHelper.normalizePhone('6591234567'), '6591234567');
    });
  });

  group('WhatsAppHelper.buildChatUri', () {
    test('builds URI without message', () {
      final uri = WhatsAppHelper.buildChatUri(phone: '081234567890');
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/6281234567890');
      expect(uri.queryParameters, isEmpty);
    });

    test('builds URI with message', () {
      final uri = WhatsAppHelper.buildChatUri(
        phone: '081234567890',
        message: 'Hello!',
      );
      expect(uri.queryParameters['text'], 'Hello!');
    });

    test('ignores empty message', () {
      final uri = WhatsAppHelper.buildChatUri(
        phone: '081234567890',
        message: '   ',
      );
      expect(uri.queryParameters, isEmpty);
    });

    test('ignores null message', () {
      final uri = WhatsAppHelper.buildChatUri(
        phone: '081234567890',
        message: null,
      );
      expect(uri.queryParameters, isEmpty);
    });
  });

  group('WhatsAppHelper.isValidPhoneNumber', () {
    test('valid 10 digits', () {
      expect(WhatsAppHelper.isValidPhoneNumber('0812345678'), isTrue);
    });

    test('valid 13 digits with prefix', () {
      expect(WhatsAppHelper.isValidPhoneNumber('+6281234567890'), isTrue);
    });

    test('valid 15 digits', () {
      expect(WhatsAppHelper.isValidPhoneNumber('628123456789012'), isTrue);
    });

    test('invalid less than 10 digits', () {
      expect(WhatsAppHelper.isValidPhoneNumber('08123'), isFalse);
    });

    test('invalid more than 15 digits', () {
      expect(WhatsAppHelper.isValidPhoneNumber('6281234567890123'), isFalse);
    });

    test('strips non-digit chars before counting', () {
      expect(WhatsAppHelper.isValidPhoneNumber('+62 812-345-6789'), isTrue);
    });

    test('empty string is invalid', () {
      expect(WhatsAppHelper.isValidPhoneNumber(''), isFalse);
    });
  });
}
