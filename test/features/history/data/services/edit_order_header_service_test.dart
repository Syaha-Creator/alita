import 'package:alitapricelist/features/history/data/services/edit_order_header_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditOrderHeaderService.buildHeaderPayload', () {
    test('includes extended_amount so grand total stays in sync with ongkir',
        () {
      // Regression: mengedit header (termasuk ongkir) sebelumnya cuma
      // mengirim `postage`, `extended_amount` di server jadi basi (stale).
      final payload = EditOrderHeaderService.buildHeaderPayload(
        customerName: 'Budi',
        phone: '0812',
        address: 'Jl. A',
        email: 'a@a.com',
        shipToName: 'Budi',
        addressShipTo: 'Jl. A',
        requestDate: '2026-07-20',
        postage: 150000,
        extendedAmount: 3150000,
      );

      expect(payload['postage'], 150000);
      expect(payload['extended_amount'], 3150000);
    });

    test('extendedAmount reflects subtotal (unchanged) + new postage', () {
      // Skenario nyata: subtotal item 3_000_000, ongkir lama 50_000 (jadi
      // extended_amount lama 3_050_000), user ubah ongkir jadi 150_000.
      const oldExtendedAmount = 3050000.0;
      const oldPostage = 50000.0;
      const newPostage = 150000.0;
      final itemsSubtotal = oldExtendedAmount - oldPostage;
      final newExtendedAmount = itemsSubtotal + newPostage;

      final payload = EditOrderHeaderService.buildHeaderPayload(
        customerName: 'Budi',
        phone: '0812',
        address: 'Jl. A',
        email: 'a@a.com',
        shipToName: 'Budi',
        addressShipTo: 'Jl. A',
        requestDate: '2026-07-20',
        postage: newPostage,
        extendedAmount: newExtendedAmount,
      );

      expect(itemsSubtotal, 3000000.0);
      expect(payload['extended_amount'], 3150000.0);
      expect(payload['postage'], newPostage);
    });
  });
}
