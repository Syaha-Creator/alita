/// Label helpers for store / dealer names from APIs (e.g. alpha_name).
class StoreDisplayUtils {
  StoreDisplayUtils._();

  /// Satu baris daftar toko: nama bersih · [catcode_27] (kode disembunyikan dari kurung alpha_name).
  static String assignedStoreRowLabel({
    required String alphaName,
    String? catcode27,
  }) {
    final title = assignedStoreTitle(alphaName);
    final code = catcode27?.trim();
    if (code == null || code.isEmpty) return title;
    return '$title · $code';
  }

  /// Title for pickers / chips: no address suffix, no trailing codes in parens.
  ///
  /// - Drops everything after the first ` · ` (some payloads concatenate).
  /// - Then removes trailing ` ( … )` / `（…）` segments (termasuk jika diikuti `.` / `。`).
  /// - Merapikan titik/spasi di akhir (mis. `… (SA - REG).` → nama saja).
  static String assignedStoreTitle(String raw) {
    var s = raw.trim();
    final dotIdx = s.indexOf(' · ');
    if (dotIdx >= 0) {
      s = s.substring(0, dotIdx).trim();
    }
    s = withoutTrailingParenthetical(s);
    return _trimTrailingDotsAndSpace(s);
  }

  /// Removes trailing parenthetical segments from API names, e.g.
  /// `57 SEJAHTERA (SA - REG)` → `57 SEJAHTERA`.
  ///
  /// Supports ASCII `()` and fullwidth `（）`, and optional punctuation right after `)`.
  static String withoutTrailingParenthetical(String raw) {
    var s = raw.trim();
    final re = RegExp(r'\s*[\(（][^)）]*[\)）]\s*[.。…]*\s*$');
    while (re.hasMatch(s)) {
      s = s.replaceFirst(re, '').trimRight();
    }
    return s.trim();
  }

  static String _trimTrailingDotsAndSpace(String s) {
    return s.replaceAll(RegExp(r'[.\s]+$'), '').trim();
  }
}
