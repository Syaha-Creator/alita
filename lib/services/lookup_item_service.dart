import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../config/dependency_injection.dart';
import '../core/error/exceptions.dart';
import 'api_client.dart';
import 'auth_service.dart';

class LookupItem {
  final String itemNumber;
  final String? fabricType; // jenis_kain, e.g., F55
  final String? fabricColor; // warna_kain, can be null
  final String? itemDesc; // item_desc
  final String? thickness; // tebal
  final String? weight; // berat
  final String? volume; // kubikasi
  final String? type; // tipe (kasur model)
  final String? brand;
  final String? size; // ukuran
  final String? itemType; // optional context tag

  LookupItem({
    required this.itemNumber,
    this.fabricType,
    this.fabricColor,
    this.itemDesc,
    this.thickness,
    this.weight,
    this.volume,
    this.type,
    this.brand,
    this.size,
    this.itemType,
  });

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      itemNumber:
          (json['item_num'] ?? json['item_number'] ?? json['itemNumber'] ?? '')
              .toString(),
      fabricType:
          json['jenis_kain']?.toString() ?? json['fabric_type']?.toString(),
      fabricColor:
          json['warna_kain']?.toString() ?? json['fabric_color']?.toString(),
      itemDesc: json['item_desc']?.toString(),
      thickness: json['tebal']?.toString(),
      weight: json['berat']?.toString(),
      volume: json['kubikasi']?.toString(),
      type: json['tipe']?.toString(),
      brand: json['brand']?.toString(),
      size: json['ukuran']?.toString(),
    );
  }
}

class LookupItemService {
  final ApiClient _client;
  LookupItemService({ApiClient? client})
      : _client = client ?? locator<ApiClient>();

  /// Fetch available item numbers (and fabric choices) for the given variant
  /// Expected query supports fields like: brand, kasur, divan, headboard, ukuran, sorong
  Future<List<LookupItem>> fetchLookupItems({
    required String brand,
    required String kasur,
    String? divan,
    String? headboard,
    String? sorong,
    required String ukuran,
    String? contextItemType,
  }) async {
    try {
      // Build authenticated URL
      final token = await AuthService.getToken();
      if (token == null) {
        throw ServerException('Auth token not found');
      }
      final url = ApiConfig.getPlLookupItemNumsUrl(token: token);

      // Normalize and avoid sending 'Tanpa/Tidak ada' values
      bool isNone(String? v) {
        if (v == null) return true;
        final s = v.trim().toLowerCase();
        if (s.isEmpty) return true;
        return s == '-' ||
            s == 'n/a' ||
            s.contains('tanpa') ||
            s.contains('tidak ada');
      }

      // Many backends expect 'tipe' for kasur name; normalize quotes
      String normTipe = kasur.replaceAll('’', "'").trim();
      // Normalize size: remove spaces, unify separators (e.g., "120 x 200" -> "120x200")
      String normalizeSize(String value) {
        final v = value
            .replaceAll('\u00D7', 'x') // multiplication sign × -> x
            .replaceAll('X', 'x')
            .replaceAll(RegExp(r'\s*[x]\s*'), 'x')
            .replaceAll(' ', '')
            .trim()
            .toLowerCase();
        return v;
      }

      final normUkuran = normalizeSize(ukuran);
      // Parser helper
      List<LookupItem> parseItems(dynamic data) {
        List<dynamic> list = const [];
        if (data is Map) {
          if (data['data'] is List) {
            list = data['data'] as List;
          } else if (data['result'] is List) {
            list = data['result'] as List;
          }
        } else if (data is List) {
          list = data;
        }
        return list
            .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      Response response;

      // Primary: GET all then local filter by tipe + ukuran (tanpa params)
      print('[LookupItemService] GET pl_lookup_item_nums params: {}');
      response = await _client.get(url);
      var items = response.statusCode == 200
          ? parseItems(response.data)
          : <LookupItem>[];
      String k(String? s) => (s ?? '').trim().toLowerCase();
      String kSize(String? s) => normalizeSize(s ?? '');
      items = items
          .where((i) => k(i.type) == k(normTipe) && kSize(i.size) == normUkuran)
          .toList();

      // Fallback 1: tambah brand/komponen via server filter bila kosong
      if (items.isEmpty) {
        String normBrand = (brand.split(' - ').first).trim();
        final qpBrand = <String, dynamic>{
          'brand': normBrand,
          'tipe': normTipe,
          'ukuran': ukuran,
        };
        if (!isNone(divan)) qpBrand['divan'] = divan;
        if (!isNone(headboard)) qpBrand['headboard'] = headboard;
        if (!isNone(sorong)) qpBrand['sorong'] = sorong;
        print('[LookupItemService] Fallback brand params: $qpBrand');
        try {
          response = await _client.get(url, queryParameters: qpBrand);
          if (response.statusCode == 200) {
            items = parseItems(response.data);
          }
        } catch (_) {}
      }

      // Fallback 2: key alternatif 'type'
      if (items.isEmpty) {
        final qpAlt = <String, dynamic>{
          'type': normTipe,
          'ukuran': ukuran,
        };
        print('[LookupItemService] Fallback alt key params: $qpAlt');
        try {
          response = await _client.get(url, queryParameters: qpAlt);
          if (response.statusCode == 200) {
            items = parseItems(response.data);
          }
        } catch (_) {}
      }

      // Fallback 3: client-side relax size filter (match by tipe only)
      if (items.isEmpty) {
        print('[LookupItemService] Fallback tipe-only filter (client-side)');
        try {
          // Ensure we have a source list to filter from
          if (response.statusCode != 200) {
            response = await _client.get(url);
          }
          final all = parseItems(response.data);
          items = all.where((i) => k(i.type) == k(normTipe)).toList();
        } catch (_) {}
      }
      print('[LookupItemService] Response count: ${items.length}');
      if (contextItemType != null && contextItemType.isNotEmpty) {
        return items
            .map((i) => LookupItem(
                  itemNumber: i.itemNumber,
                  fabricType: i.fabricType,
                  fabricColor: i.fabricColor,
                  itemDesc: i.itemDesc,
                  thickness: i.thickness,
                  weight: i.weight,
                  volume: i.volume,
                  type: i.type,
                  brand: i.brand,
                  size: i.size,
                  itemType: contextItemType,
                ))
            .toList();
      }
      return items;
    } catch (_) {
      return [];
    }
  }
}
