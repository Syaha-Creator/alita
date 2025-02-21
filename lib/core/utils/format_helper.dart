import 'package:intl/intl.dart';

class FormatHelper {
  /// Format angka ke mata uang Rupiah dengan simbol Rp dan tanpa desimal
  static String formatCurrency(double amount, {bool includeSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: includeSymbol ? 'Rp ' : '',
      decimalDigits: 0, // Menghilangkan angka di belakang koma
    );
    return formatter.format(amount);
  }

  /// Format angka hanya dengan pemisah ribuan tanpa simbol mata uang
  static String formatNumber(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  /// Konversi dari format mata uang ke double
  static double parseCurrencyToDouble(String formatted) {
    String cleaned = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format teks saat pengguna mengetik di TextField (otomatis tambahkan `Rp` dan pemisah ribuan)
  static String formatTextFieldCurrency(String input) {
    String cleaned =
        input.replaceAll(RegExp(r'[^0-9]'), ''); // Hapus semua non-digit
    if (cleaned.isEmpty) return "Rp 0"; // Jangan biarkan kosong
    double value = double.parse(cleaned);
    return "Rp ${NumberFormat('#,###', 'id_ID').format(value)}";
  }

  static String getMonthName(int month) {
    List<String> months = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember"
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : "Tidak Valid";
  }
}
