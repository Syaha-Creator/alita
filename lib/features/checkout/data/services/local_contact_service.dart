import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and retrieves customer contacts locally using SharedPreferences.
/// Data is stored as a JSON-encoded list of customer maps.
class LocalContactService {
  static const String _key = 'saved_customers';

  static String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Saves contact with id-based overwrite semantics.
  /// - No [id]: treated as a new contact (insert with generated id).
  /// - Has [id]: overwrite full existing contact matched by id.
  static Future<void> saveContact(Map<String, dynamic> customerData) async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(_key) ?? [];
    final existingContacts = savedList
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();

    final payload = Map<String, dynamic>.from(customerData)
      ..['phone'] = (customerData['phone'] as String? ?? '').trim();
    final id = payload['id']?.toString().trim() ?? '';

    if (id.isEmpty) {
      payload['id'] = _generateId();
      existingContacts.add(payload);
    } else {
      final index = existingContacts.indexWhere(
        (contact) => (contact['id']?.toString() ?? '') == id,
      );
      if (index != -1) {
        existingContacts[index] = payload;
      } else {
        existingContacts.add(payload);
      }
    }

    final encoded = existingContacts.map(jsonEncode).toList();
    await prefs.setStringList(_key, encoded);
  }

  /// Returns all saved contacts, most recently added first.
  static Future<List<Map<String, dynamic>>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(_key) ?? [];
    final contacts = savedList
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();

    var didMigrate = false;
    for (var i = 0; i < contacts.length; i++) {
      final id = contacts[i]['id']?.toString().trim() ?? '';
      if (id.isEmpty) {
        contacts[i]['id'] = '${_generateId()}_$i';
        didMigrate = true;
      }
    }

    if (didMigrate) {
      final encoded = contacts.map(jsonEncode).toList();
      await prefs.setStringList(_key, encoded);
    }

    return contacts;
  }
}
