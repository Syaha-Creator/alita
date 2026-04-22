import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../utils/take_away_parse.dart';
import 'pdf_helpers.dart';

/// Builds the main items table for the PDF invoice.
///
/// Kontrak detail (selaras checkout / API): **`unit_price`**, **`customer_price`**,
/// dan **`net_price`** = **per unit**; kolom **JML** = [qty]. Maka:
/// - **Pricelist (internal)** per unit; **eksternal**: kolom total pricelist
///   baris (supaya selaras dengan diskon & total).
/// - **Harga EUP** (internal) & **harga total** = per unit × qty (total baris).
/// - **Diskon internal** = selisih total EUP baris vs total net baris.
/// - **Diskon eksternal (customer)** = **`total pricelist baris − harga total`**
///   dengan total pricelist = `unit_price × qty`. Kolom **TOTAL PRICELIST**
///   menampilkan angka total itu (bukan hanya satuan), supaya selaras dengan
///   kolom **DISKON** dan **HARGA TOTAL** tanpa mengira-ngira × qty.
abstract final class PdfItemsTable {
  static List<pw.Widget> buildItemsTable(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> details,
    List<Map<String, dynamic>> discounts, {
    required bool isInternal,
    bool hideStoreDiscountTiers = false,
  }) {
    final headers = isInternal
        ? [
            'MEREK',
            'NO. URUT',
            'NAMA BARANG',
            'JML',
            'HARGA SATUAN',
            'HARGA EUP',
            'DISKON',
            'HARGA TOTAL'
          ]
        : [
            'MEREK',
            'NO. URUT',
            'NAMA BARANG',
            'JML',
            'PRICELIST',
            'DISKON',
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
    var previousWasBonus = true;
    for (var i = 0; i < details.length; i++) {
      final d = details[i];
      final brand = _brandAbbr(d['brand']?.toString() ?? '');
      final rawItemDesc = d['item_description']?.toString() ?? '';
      final rawDesc1 = d['desc_1']?.toString() ?? '';
      final name = (rawItemDesc.isNotEmpty && rawItemDesc != '-')
          ? rawItemDesc
          : rawDesc1;
      final qty = PdfHelpers.intFrom(d['qty']);
      final qtySafe = qty <= 0 ? 1 : qty;
      final unitPrice = PdfHelpers.dbl(d['unit_price']);
      final extPrice = PdfHelpers.dbl(d['extended_price']);
      final custPrice = PdfHelpers.dbl(d['customer_price']);
      final netPrice = PdfHelpers.dbl(d['net_price'] ?? custPrice);

      /// Total baris: API mengirim customer/net **per unit**; `extended_price` fallback total PL baris (internal).
      final lineEup = custPrice == 0 ? extPrice : custPrice * qtySafe;
      final lineNet = netPrice * qtySafe;

      /// Total pricelist baris (eksternal): tampilan kolom + dasar diskon.
      final linePricelistTotalExternal = unitPrice * qtySafe;
      final discExternal = linePricelistTotalExternal - lineNet;
      final takeAway = parseTakeAway(d['take_away']);

      final itemType = (d['item_type']?.toString() ?? '').toLowerCase();
      final isMattress =
          itemType.contains('mattress') || itemType.contains('kasur');
      final isBonus = itemType.contains('bonus');
      final isLeadItem = isMattress || (!isBonus && previousWasBonus);
      previousWasBonus = isBonus;
      final brandCell = isLeadItem ? brand : '';
      final orderCell = isLeadItem ? '${bundleOrderCounter++}' : '';

      final displayName = takeAway ? '$name (BAWA PULANG)' : name;
      final mainTextDisplay =
          _line1Desc1Desc2(d, isBonus: isBonus, takeAway: takeAway);
      final subtitleRaw = d['item_description']?.toString() ?? '';
      final trimmedSub = subtitleRaw.trim();
      final subtitle =
          trimmedSub.isNotEmpty && trimmedSub != '-' ? subtitleRaw : null;
      final mainLineForTwoRows = mainTextDisplay.isNotEmpty
          ? mainTextDisplay
          : (d['desc_1']?.toString().trim() ?? '');
      final primaryForCell = subtitle == null && mainTextDisplay.isNotEmpty
          ? mainTextDisplay
          : displayName;
      final nameWidget = _buildNameCell(
        primaryForCell,
        isBold: isLeadItem,
        subtitle: subtitle,
        mainText: subtitle != null
            ? (mainLineForTwoRows.isNotEmpty ? mainLineForTwoRows : displayName)
            : null,
      );

      if (isInternal) {
        final discInternal = lineEup - lineNet;
        final discWidget = _buildDiscountCellInternal(
            discInternal, d, discounts,
            pricelist: lineEup, hideStoreDiscountTiers: hideStoreDiscountTiers);
        final eupWidget = _buildEupCellInternal(
          lineEup: lineEup,
          detail: d,
          allDiscounts: discounts,
        );
        tableRows.add(pw.TableRow(children: [
          PdfHelpers.tc(brandCell, align: pw.TextAlign.center),
          PdfHelpers.tc(orderCell, align: pw.TextAlign.center),
          nameWidget,
          PdfHelpers.tc('$qty', align: pw.TextAlign.center),
          PdfHelpers.currencyTc(unitPrice),
          eupWidget,
          discWidget,
          PdfHelpers.currencyTc(lineNet),
        ]));
      } else {
        tableRows.add(pw.TableRow(children: [
          PdfHelpers.tc(brandCell, align: pw.TextAlign.center),
          PdfHelpers.tc(orderCell, align: pw.TextAlign.center),
          nameWidget,
          PdfHelpers.tc('$qty', align: pw.TextAlign.center),
          _externalPricelistCell(
            unitPrice: unitPrice,
            qtySafe: qtySafe,
            linePricelistTotal: linePricelistTotalExternal,
          ),
          PdfHelpers.currencyTc(discExternal > 0 ? discExternal : 0),
          PdfHelpers.currencyTc(lineNet),
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
        ? {0: const pw.FlexColumnWidth(42), 1: const pw.FlexColumnWidth(6.0)}
        : {0: const pw.FlexColumnWidth(34.5), 1: const pw.FlexColumnWidth(6.0)};

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

  /// Baris 1 kolom NAMA BARANG (PDF internal): [desc_1] + opsional [desc_2] untuk
  /// barang utama; bonus hanya [desc_1]. [takeAway] ditambahkan di akhir bila perlu.
  static String _line1Desc1Desc2(
    Map<String, dynamic> d, {
    required bool isBonus,
    required bool takeAway,
  }) {
    final desc1 = d['desc_1']?.toString().trim() ?? '';
    var line = desc1;
    if (!isBonus) {
      final desc2 = d['desc_2']?.toString().trim() ?? '';
      if (desc2.isNotEmpty && desc2 != '-') {
        line = desc1.isEmpty ? desc2 : '$desc1 · $desc2';
      }
    }
    if (takeAway && line.isNotEmpty) {
      line = '$line (BAWA PULANG)';
    }
    return line;
  }

  static pw.Widget _buildNameCell(String name,
      {required bool isBold, String? subtitle, String? mainText}) {
    const padding = pw.EdgeInsets.all(6);
    if (subtitle != null &&
        subtitle.isNotEmpty &&
        mainText != null &&
        mainText.isNotEmpty) {
      return pw.Padding(
        padding: padding,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(mainText,
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight:
                        isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
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
      padding: padding,
      child: pw.Text(name,
          style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  static bool _isStoreDiscountTier(Map<String, dynamic> d) {
    final level = d['approver_level']?.toString().toLowerCase() ?? '';
    return level.startsWith('diskon toko');
  }

  static pw.Widget _buildDiscountCellInternal(
    double totalDiscount,
    Map<String, dynamic> detail,
    List<Map<String, dynamic>> allDiscounts, {
    double pricelist = 0,
    bool hideStoreDiscountTiers = false,
  }) {
    final detailId =
        PdfHelpers.intFrom(detail['order_letter_detail_id'] ?? detail['id']);
    var itemDiscounts = allDiscounts.where((d) {
      final dId =
          PdfHelpers.intFrom(d['order_letter_detail_id'] ?? d['detail_id']);
      return dId == detailId && detailId > 0;
    }).toList();
    if (hideStoreDiscountTiers) {
      itemDiscounts =
          itemDiscounts.where((d) => !_isStoreDiscountTier(d)).toList();
    }
    // Urutan tampilan persentase line-2 mengikuti urutan cascade:
    //   diskon toko (standard) → lalu diskon input user (L1–L4).
    // Dalam kelompok yang sama, tetap urut naik berdasarkan approver_level_id.
    itemDiscounts.sort((a, b) {
      final aStore = _isStoreDiscountTier(a) ? 0 : 1;
      final bStore = _isStoreDiscountTier(b) ? 0 : 1;
      if (aStore != bStore) return aStore.compareTo(bStore);
      return PdfHelpers.intFrom(a['approver_level_id'])
          .compareTo(PdfHelpers.intFrom(b['approver_level_id']));
    });

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

  /// PDF internal kolom HARGA EUP:
  /// - Line 1: nominal [lineEup].
  /// - Line 2 (opsional): persentase `discount_program` jika ada pada salah satu
  ///   baris diskon untuk detail ini. Kalau tidak ada, kolom tetap satu baris.
  static pw.Widget _buildEupCellInternal({
    required double lineEup,
    required Map<String, dynamic> detail,
    required List<Map<String, dynamic>> allDiscounts,
  }) {
    final detailId =
        PdfHelpers.intFrom(detail['order_letter_detail_id'] ?? detail['id']);
    String? programText;
    if (detailId > 0) {
      for (final d in allDiscounts) {
        final dId =
            PdfHelpers.intFrom(d['order_letter_detail_id'] ?? d['detail_id']);
        if (dId != detailId) continue;
        final raw = d['discount_program']?.toString().trim() ?? '';
        if (raw.isEmpty || raw == '-') continue;
        programText = raw;
        break;
      }
    }

    if (programText == null) {
      return PdfHelpers.currencyTc(lineEup);
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          PdfHelpers.buildCurrencyCell(lineEup),
          pw.SizedBox(height: 2),
          pw.Text(
            programText,
            style:
                const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  /// PDF customer: isi kolom total pricelist = [linePricelistTotal] (`unit×qty`);
  /// bila qty > 1, baris kecil menunjukkan harga satuan agar tetap transparan.
  static pw.Widget _externalPricelistCell({
    required double unitPrice,
    required int qtySafe,
    required double linePricelistTotal,
  }) {
    if (qtySafe <= 1) {
      return PdfHelpers.currencyTc(linePricelistTotal);
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          PdfHelpers.buildCurrencyCell(linePricelistTotal),
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
