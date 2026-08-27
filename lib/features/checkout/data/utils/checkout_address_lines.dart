/// Helpers for checkout address line 1 / 2 / 3 UI ↔ API payload fields.
class CheckoutAddressLines {
  CheckoutAddressLines._();

  static const String defaultCountry = 'Indonesia';

  /// Max chars per address line (UI + payload).
  ///
  /// Product cap is 40; if backend rejects longer values, lower this
  /// (column may be ~37–38).
  static const int maxLineLength = 40;

  /// Trims and truncates a single address line to [maxLineLength].
  static String clampLine(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLineLength) return trimmed;
    return trimmed.substring(0, maxLineLength);
  }

  /// Joins non-empty lines with `", "` for order_letter `address` payloads.
  static String join(String line1, String line2, [String line3 = '']) {
    return [line1, line2, line3]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');
  }

  /// Legacy single-string address: detail lines + Kec./kota/provinsi.
  static String legacyCombined({
    required String detailJoined,
    String? kecamatan,
    String? kota,
    String? provinsi,
    bool detailOnly = false,
  }) {
    final detail = detailJoined.trim();
    if (detailOnly) return detail;
    final kec = (kecamatan ?? '').trim();
    final city = (kota ?? '').trim();
    final state = (provinsi ?? '').trim();
    final suffixParts = <String>[
      if (kec.isNotEmpty) 'Kec. $kec',
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ];
    if (suffixParts.isEmpty) return detail;
    if (detail.isEmpty) return suffixParts.join(', ');
    return '$detail, ${suffixParts.join(', ')}';
  }

  /// Splits a legacy single address into up to 3 lines (quotation / edit restore).
  static ({String line1, String line2, String line3}) split(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (line1: '', line2: '', line3: '');
    }
    final parts = trimmed
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      return (line1: parts[0], line2: '', line3: '');
    }
    if (parts.length == 2) {
      return (line1: parts[0], line2: parts[1], line3: '');
    }
    return (
      line1: parts[0],
      line2: parts[1],
      line3: parts.sublist(2).join(', '),
    );
  }

  /// Structured sold-to / ship-to fields for `order_letters`.
  ///
  /// Mapping:
  /// - address1/2/3 ← line 1/2/3
  /// - city ← kota/kab
  /// - state ← provinsi
  /// - county ← kecamatan
  /// - country ← [defaultCountry] (fixed)
  /// - postal_code ← kode pos dari kelurahan (geo.velrox.cloud)
  static Map<String, dynamic> structuredBlock({
    required String prefix, // `soldto` | `shipto`
    required String address1,
    required String address2,
    required String address3,
    required String? city,
    required String? state,
    required String? county,
    String postalCode = '',
    String country = defaultCountry,
  }) {
    return {
      '${prefix}_address1': clampLine(address1),
      '${prefix}_address2': clampLine(address2),
      '${prefix}_address3': clampLine(address3),
      '${prefix}_city': (city ?? '').trim(),
      '${prefix}_state': (state ?? '').trim(),
      '${prefix}_county': (county ?? '').trim(),
      '${prefix}_postal_code': postalCode.trim(),
      '${prefix}_country': country.trim().isEmpty ? defaultCountry : country.trim(),
    };
  }
}
