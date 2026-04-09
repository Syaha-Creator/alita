import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:alitapricelist/core/enums/order_status.dart';
import 'package:alitapricelist/core/utils/log.dart';

/// Shared PDF utilities used across multiple section builders.
abstract final class PdfHelpers {
  static final _curFmt = NumberFormat('#,##0', 'id_ID');
  static String cur(double n) => _curFmt.format(n.round());
  static String fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  static String fmtDateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy HH:mm').format(d);

  static double dbl(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int intFrom(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static List<Map<String, dynamic>> toListMap(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data
          .map((e) => e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  /// [ship] true = penerima; null/false = pemesan (kompatibel data lama).
  static bool _contactShipTrue(dynamic shipVal) {
    if (shipVal == null) return false;
    if (shipVal is bool) return shipVal;
    final s = shipVal.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  /// Gabungkan `order_letter_contacts` ke salinan [letter] untuk header PDF.
  /// Set [pdf_phones_pemesan] / [pdf_phones_penerima] dan perbarui [phone] bila perlu.
  static Map<String, dynamic> letterWithContactPhonesForPdf(
    Map<String, dynamic> letter,
    Map<String, dynamic> orderData,
  ) {
    final list = toListMap(orderData['order_letter_contacts']);
    if (list.isEmpty) return Map<String, dynamic>.from(letter);

    final pemesan = <String>[];
    final penerima = <String>[];
    for (final m in list) {
      final p = m['phone']?.toString().trim() ?? '';
      if (p.isEmpty) continue;
      final bucket = _contactShipTrue(m['ship']) ? penerima : pemesan;
      if (!bucket.contains(p)) bucket.add(p);
    }

    final out = Map<String, dynamic>.from(letter);
    final pemesanStr = pemesan.join(' / ');
    final penerimaStr = penerima.join(' / ');
    if (pemesanStr.isNotEmpty) out['pdf_phones_pemesan'] = pemesanStr;
    if (penerimaStr.isNotEmpty) out['pdf_phones_penerima'] = penerimaStr;

    if (penerimaStr.isNotEmpty) {
      out['phone'] = penerimaStr;
    } else if (pemesanStr.isNotEmpty) {
      out['phone'] = pemesanStr;
    }
    return out;
  }

  static String? prettyDate(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty || raw == '-') return null;
    try {
      final parsed = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      Log.warning('PDF prettyDate parse failed: $raw', tag: 'PDF');
      return raw;
    }
  }

  static String? extractTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return null;
    try {
      final tIdx = createdAt.indexOf('T');
      if (tIdx == -1) return null;
      final time = createdAt.substring(tIdx + 1);
      return time.length >= 5 ? time.substring(0, 5) : null;
    } catch (_) {
      Log.warning('PDF extractTime parse failed: $createdAt', tag: 'PDF');
      return null;
    }
  }

  /// Robust check: API may return bool `true`, string "approved", "true", or "1".
  static bool isApprovedStatus(dynamic value) =>
      OrderStatusX.fromDynamic(value) == OrderStatus.approved;

  // ── PDF cell helpers ──

  static pw.Widget tc(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: const pw.TextStyle(fontSize: 8), textAlign: align),
    );
  }

  static pw.Widget currencyTc(double amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: buildCurrencyCell(amount, isBold: isBold),
    );
  }

  static pw.Widget buildCurrencyCell(double amount, {bool isBold = false}) {
    final textStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Rp', style: textStyle),
        pw.Text(cur(amount), style: textStyle, textAlign: pw.TextAlign.right),
      ],
    );
  }
}
