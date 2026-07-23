import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/features/checkout/data/services/local_contact_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Mock FlutterSecureStorage method channel — mirrors storage_service_test.
  void mockSecureStorage([Map<String, String> store = const {}]) {
    final copy = Map<String, String>.from(store);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall call) async {
        switch (call.method) {
          case 'read':
            return copy[call.arguments['key']];
          case 'write':
            copy[call.arguments['key'] as String] =
                call.arguments['value'] as String;
            return null;
          case 'delete':
            copy.remove(call.arguments['key']);
            return null;
          case 'deleteAll':
            copy.clear();
            return null;
          default:
            return null;
        }
      },
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
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
      mockSecureStorage({
        'saved_customers': jsonEncode([
          'not-valid-json{{{',
          '"just-a-string"', // valid JSON, but not a Map
          '{"id":"1","name":"Valid Toko"}',
        ]),
      });

      final contacts = await LocalContactService.getContacts();

      expect(contacts, hasLength(1));
      expect(contacts.first['name'], 'Valid Toko');
    });

    test('saveContact overwrites existing contact matched by id', () async {
      mockSecureStorage({
        'saved_customers': jsonEncode(['{"id":"1","name":"Old Name"}']),
      });

      await LocalContactService.saveContact({'id': '1', 'name': 'New Name'});
      final contacts = await LocalContactService.getContacts();

      expect(contacts, hasLength(1));
      expect(contacts.first['name'], 'New Name');
    });

    test('migrates legacy plaintext SharedPreferences contacts once',
        () async {
      SharedPreferences.setMockInitialValues({
        'saved_customers': ['{"id":"1","name":"Legacy Toko"}'],
      });

      final contacts = await LocalContactService.getContacts();
      expect(contacts, hasLength(1));
      expect(contacts.first['name'], 'Legacy Toko');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('saved_customers'), isNull);
      expect(prefs.getBool('saved_customers_migrated_v1'), true);
    });
  });
}
