import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_helpers.dart';

/// Builds the main items table for the PDF invoice.
abstract final class PdfItemsTable {
  static List<pw.Widget> buildItemsTable(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> details,
    List<Map<String, dynamic>> discounts, {
    required bool isInternal,
  }) {
    final headers = isInternal
        ? [
            'BRAND',
            'ORDER',
            'NAMA BARANG',
            'QTY',
            'PRICELIST',
            'END USER PRICE',
            'DISCOUNT',
            'HARGA TOTAL'
          ]
        : [
            'BRAND',
            'ORDER',
            'NAMA BARANG',
            'QTY',
            'PRICELIST',
            'DISCOUNT',
            'HARGA TOTAL'
          ];

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: headers
            .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ))
            .toList(),
      ),
    ];

    var bundleOrderCounter = 1;
    for (var i = 0; i < details.length; i++) {
      final d = details[i];
      final brand = _brandAbbr(d['brand']?.toString() ?? '');
      final name =
          d['item_description']?.toString() ?? d['desc_1']?.toString() ?? '';
      final qty = PdfHelpers.intFrom(d['qty']);
      final unitPrice = PdfHelpers.dbl(d['unit_price']);
      final extPrice = PdfHelpers.dbl(d['extended_price']);
      final custPrice = PdfHelpers.dbl(d['customer_price']);
      final netPrice = PdfHelpers.dbl(d['net_price'] ?? custPrice);
      final disc = unitPrice - netPrice;
      final takeAway = d['take_away'] == true ||
          d['take_away']?.toString().toLowerCase() == 'take away';

      final itemType = (d['item_type']?.toString() ?? '').toLowerCase();
      final isMattress =
          itemType.contains('mattress') || itemType.contains('kasur');
      final isMainItem = isMattress || (i == 0 && itemType.isEmpty);
      final brandCell = isMainItem ? brand : '';
      final orderCell = isMainItem ? '${bundleOrderCounter++}' : '';

      final displayName = takeAway ? '$name (TAKE AWAY)' : name;
      final nameWidget = _buildNameCell(displayName,
          isMattress: isMattress,
          subtitle: isInternal ? (d['item_description']?.toString()) : null,
          mainText: isInternal ? (d['desc_1']?.toString()) : null);

      if (isInternal) {
        final eup = custPrice == 0 ? extPrice : custPrice;
        final discInternal = eup - netPrice;
        final discWidget = _buildDiscountCellInternal(
            discInternal, d, discounts,
            pricelist: eup);
        tableRows.add(pw.TableRow(children: [
          PdfHelpers.tc(brandCell, align: pw.TextAlign.center),
          PdfHelpers.tc(orderCell, align: pw.TextAlign.center),
          nameWidget,
          PdfHelpers.tc('$qty', align: pw.TextAlign.center),
          PdfHelpers.currencyTc(unitPrice),
          PdfHelpers.currencyTc(eup),
          discWidget,
          PdfHelpers.currencyTc(netPrice),
        ]));
      } else {
        tableRows.add(pw.TableRow(children: [
          PdfHelpers.tc(brandCell, align: pw.TextAlign.center),
          PdfHelpers.tc(orderCell, align: pw.TextAlign.center),
          nameWidget,
          PdfHelpers.tc('$qty', align: pw.TextAlign.center),
          PdfHelpers.currencyTc(unitPrice),
          PdfHelpers.currencyTc(disc > 0 ? disc : 0),
          PdfHelpers.currencyTc(netPrice),
        ]));
      }
    }

    final columnWidths = isInternal
        ? {
            0: const pw.FlexColumnWidth(1.0),
            1: const pw.FlexColumnWidth(0.8),
            2: const pw.FlexColumnWidth(3.5),
            3: const pw.FlexColumnWidth(0.7),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(1.5),
            6: const pw.FlexColumnWidth(1.5),
            7: const pw.FlexColumnWidth(1.5)
          }
        : {
            0: const pw.FlexColumnWidth(1.0),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(4.5),
            3: const pw.FlexColumnWidth(0.8),
            4: const pw.FlexColumnWidth(2.0),
            5: const pw.FlexColumnWidth(2.0),
            6: const pw.FlexColumnWidth(2.0)
          };

    final itemsTable = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: columnWidths,
      children: tableRows,
    );

    final postage = PdfHelpers.dbl(order['postage']);
    if (postage <= 0) return [itemsTable];

    final shippingWidths = isInternal
        ? {0: const pw.FlexColumnWidth(6.0), 1: const pw.FlexColumnWidth(6.0)}
        : {0: const pw.FlexColumnWidth(7.5), 1: const pw.FlexColumnWidth(6.0)};

    final shippingTable = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: shippingWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Ongkos Kirim / Angkut',
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: PdfHelpers.buildCurrencyCell(postage, isBold: true),
            ),
          ],
        ),
      ],
    );

    return [itemsTable, shippingTable];
  }

  static pw.Widget _buildNameCell(String name,
      {required bool isMattress, String? subtitle, String? mainText}) {
    if (subtitle != null &&
        subtitle.isNotEmpty &&
        mainText != null &&
        mainText.isNotEmpty) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(
            left: isMattress ? 6 : 18, top: 6, bottom: 6, right: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(mainText,
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: isMattress
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal)),
            pw.SizedBox(height: 1),
            pw.Text(subtitle,
                style: pw.TextStyle(
                    fontSize: 6.5,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic)),
          ],
        ),
      );
    }
    return pw.Padding(
      padding: pw.EdgeInsets.only(
          left: isMattress ? 6 : 18, top: 6, bottom: 6, right: 6),
      child: pw.Text(name,
          style: pw.TextStyle(
              fontSize: 8,
              fontWeight:
                  isMattress ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  static pw.Widget _buildDiscountCellInternal(
    double totalDiscount,
    Map<String, dynamic> detail,
    List<Map<String, dynamic>> allDiscounts, {
    double pricelist = 0,
  }) {
    final detailId =
        PdfHelpers.intFrom(detail['order_letter_detail_id'] ?? detail['id']);
    final itemDiscounts = allDiscounts.where((d) {
      final dId =
          PdfHelpers.intFrom(d['order_letter_detail_id'] ?? d['detail_id']);
      return dId == detailId && detailId > 0;
    }).toList()
      ..sort((a, b) => PdfHelpers.intFrom(a['approver_level_id'])
          .compareTo(PdfHelpers.intFrom(b['approver_level_id'])));

    final pcts = <String>[];
    for (final d in itemDiscounts) {
      final pct = PdfHelpers.dbl(d['discount']);
      if (pct > 0) {
        pcts.add(pct % 1 == 0
            ? '${pct.toInt()}%'
            : '${pct.toStringAsFixed(2).replaceAll(RegExp(r'0+\$'), '').replaceAll(RegExp(r'\.\$'), '')}%');
      }
    }
    String? pctText = pcts.isNotEmpty ? pcts.join(' + ') : null;
    if (pctText == null && pricelist > 0 && totalDiscount > 0) {
      final p = (totalDiscount / pricelist) * 100;
      pctText = p % 1 == 0 ? '${p.toInt()}%' : '${p.toStringAsFixed(1)}%';
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          PdfHelpers.buildCurrencyCell(totalDiscount),
          if (pctText != null && totalDiscount > 0)
            pw.Text(pctText,
                style:
                    const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                textAlign: pw.TextAlign.right),
        ],
      ),
    );
  }

  static String _brandAbbr(String brand) {
    final b = brand.toLowerCase();
    if (b.contains('spring air')) return 'SA';
    if (b.contains('therapedic')) return 'TH';
    if (b.contains('comforta')) return 'CF';
    if (b.contains('sleep spa')) return 'SS';
    if (b.contains('superfit')) return 'SF';
    if (b.contains('isleep')) return 'isleep';
    return brand.length >= 2
        ? brand.substring(0, 2).toUpperCase()
        : brand.toUpperCase();
  }
}
