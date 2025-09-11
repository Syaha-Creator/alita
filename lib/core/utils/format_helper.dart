import 'package:intl/intl.dart';

/// Utility untuk membantu format angka, currency, dan string.
class FormatHelper {
  /// Format angka menjadi currency (IDR) dengan pemisah ribuan.
  static String formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
  }

  /// Format string menjadi kapital pada huruf pertama setiap kata.
  static String capitalizeEachWord(String text) {
    return text.replaceAllMapped(
        RegExp(r'\b\w'), (match) => match.group(0)!.toUpperCase());
  }

  static String formatSimpleDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static DateTime? parseSimpleDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Format angka hanya dengan pemisah ribuan tanpa simbol mata uang
  static String formatNumber(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  /// Konversi dari format mata uang ke double
  static double parseCurrencyToDouble(String formatted) {
    String cleaned = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    final value = double.tryParse(cleaned) ?? 0.0;
    // Round to 2 decimal places to avoid floating point precision issues
    return double.parse(value.toStringAsFixed(2));
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
