import 'package:alitapricelist/features/checkout/data/models/address_book_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddressBookContact.fromJson', () {
    test('maps ERP field names (ABALPH/ABALKY/area_id) to name/phone/areaId',
        () {
      final contact = AddressBookContact.fromJson({
        'id': 47967,
        'ABAN8': null,
        'ABALPH': 'IBU RATIH MAMA ESI',
        'ABALKY': '085736237519',
        'ABMCU': null,
        'ABUPMJ': null,
        'ABUPMT': null,
        'ROWID': null,
        'area_id': 1,
      });

      expect(contact.id, 47967);
      expect(contact.name, 'IBU RATIH MAMA ESI');
      expect(contact.phone, '085736237519');
      expect(contact.areaId, 1);
    });

    test('defaults to empty/zero on missing or null fields — never throws', () {
      final contact = AddressBookContact.fromJson({'id': null});

      expect(contact.id, 0);
      expect(contact.name, '');
      expect(contact.phone, '');
      expect(contact.areaId, 0);
    });

    test('trims whitespace from name and phone', () {
      final contact = AddressBookContact.fromJson({
        'id': 1,
        'ABALPH': '  Budi  ',
        'ABALKY': ' 08123 ',
        'area_id': 2,
      });

      expect(contact.name, 'Budi');
      expect(contact.phone, '08123');
    });

    test('equality and hashCode are id-based', () {
      const a = AddressBookContact(id: 1, name: 'A', phone: '1', areaId: 1);
      const b = AddressBookContact(id: 1, name: 'B', phone: '2', areaId: 2);
      const c = AddressBookContact(id: 2, name: 'A', phone: '1', areaId: 1);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
