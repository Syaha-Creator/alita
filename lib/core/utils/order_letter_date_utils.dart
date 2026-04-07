/// Aturan tanggal **Surat Pesanan** (`order_date`): bulan kalender yang sama
/// dengan hari ini, tidak boleh setelah hari ini (berlaku universal direct/indirect).
abstract final class OrderLetterDateUtils {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Tanggal 1 pada bulan [reference] (lokal).
  static DateTime firstDayOfMonth({DateTime? reference}) {
    final r = dateOnly(reference ?? DateTime.now());
    return DateTime(r.year, r.month, 1);
  }

  /// Hari ini (tanggal saja, lokal).
  static DateTime today({DateTime? reference}) =>
      dateOnly(reference ?? DateTime.now());

  /// `true` jika [date] sejajar dengan bulan [reference] dan tidak setelah hari [reference].
  static bool isValidOrderLetterDate(
    DateTime date, {
    DateTime? reference,
  }) {
    final ref = today(reference: reference);
    final d = dateOnly(date);
    if (d.isAfter(ref)) return false;
    if (d.year != ref.year || d.month != ref.month) return false;
    return true;
  }

  /// Membatasi [date] ke rentang [tanggal 1 bulan berjalan, hari ini].
  static DateTime clampToValidOrderLetterDate(
    DateTime date, {
    DateTime? reference,
  }) {
    final ref = today(reference: reference);
    final start = DateTime(ref.year, ref.month, 1);
    final d = dateOnly(date);
    if (d.isBefore(start)) return start;
    if (d.isAfter(ref)) return ref;
    return d;
  }
}
