import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../pricelist/data/models/product.dart';
import '../data/quotation_model.dart';
import 'quotation_pdf_cell_helpers.dart';

/// Builds the items table section of the quotation PDF.
///
/// Extracted from [QuotationPdfGenerator] to reduce file size.
class QuotationPdfItemsBuilder {
  QuotationPdfItemsBuilder._();

  static List<pw.Widget> build(QuotationModel q) {
    final headers = [
      'BRAND',
      'ORDER',
      'NAMA BARANG',
      'QTY',
      'PRICELIST',
      'DISCOUNT',
      'HARGA TOTAL',
    ];
    final headerStyle =
        pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold);

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: headers
            .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(h,
                      textAlign: pw.TextAlign.center, style: headerStyle),
                ))
            .toList(),
      ),
    ];

    var orderCounter = 1;
    for (var i = 0; i < q.items.length; i++) {
      final item = q.items[i];
      final p = item.product;
      final brand = QuotationPdfCellHelpers.brandAbbr(p.brand);
      final ukuran = p.ukuran;
      final currentOrder = '${orderCounter++}';

      if (_hasComponent(p.kasur)) {
        final kasurName =
            QuotationPdfCellHelpers.appendSizeIfMissing(p.name, ukuran);
        final displayName =
            q.isTakeAway ? '$kasurName (TAKE AWAY)' : kasurName;
        final unitPl = p.plKasur;
        final unitEup = p.eupKasur;
        final disc = unitPl - unitEup;

        tableRows.add(_buildItemRow(
          brandCell: brand,
          orderCell: currentOrder,
          name: displayName,
          isBold: true,
          indent: 6,
          qty: item.quantity,
          pricelist: unitPl,
          discount: disc > 0 ? disc : 0,
          total: unitEup * item.quantity,
        ));
      }

      if (p.isSet && _hasComponent(p.divan)) {
        final divanName =
            QuotationPdfCellHelpers.cleanComponentName(p.divan, ukuran);
        final unitPl = p.plDivan;
        final unitEup = p.eupDivan;
        final disc = unitPl - unitEup;

        tableRows.add(_buildItemRow(
          name: divanName,
          indent: 18,
          qty: item.quantity,
          pricelist: unitPl,
          discount: disc > 0 ? disc : 0,
          total: unitEup * item.quantity,
        ));
      }

      if (p.isSet && _hasComponent(p.headboard)) {
        final hbName =
            QuotationPdfCellHelpers.cleanComponentName(p.headboard, ukuran);
        final unitPl = p.plHeadboard;
        final unitEup = p.eupHeadboard;
        final disc = unitPl - unitEup;

        tableRows.add(_buildItemRow(
          name: hbName,
          indent: 18,
          qty: item.quantity,
          pricelist: unitPl,
          discount: disc > 0 ? disc : 0,
          total: unitEup * item.quantity,
        ));
      }

      if (p.isSet && _hasComponent(p.sorong)) {
        final sorongName =
            QuotationPdfCellHelpers.cleanComponentName(p.sorong, ukuran);
        final unitPl = p.plSorong;
        final unitEup = p.eupSorong;
        final disc = unitPl - unitEup;

        tableRows.add(_buildItemRow(
          name: sorongName,
          indent: 18,
          qty: item.quantity,
          pricelist: unitPl,
          discount: disc > 0 ? disc : 0,
          total: unitEup * item.quantity,
        ));
      }

      for (final bonus in item.bonusSnapshots) {
        final bonusPlPrice = _resolveBonusPlPrice(p, bonus.name);

        tableRows.add(_buildItemRow(
          name: '${bonus.name} (Bonus)',
          indent: 18,
          qty: bonus.qty,
          pricelist: bonusPlPrice,
          discount: bonusPlPrice,
          total: 0,
        ));
      }
    }

    final columnWidths = {
      0: const pw.FlexColumnWidth(1.0),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(4.5),
      3: const pw.FlexColumnWidth(0.8),
      4: const pw.FlexColumnWidth(2.0),
      5: const pw.FlexColumnWidth(2.0),
      6: const pw.FlexColumnWidth(2.0),
    };

    final itemsTable = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: columnWidths,
      children: tableRows,
    );

    final postage = QuotationPdfCellHelpers.parsePostage(q.postage);
    if (postage <= 0) return [itemsTable];

    final shippingTable = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(34.5),
        1: pw.FlexColumnWidth(6.0),
      },
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
              child:
                  QuotationPdfCellHelpers.buildCurrencyCell(postage, isBold: true),
            ),
          ],
        ),
      ],
    );

    return [itemsTable, shippingTable];
  }

  static bool _hasComponent(String value) {
    final lower = value.trim().toLowerCase();
    return lower.isNotEmpty && !lower.contains('tanpa');
  }

  static pw.TableRow _buildItemRow({
    String brandCell = '',
    String orderCell = '',
    required String name,
    bool isBold = false,
    double indent = 6,
    required int qty,
    required double pricelist,
    required double discount,
    required double total,
  }) {
    return pw.TableRow(children: [
      QuotationPdfCellHelpers.tc(brandCell, align: pw.TextAlign.center),
      QuotationPdfCellHelpers.tc(orderCell, align: pw.TextAlign.center),
      pw.Padding(
        padding:
            pw.EdgeInsets.only(left: indent, top: 6, bottom: 6, right: 6),
        child: pw.Text(name,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ),
      QuotationPdfCellHelpers.tc('$qty', align: pw.TextAlign.center),
      QuotationPdfCellHelpers.currencyTc(pricelist),
      QuotationPdfCellHelpers.currencyTc(discount),
      QuotationPdfCellHelpers.currencyTc(total),
    ]);
  }

  static double _resolveBonusPlPrice(Product p, String bonusName) {
    final lower = bonusName.trim().toLowerCase();
    final entries = [
      (p.bonus1, p.plBonus1),
      (p.bonus2, p.plBonus2),
      (p.bonus3, p.plBonus3),
      (p.bonus4, p.plBonus4),
      (p.bonus5, p.plBonus5),
      (p.bonus6, p.plBonus6),
      (p.bonus7, p.plBonus7),
      (p.bonus8, p.plBonus8),
    ];
    for (final (name, price) in entries) {
      if (name != null &&
          name.trim().toLowerCase() == lower &&
          price != null &&
          price > 0) {
        return price;
      }
    }
    return 0;
  }
}
