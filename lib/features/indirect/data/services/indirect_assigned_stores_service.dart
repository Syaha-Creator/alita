import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/log.dart';
import '../models/assigned_store.dart';

/// Fetch daftar toko assign (indirect) dari host terpisah.
class IndirectAssignedStoresService {
  IndirectAssignedStoresService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Uri _storeListUri(String salesCode) {
    final base = AppConfig.indirectStoresBaseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base/address_number/address_number_by_sales_code')
        .replace(queryParameters: {'sales_code': salesCode});
  }

  Future<List<AssignedStore>> fetchBySalesCode(String salesCode) async {
    if (!AppConfig.isIndirectStoresConfigured) {
      Log.warning(
        'Indirect stores: INDIRECT_STORES_BASE_URL / keys belum diisi',
        tag: 'IndirectStores',
      );
      return [];
    }
    if (salesCode.isEmpty) return [];

    final url = _storeListUri(salesCode);
    final response = await _client.get(
      url,
      headers: {
        'Accept': 'application/json',
        'x-api-key': AppConfig.indirectApiKey,
        'x-client-key': AppConfig.indirectClientKey,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memuat toko assign (${response.statusCode})',
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Response toko assign tidak valid');
    }
    if (!_isTruthyStatus(data['status'])) {
      throw Exception('Response toko assign tidak valid');
    }

    final result = data['result'];
    if (result is! List) return [];

    return _parseStoreRows(result);
  }

  /// API kadang mengirim `true`, `1`, atau `"true"`.
  static bool _isTruthyStatus(dynamic v) {
    if (v == true) return true;
    if (v == 1) return true;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  /// Normalisasi tipe JSON (angka sebagai string, null) agar [AssignedStore.fromJson] tidak gagal.
  static List<AssignedStore> _parseStoreRows(List<dynamic> result) {
    final out = <AssignedStore>[];
    for (final item in result) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      try {
        _normalizeStoreRow(m);
        out.add(AssignedStore.fromJson(m));
      } catch (e) {
        Log.warning(
          'Baris toko assign dilewati: $e',
          tag: 'IndirectStores',
        );
      }
    }
    out.sort((a, b) =>
        a.alphaName.toLowerCase().compareTo(b.alphaName.toLowerCase()));
    return out;
  }

  static void _normalizeStoreRow(Map<String, dynamic> m) {
    final an = m['address_number'];
    if (an != null && an is! num) {
      final p = int.tryParse(an.toString().trim());
      if (p != null) {
        m['address_number'] = p;
      }
    }
    final pn = m['parent_number'];
    if (pn != null && pn is! num) {
      final p = int.tryParse(pn.toString().trim());
      m['parent_number'] = p;
    }
    m['alpha_name'] = m['alpha_name']?.toString() ?? '';
    m['address'] = m['address']?.toString() ?? '';
    if (m['catcode_27'] != null) {
      m['catcode_27'] = m['catcode_27'].toString();
    }
  }
}
