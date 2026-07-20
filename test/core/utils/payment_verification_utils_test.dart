import 'package:alitapricelist/core/utils/payment_verification_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('paymentCountsTowardTotal', () {
    test('null (belum direview) dihitung', () {
      expect(paymentCountsTowardTotal(null), isTrue);
    });

    test('true dihitung', () {
      expect(paymentCountsTowardTotal(true), isTrue);
    });

    test('false (ditolak/duplikat/invalid) TIDAK dihitung', () {
      expect(paymentCountsTowardTotal(false), isFalse);
    });

    test('string "true"/"false" dari raw JSON map', () {
      expect(paymentCountsTowardTotal('true'), isTrue);
      expect(paymentCountsTowardTotal('false'), isFalse);
    });

    test('angka 0/1 dari raw JSON map', () {
      expect(paymentCountsTowardTotal(1), isTrue);
      expect(paymentCountsTowardTotal(0), isFalse);
    });

    test('string kosong/"null" diperlakukan seperti null', () {
      expect(paymentCountsTowardTotal(''), isTrue);
      expect(paymentCountsTowardTotal('null'), isTrue);
    });
  });
}
