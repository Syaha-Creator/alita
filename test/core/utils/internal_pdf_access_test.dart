import 'package:alitapricelist/core/utils/internal_pdf_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InternalPdfAccess.bypassesItemDiscountApprovalGate', () {
    test('returns true for listed user id when bypass enabled', () {
      expect(InternalPdfAccess.bypassesItemDiscountApprovalGate(5206), isTrue);
    });

    test('returns false for other users', () {
      expect(InternalPdfAccess.bypassesItemDiscountApprovalGate(1234), isFalse);
    });

    test('returns false for null and zero', () {
      expect(InternalPdfAccess.bypassesItemDiscountApprovalGate(null), isFalse);
      expect(InternalPdfAccess.bypassesItemDiscountApprovalGate(0), isFalse);
    });
  });
}
