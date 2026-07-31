import 'dart:convert';

import '../../../../core/services/api_client.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/safe_json_list.dart';
import '../models/address_book_contact.dart';

/// Fetches contacts from the `/address_books` endpoint (Ransack-style
/// filtering, e.g. `q[area_id_eq]`) — a server-side, shared address book,
/// used to replace the old on-device-only "saved contacts" picker.
class AddressBookService {
  static final ApiClient _api = ApiClient.instance;

  /// Calls `GET /address_books?q[area_id_eq]=[areaId]` and returns the raw
  /// list of contacts for that area. There is no server-side name/phone
  /// search parameter — callers filter client-side (see [ContactPickerBottomSheet]).
  Future<List<AddressBookContact>> fetchByArea(int areaId) async {
    final response = await _api.get(
      '/address_books',
      queryParams: {'q[area_id_eq]': areaId.toString()},
      timeout: const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return safeMapList(decoded, fieldName: 'address_books')
          .map(AddressBookContact.fromJson)
          .toList();
    }
    // Balikin pesan singkat — jangan bawa body mentah (bisa berisi PII
    // nama/telepon) ke pesan Exception yang mungkin berakhir di Crashlytics.
    throw Exception(
      'HTTP ${response.statusCode}: ${Log.previewBody(response.body)}',
    );
  }
}
