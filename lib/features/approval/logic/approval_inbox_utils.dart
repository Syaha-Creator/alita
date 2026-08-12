import 'package:geocoding/geocoding.dart';

/// Susun satu baris alamat baca-manusia dari [Placemark] (prioritas Indonesia).
/// Memakai `thoroughfare` / `subThoroughfare` bila `street` kosong (sering di Android).
String formatPlacemarkAddressForApproval(Placemark place) {
  String nt(String? s) => (s ?? '').trim();

  var line1 = nt(place.street);
  if (line1.isEmpty) {
    final sub = nt(place.subThoroughfare);
    final thru = nt(place.thoroughfare);
    if (sub.isNotEmpty && thru.isNotEmpty) {
      line1 = '$sub $thru';
    } else if (thru.isNotEmpty) {
      line1 = thru;
    } else if (sub.isNotEmpty) {
      line1 = sub;
    } else {
      line1 = nt(place.name);
    }
  }

  final parts = <String>[];
  if (line1.isNotEmpty) parts.add(line1);

  void addUnique(String value) {
    final t = value.trim();
    if (t.isEmpty) return;
    final lower = t.toLowerCase();
    if (parts.any((p) => p.toLowerCase() == lower)) return;
    parts.add(t);
  }

  addUnique(nt(place.subLocality));

  final subAdm = nt(place.subAdministrativeArea);
  if (subAdm.isNotEmpty) {
    final lower = subAdm.toLowerCase();
    addUnique(
      lower.contains('kecamatan') ? subAdm : 'Kecamatan $subAdm',
    );
  }

  addUnique(nt(place.locality));
  addUnique(nt(place.administrativeArea));

  return parts.join(', ');
}

/// Label lokasi/toko dari raw `orderWrap` API (sama logika dengan header approval).
String approvalOrderWrapWorkPlace(dynamic wrap) {
  if (wrap is! Map) return '';
  final map = Map<String, dynamic>.from(wrap);
  final order = map['order_letter'] as Map<String, dynamic>? ?? {};
  for (final v in <dynamic>[
    map['work_place_name'],
    map['workplace_name'],
    order['work_place_name'],
    order['workplace_name'],
    order['work_place'],
  ]) {
    final s = v?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
  }
  return '';
}

/// Daftar unik `work_place` untuk tab Selesai (urut A–Z).
List<String> approvalHistoryWorkPlaceOptions(List<dynamic> history) {
  final set = <String>{};
  for (final w in history) {
    final label = approvalOrderWrapWorkPlace(w);
    if (label.isNotEmpty) set.add(label);
  }
  final out = set.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return out;
}

/// Riwayat approval difilter di klien menurut lokasi/toko.
List<dynamic> approvalHistoryFilteredByWorkPlace(
  List<dynamic> history,
  String? workPlace,
) {
  if (workPlace == null || workPlace.isEmpty) return history;
  return history
      .where((w) => approvalOrderWrapWorkPlace(w) == workPlace)
      .toList();
}

/// Filter list approval (pending atau history) berdasarkan query teks.
/// Cocokkan terhadap: no_sp, customer_name, work_place, creator, item pertama.
List<dynamic> approvalFilteredByQuery(List<dynamic> items, String query) {
  if (query.isEmpty) return items;
  final q = query.toLowerCase().trim();
  return items.where((wrap) {
    if (wrap is! Map) return false;
    final order = (wrap['order_letter'] as Map<String, dynamic>? ?? {});
    final noSp = (order['no_sp'] as String? ?? '').toLowerCase();
    final customer = (order['customer_name'] as String? ?? '').toLowerCase();
    final creator = approvalOrderWrapCreatorLabel(wrap).toLowerCase();
    final workPlace = approvalOrderWrapWorkPlace(wrap).toLowerCase();
    final details = wrap['order_letter_details'] as List<dynamic>? ?? [];
    var itemName = '';
    if (details.isNotEmpty) {
      final first = details.first;
      if (first is Map) {
        itemName = ((first['item_description'] as String?) ??
                (first['desc_1'] as String?) ??
                '')
            .toLowerCase();
      }
    }
    return noSp.contains(q) ||
        customer.contains(q) ||
        creator.contains(q) ||
        workPlace.contains(q) ||
        itemName.contains(q);
  }).toList();
}

/// Label pembuat SP dari wrap approval (nama → sales → id).
String approvalOrderWrapCreatorLabel(dynamic wrap) {
  if (wrap is! Map) return '';
  final order = wrap['order_letter'] as Map<String, dynamic>? ?? {};
  for (final v in <dynamic>[
    order['creator_name'],
    order['sales_name'],
    wrap['creator_name'],
    order['creator'],
    order['user_id'],
  ]) {
    final s = v?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
  }
  return '';
}

/// Label filter creator (kosong → "Tanpa nama pembuat").
String approvalOrderWrapCreatorFilterLabel(dynamic wrap) {
  final label = approvalOrderWrapCreatorLabel(wrap);
  return label.isEmpty ? 'Tanpa nama pembuat' : label;
}

/// Daftar unik pembuat SP (urut A–Z) — pola sama [approvalHistoryWorkPlaceOptions].
List<String> approvalCreatorOptions(List<dynamic> wraps) {
  final set = <String>{};
  for (final w in wraps) {
    set.add(approvalOrderWrapCreatorFilterLabel(w));
  }
  final out = set.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return out;
}

/// Filter klien menurut pembuat SP (null/empty = semua).
List<dynamic> approvalFilteredByCreator(
  List<dynamic> wraps,
  String? creator,
) {
  if (creator == null || creator.isEmpty) return wraps;
  return wraps
      .where((w) => approvalOrderWrapCreatorFilterLabel(w) == creator)
      .toList();
}

/// Sort baris detail API menurut `line_number` (urutan input).
List<Map<String, dynamic>> sortOrderLetterDetailsByLineNumber(
  List<dynamic> details,
) {
  final maps = details
      .whereType<Map<dynamic, dynamic>>()
      .map(Map<String, dynamic>.from)
      .toList();
  maps.sort((a, b) {
    final la = (a['line_number'] as num?)?.toInt() ?? 0;
    final lb = (b['line_number'] as num?)?.toInt() ?? 0;
    if (la > 0 && lb > 0 && la != lb) return la.compareTo(lb);
    if (la > 0 && lb <= 0) return -1;
    if (la <= 0 && lb > 0) return 1;
    final ida = (a['order_letter_detail_id'] as num?)?.toInt() ??
        (a['id'] as num?)?.toInt() ??
        0;
    final idb = (b['order_letter_detail_id'] as num?)?.toInt() ??
        (b['id'] as num?)?.toInt() ??
        0;
    return ida.compareTo(idb);
  });
  return maps;
}
