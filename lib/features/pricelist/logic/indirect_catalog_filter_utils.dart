import 'dart:math';

/// Filter helpers for mode indirect: channel "toko" + brand by [catcode_27].
class IndirectCatalogFilterUtils {
  IndirectCatalogFilterUtils._();

  static const _catcodeKeys = <String>[
    'catcode_27',
    'catcode27',
    'catcode',
    'code',
    'brand_code',
    'pl_catcode',
    'pl_catcode_27',
  ];

  /// Minimal skor dianggap "cocok" dari field master (bukan tebakan substring nama).
  static const int _minStrongScore = 50;

  /// Fallback jika baris brand tidak punya catcode: kode toko → substring nama brand (lower).
  /// Kunci = [catcode_27] normal (tanpa spasi, lower).
  /// Superfit = SF, Sleep Spa = SS (sama seperti singkatan brand di PDF).
  static const Map<String, List<String>> _catcodeBrandHints = {
    'sa': ['spring air'],
    'cf': ['comforta'],
    'th': ['therapedic'],
    'sf': ['superfit'],
    'ss': ['sleep spa'],
    'is': ['isleep'],
    'sp': ['sleep spa'],
  };

  /// Channel names that contain "toko" (case-insensitive). Exact `Toko` sorts first.
  static List<String> filterTokoChannels(Iterable<String> all) {
    final list = all
        .where((n) => n.trim().toLowerCase().contains('toko'))
        .toList();
    list.sort((a, b) {
      final ae = a.trim().toLowerCase() == 'toko';
      final be = b.trim().toLowerCase() == 'toko';
      if (ae != be) return ae ? -1 : 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return list;
  }

  /// Prefer channel bernama persis "Toko", lalu entri pertama daftar terfilter.
  static String pickDefaultTokoChannel(List<String> tokoChannels) {
    if (tokoChannels.isEmpty) {
      throw StateError('pickDefaultTokoChannel: empty list');
    }
    for (final c in tokoChannels) {
      if (c.trim().toLowerCase() == 'toko') return c;
    }
    return tokoChannels.first;
  }

  /// Nama brand untuk channel terpilih; jika [catcode27] terisi, sempitkan ke brand yang selaras.
  static List<String> brandNamesForChannel(
    List<Map<String, dynamic>> channels,
    List<Map<String, dynamic>> brands,
    String channelName, {
    String? catcode27,
  }) {
    if (channels.isEmpty || brands.isEmpty) return [];

    final channelObj = channels.firstWhere(
      (c) => c['channel']?.toString() == channelName,
      orElse: () => <String, dynamic>{},
    );
    final rawId = channelObj['id'];
    if (rawId == null) return [];
    final channelId =
        rawId is int ? rawId : int.tryParse(rawId.toString());
    if (channelId == null) return [];

    final inChannel = brands.where((b) {
      final plId = b['pl_channel_id'];
      if (plId == null) return false;
      final plIdInt = plId is int ? plId : int.tryParse(plId.toString());
      return plIdInt != null && plIdInt == channelId;
    }).toList();

    final code = _normToken(catcode27 ?? '');
    if (code.isEmpty) {
      return _uniqueBrandNames(inChannel);
    }

    final scored = inChannel
        .map((b) => MapEntry(b, _catcodeMatchScore(b, code)))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        final na = (a.key['brand'] ?? '').toString().toLowerCase();
        final nb = (b.key['brand'] ?? '').toString().toLowerCase();
        return na.compareTo(nb);
      });

    final maxScore = scored.isEmpty ? 0 : scored.first.value;
    if (maxScore >= _minStrongScore) {
      return _uniqueBrandNames(scored.map((e) => e.key).toList());
    }

    final hinted = _rowsMatchingCatcodeHints(inChannel, code);
    if (hinted.isNotEmpty) {
      hinted.sort((a, b) {
        final cmp = _hintMatchScore(b, code).compareTo(_hintMatchScore(a, code));
        if (cmp != 0) return cmp;
        final na = (a['brand'] ?? '').toString().toLowerCase();
        final nb = (b['brand'] ?? '').toString().toLowerCase();
        return na.compareTo(nb);
      });
      return _uniqueBrandNames(hinted);
    }

    if (scored.isNotEmpty) {
      return _uniqueBrandNames(scored.map((e) => e.key).toList());
    }

    // Catcode toko terisi tapi channel ini tidak punya brand yang selaras — jangan
    // fallback ke semua brand channel (menyesatkan, mis. Comforta untuk toko SA).
    return [];
  }

  static List<Map<String, dynamic>> _rowsMatchingCatcodeHints(
    List<Map<String, dynamic>> inChannel,
    String codeNorm,
  ) {
    final hints = _catcodeBrandHints[codeNorm];
    if (hints == null || hints.isEmpty) return [];

    return inChannel.where((b) {
      final name = _normToken(b['brand']?.toString() ?? '');
      if (name.isEmpty) return false;
      return hints.any((h) => name.contains(_normToken(h)));
    }).toList();
  }

  static int _hintMatchScore(Map<String, dynamic> b, String codeNorm) {
    final hints = _catcodeBrandHints[codeNorm];
    if (hints == null) return 0;
    final name = _normToken(b['brand']?.toString() ?? '');
    var s = 0;
    for (final h in hints) {
      final hn = _normToken(h);
      if (hn.isEmpty) continue;
      if (name.startsWith(hn)) {
        s += 100;
      } else if (name.contains(hn)) {
        s += 60;
      }
    }
    return s;
  }

  static List<String> _uniqueBrandNames(List<Map<String, dynamic>> rows) {
    final names = rows
        .map((b) => (b['brand'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  /// Skor kecocokan toko [code] dengan baris brand (field catcode dulu; nama brand tanpa substring 2-huruf).
  static int _catcodeMatchScore(Map<String, dynamic> b, String code) {
    final c = _normToken(code);
    if (c.isEmpty) return 0;
    var best = 0;

    for (final key in _catcodeKeys) {
      final raw = b[key]?.toString();
      if (raw == null || raw.trim().isEmpty) continue;
      final v = _normToken(raw);
      if (v == c) {
        best = max(best, 100);
        continue;
      }
      if (v.startsWith('$c-') || v.startsWith('${c}_')) {
        best = max(best, 88);
        continue;
      }
      final first = _firstSegment(v);
      if (first.isNotEmpty && first == c) {
        best = max(best, 78);
        continue;
      }
      // Substring di field kode saja (bukan di nama brand) — hindari false positive.
      if (c.length >= 3 && v.contains(c)) {
        best = max(best, 45);
      }
    }

    return best;
  }

  static String _normToken(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  static String _firstSegment(String s) {
    final t = _normToken(s);
    if (t.isEmpty) return '';
    return t.split(RegExp(r'[-_/]')).first;
  }
}
