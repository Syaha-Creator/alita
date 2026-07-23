import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/log.dart';

/// Persists and retrieves customer contacts locally using secure storage
/// (encrypted keychain/keystore) — this is customer PII (name, phone,
/// address), it must not sit in plaintext SharedPreferences.
/// Data is stored as a single JSON-encoded list of customer maps.
class LocalContactService {
  static const String _key = 'saved_customers';
  static const String _migratedKey = 'saved_customers_migrated_v1';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  /// One-time migration: moves the contact list from the legacy plaintext
  /// SharedPreferences key into secure storage.
  static Future<void> _migrateLegacyIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;

    final legacyList = prefs.getStringList(_key);
    if (legacyList != null && legacyList.isNotEmpty) {
      await _writeRawList(legacyList);
      await prefs.remove(_key);
    }
    await prefs.setBool(_migratedKey, true);
  }

  static Future<List<String>> _readRawList() async {
    await _migrateLegacyIfNeeded();
    try {
      final raw = await _secureStorage.read(key: _key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<String>().toList();
    } catch (e, st) {
      Log.error(e, st,
          reason: 'LocalContactService: read secure storage failed');
      return [];
    }
  }

  static Future<void> _writeRawList(List<String> list) async {
    try {
      await _secureStorage.write(key: _key, value: jsonEncode(list));
    } catch (e, st) {
      Log.error(e, st,
          reason: 'LocalContactService: write secure storage failed');
    }
  }

  /// Decodes stored JSON strings into contact maps, skipping any entry that
  /// is corrupt JSON or not a Map — a single bad row (e.g. from a future
  /// schema change) must not crash saved-customer load/save entirely.
  static List<Map<String, dynamic>> _decodeContacts(List<String> savedList) {
    final contacts = <Map<String, dynamic>>[];
    for (final item in savedList) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is! Map) {
          Log.warning(
            'LocalContactService: skip non-Map saved contact',
            tag: 'LocalContactService',
          );
          continue;
        }
        contacts.add(Map<String, dynamic>.from(decoded));
      } catch (e, st) {
        Log.error(e, st, reason: 'LocalContactService: corrupt saved contact');
      }
    }
    return contacts;
  }

  /// Saves contact with id-based overwrite semantics.
  /// - No [id]: treated as a new contact (insert with generated id).
  /// - Has [id]: overwrite full existing contact matched by id.
  static Future<void> saveContact(Map<String, dynamic> customerData) async {
    final savedList = await _readRawList();
    final existingContacts = _decodeContacts(savedList);

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
    await _writeRawList(encoded);
  }

  /// Returns all saved contacts, most recently added first.
  static Future<List<Map<String, dynamic>>> getContacts() async {
    final savedList = await _readRawList();
    final contacts = _decodeContacts(savedList);

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
      await _writeRawList(encoded);
    }

    return contacts;
  }
}
