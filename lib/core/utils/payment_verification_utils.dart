/// Menentukan apakah satu baris `order_letter_payments` dihitung sebagai
/// dana masuk yang sah untuk perhitungan "Total Dibayar" / "Sisa Tagihan".
///
/// Backend mengirim field `verified` sebagai tri-state:
/// - `true`  → sudah diverifikasi finance → dihitung.
/// - `null`  → belum direview → tetap dihitung (pembayaran nyata, hanya
///   belum sempat dicek finance).
/// - `false` → ditolak / duplikat / tidak valid → **wajib dikeluarkan**
///   dari total, supaya tidak dobel-hitung pembayaran yang sudah dibatalkan.
///
/// Singkatnya: hitung semua KECUALI yang eksplisit `false`.
bool paymentCountsTowardTotal(dynamic verifiedRaw) {
  if (verifiedRaw == null) return true;
  if (verifiedRaw is bool) return verifiedRaw;
  if (verifiedRaw is num) return verifiedRaw != 0;
  final s = verifiedRaw.toString().trim().toLowerCase();
  if (s.isEmpty || s == 'null') return true;
  return s != 'false' && s != '0';
}
