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
/// Cocokkan terhadap: no_sp, customer_name, work_place, dan nama item pertama.
List<dynamic> approvalFilteredByQuery(List<dynamic> items, String query) {
  if (query.isEmpty) return items;
  final q = query.toLowerCase().trim();
  return items.where((wrap) {
    if (wrap is! Map) return false;
    final order = (wrap['order_letter'] as Map<String, dynamic>? ?? {});
    final noSp = (order['no_sp'] as String? ?? '').toLowerCase();
    final customer = (order['customer_name'] as String? ?? '').toLowerCase();
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
        workPlace.contains(q) ||
        itemName.contains(q);
  }).toList();
}
