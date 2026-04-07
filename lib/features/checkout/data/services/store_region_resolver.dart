import '../../../../core/utils/log.dart';
import '../models/region_result.dart';
import 'region_service.dart';

/// Maps teks provinsi/kecamatan dari master toko ke triple wilayah picker (EMSIFA).
///
/// Data toko kadang menyimpan kecamatan di field `city`; alamat panjang bisa
/// memuat "Kota …" / "Kec. …" untuk membatasi pencarian.
class StoreRegionResolver {
  StoreRegionResolver({RegionService? regionService})
      : _regionService = regionService ?? RegionService();

  final RegionService _regionService;

  /// Mengembalikan null jika tidak ada kecocokan — user harus pilih manual.
  Future<RegionResult?> resolve({
    required String state,
    required String city,
    String address = '',
  }) async {
    final stateTrim = state.trim();
    final cityTrim = city.trim();
    final addrTrim = address.trim();
    if (stateTrim.isEmpty && cityTrim.isEmpty && addrTrim.isEmpty) {
      return null;
    }

    try {
      final provinces = await _regionService.getProvinces();
      if (provinces.isEmpty) return null;

      final prov = _pickProvince(provinces, stateTrim, addrTrim);
      if (prov == null) return null;

      final provId = prov['id']?.toString() ?? '';
      final provName = prov['name']?.toString() ?? '';
      if (provId.isEmpty) return null;

      final regencies = await _regionService.getRegencies(provId);
      if (regencies.isEmpty) return null;

      final kotaHint = _kotaFromAddress(addrTrim);
      final kecHint = _kecamatanHint(cityTrim, addrTrim);
      if (kecHint.isEmpty && kotaHint == null) return null;

      final regencyCandidates = _filterRegencies(regencies, kotaHint);
      for (final reg in regencyCandidates) {
        final regId = reg['id']?.toString() ?? '';
        final regName = reg['name']?.toString() ?? '';
        if (regId.isEmpty) continue;

        final districts = await _regionService.getDistricts(regId);
        final match = _findDistrict(districts, kecHint);
        if (match != null) {
          final kecName = match['name']?.toString() ?? '';
          return RegionResult(
            provinsi: provName,
            kota: regName,
            kecamatan: kecName,
          );
        }
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'StoreRegionResolver.resolve');
    }
    return null;
  }

  Map<String, dynamic>? _pickProvince(
    List<Map<String, dynamic>> provinces,
    String state,
    String address,
  ) {
    Map<String, dynamic>? best;
    var bestScore = 0.0;
    final foldState = _fold(state);
    final foldAddr = _fold(address);

    for (final p in provinces) {
      final name = p['name']?.toString() ?? '';
      final foldName = _fold(name);
      var score = _adminNameScore(foldName, foldState);
      if (score < 0.5 && foldAddr.isNotEmpty) {
        score = score > _adminNameScore(foldName, foldAddr)
            ? score
            : _adminNameScore(foldName, foldAddr);
      }
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }
    return bestScore >= 0.45 ? best : null;
  }

  /// Skor 0–1 untuk seberapa mirip nama administratif EMSIFA dengan hint teks bebas.
  double _adminNameScore(String foldApiName, String foldHint) {
    if (foldApiName.isEmpty || foldHint.isEmpty) return 0;
    if (foldApiName == foldHint) return 1;
    if (foldApiName.contains(foldHint) || foldHint.contains(foldApiName)) {
      return 0.92;
    }
    // DKI / Jakarta
    final hintJakarta =
        foldHint.contains('jakarta') || foldHint.contains('dki');
    final apiJakarta = foldApiName.contains('jakarta');
    if (hintJakarta && apiJakarta) {
      if (foldHint.contains('ibukota') ||
          foldHint.contains('khusus') ||
          foldHint.contains('dki')) {
        return 0.88;
      }
      return 0.72;
    }
    // Token overlap
    final apiTokens = foldApiName.split(RegExp(r'\s+')).where((t) => t.length > 2);
    final hintTokens = foldHint.split(RegExp(r'\s+')).where((t) => t.length > 2);
    var overlap = 0;
    for (final t in hintTokens) {
      if (apiTokens.any((a) => a == t || a.contains(t) || t.contains(a))) {
        overlap++;
      }
    }
    if (overlap == 0) return 0;
    return 0.45 + (0.08 * overlap).clamp(0.0, 0.4);
  }

  List<Map<String, dynamic>> _filterRegencies(
    List<Map<String, dynamic>> regencies,
    String? kotaHint,
  ) {
    if (kotaHint == null || kotaHint.isEmpty) return regencies;
    final hint = _fold(kotaHint);
    final scored = <({Map<String, dynamic> reg, double score})>[];
    for (final r in regencies) {
      final n = _fold(r['name']?.toString() ?? '');
      if (n.isEmpty) continue;
      var s = _adminNameScore(n, hint);
      if (s < 0.5) {
        final stripped = n
            .replaceFirst(RegExp(r'^(kota|kabupaten)\s+'), '')
            .trim();
        if (stripped.isNotEmpty) {
          s = s > _adminNameScore(stripped, hint) ? s : _adminNameScore(stripped, hint);
        }
      }
      if (s >= 0.45) scored.add((reg: r, score: s));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.isEmpty) return regencies;
    return scored.map((e) => e.reg).toList();
  }

  Map<String, dynamic>? _findDistrict(
    List<Map<String, dynamic>> districts,
    String kecHintFolded,
  ) {
    if (kecHintFolded.isEmpty) return null;
    Map<String, dynamic>? best;
    var bestScore = 0.0;
    for (final d in districts) {
      final n = _fold(d['name']?.toString() ?? '');
      if (n.isEmpty) continue;
      var score = 0.0;
      if (n == kecHintFolded) {
        score = 1;
      } else if (n.contains(kecHintFolded) || kecHintFolded.contains(n)) {
        score = 0.9;
      } else {
        score = _tokenOverlapScore(n, kecHintFolded);
      }
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return bestScore >= 0.55 ? best : null;
  }

  double _tokenOverlapScore(String a, String b) {
    final ta = a.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
    final tb = b.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
    if (ta.isEmpty || tb.isEmpty) return 0;
    var hit = 0;
    for (final t in tb) {
      if (ta.any((x) => x == t || x.contains(t) || t.contains(x))) hit++;
    }
    return hit / tb.length;
  }

  String _kecamatanHint(String cityField, String address) {
    final fromCity = _stripKecamatanPrefix(cityField);
    if (fromCity.isNotEmpty) return _fold(fromCity);

    final re = RegExp(
      r'Kec\.?\s*([^,\n]+)',
      caseSensitive: false,
    );
    final m = re.firstMatch(address);
    if (m != null) {
      return _fold(m.group(1) ?? '');
    }
    return '';
  }

  String _stripKecamatanPrefix(String raw) {
    var s = raw.trim();
    s = s.replaceFirst(RegExp(r'^kecamatan\s+', caseSensitive: false), '');
    s = s.replaceFirst(RegExp(r'^kec\.\s*', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\bk\.b\.\s*', caseSensitive: false), 'kebon ');
    s = s.replaceAll(RegExp(r'\bkb\.\s*', caseSensitive: false), 'kebon ');
    return s.trim();
  }

  String? _kotaFromAddress(String address) {
    final re = RegExp(
      r'(?:Kota|Kabupaten)\s+([^,\n]+)',
      caseSensitive: false,
    );
    final m = re.firstMatch(address);
    if (m == null) return null;
    return m.group(1)?.trim();
  }

  String _fold(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[\.\,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
