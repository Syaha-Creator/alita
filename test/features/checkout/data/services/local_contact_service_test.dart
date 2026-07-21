import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/features/checkout/data/services/local_contact_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalContactService', () {
    test('saveContact then getContacts round-trips normally', () async {
      await LocalContactService.saveContact({
        'name': 'Toko A',
        'phone': ' 08123 ',
      });

      final contacts = await LocalContactService.getContacts();
      expect(contacts, hasLength(1));
      expect(contacts.first['name'], 'Toko A');
      expect(contacts.first['phone'], '08123');
      expect(contacts.first['id'], isNotEmpty);
    });

    test('getContacts skips corrupt JSON entries without throwing', () async {
      SharedPreferences.setMockInitialValues({
        'saved_customers': [
          'not-valid-json{{{',
          '"just-a-string"', // valid JSON, but not a Map
          '{"id":"1","name":"Valid Toko"}',
        ],
      });

      final contacts = await LocalContactService.getContacts();

      expect(contacts, hasLength(1));
      expect(contacts.first['name'], 'Valid Toko');
    });

    test('saveContact overwrites existing contact matched by id', () async {
      SharedPreferences.setMockInitialValues({
        'saved_customers': ['{"id":"1","name":"Old Name"}'],
      });

      await LocalContactService.saveContact({'id': '1', 'name': 'New Name'});
      final contacts = await LocalContactService.getContacts();

      expect(contacts, hasLength(1));
      expect(contacts.first['name'], 'New Name');
    });
  });
}
