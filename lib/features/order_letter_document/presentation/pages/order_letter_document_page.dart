import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../services/pdf_services.dart';
import '../../data/models/order_letter_document_model.dart';
import '../../data/repositories/order_letter_document_repository.dart';
import '../../../cart/domain/entities/cart_entity.dart';
import '../../../product/domain/entities/product_entity.dart';

class OrderLetterDocumentPage extends StatefulWidget {
  final int orderLetterId;

  const OrderLetterDocumentPage({
    super.key,
    required this.orderLetterId,
  });

  @override
  State<OrderLetterDocumentPage> createState() =>
      _OrderLetterDocumentPageState();
}

class _OrderLetterDocumentPageState extends State<OrderLetterDocumentPage> {
  OrderLetterDocumentModel? _document;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = GetIt.instance<OrderLetterDocumentRepository>();
      final document =
          await repository.getOrderLetterDocument(widget.orderLetterId);

      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surat Pesanan'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocument,
          ),
        ],
      ),
      floatingActionButton: _document != null
          ? Builder(
              builder: (buttonContext) => FloatingActionButton.extended(
                onPressed: () => _generatePDF(buttonContext),
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                icon: const Icon(Icons.picture_as_pdf),
                elevation: 8,
                label: const Text('Generate PDF'),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDocument,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _document == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Dokumen tidak ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pastikan order letter ID valid',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildDocumentContent(),
                    ),
    );
  }

  Widget _buildDocumentContent() {
    final document = _document!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildItemsTable(),
          const SizedBox(height: 16),
          _buildTotalsSection(),
          const SizedBox(height: 16),
          _buildApprovalSection(),
          const SizedBox(height: 16),
          _buildTermsAndConditions(),
          const SizedBox(height: 16),
          _buildSignatureSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: const Text(
                  'SURAT PESANAN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'No. SP: ${_document!.noSp}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Status: ${_document!.status}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(_document!.status),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Tanggal: ${_formatDate(_document!.createdAt)}'),
          const SizedBox(height: 4),
          Text('Dibuat oleh: ${_document!.creator}'),
          const SizedBox(height: 8),
          Text('Customer: ${_document!.customerName}'),
          const SizedBox(height: 4),
          Text('Phone: ${_document!.phone}'),
          const SizedBox(height: 4),
          Text('Address: ${_document!.address}'),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    final details = _document!.details;

    if (details.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Tidak ada detail pesanan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: const Text(
              'DETAIL PESANAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _buildOrderItemCards(details),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderItemCards(List<dynamic> details) {
    final List<Widget> cards = [];

    // Kelompokkan detail berdasarkan kasur utama
    final kasurDetails = details.where((d) => d.itemType == 'kasur').toList();

    print('Total details: ${details.length}');
    print('Kasur details: ${kasurDetails.length}');

    // Debug: print all details first to see the structure
    print('=== ALL DETAILS STRUCTURE ===');
    for (int j = 0; j < details.length; j++) {
      final detail = details[j];
      print(
          '  $j: itemType=${detail.itemType}, desc1="${detail.desc1}", desc2="${detail.desc2}"');
      // Print all available fields
      print('      Fields: ${detail.runtimeType.toString()}');
      if (detail.runtimeType.toString().contains('Map')) {
        print('      Map keys: ${(detail as Map).keys.toList()}');
      }
    }

    for (int i = 0; i < kasurDetails.length; i++) {
      final kasurDetail = kasurDetails[i];
      final kasurIndex = i + 1;

      print('\n=== PROCESSING KASUR $kasurIndex ===');
      print('Kasur: ${kasurDetail.desc1} - ${kasurDetail.desc2}');
      print('Kasur desc1: "${kasurDetail.desc1}"');
      print('Kasur desc2: "${kasurDetail.desc2}"');

      // Coba berbagai cara matching untuk aksesoris
      List<dynamic> relatedAccessories = [];

      // Method 1: Exact desc1 match
      var accessories1 = details
          .where((d) =>
              d.itemType != 'kasur' &&
              d.itemType != 'Bonus' &&
              d.desc1 == kasurDetail.desc1)
          .toList();
      print('Method 1 (exact desc1): ${accessories1.length} accessories');

      // Method 2: Partial desc1 match
      var accessories2 = details
          .where((d) =>
              d.itemType != 'kasur' &&
              d.itemType != 'Bonus' &&
              d.desc1.toString().contains(kasurDetail.desc1.toString()))
          .toList();
      print('Method 2 (partial desc1): ${accessories2.length} accessories');

      // Method 3: Any field match
      var accessories3 = details
          .where((d) =>
              d.itemType != 'kasur' &&
              d.itemType != 'Bonus' &&
              (d.desc1.toString().contains(kasurDetail.desc1.toString()) ||
                  d.desc2.toString().contains(kasurDetail.desc1.toString()) ||
                  d.desc1.toString().contains(kasurDetail.desc2.toString()) ||
                  d.desc2.toString().contains(kasurDetail.desc2.toString())))
          .toList();
      print('Method 3 (any field): ${accessories3.length} accessories');

      // Method 4: Show all non-kasur, non-bonus items
      var allAccessories = details
          .where((d) => d.itemType != 'kasur' && d.itemType != 'Bonus')
          .toList();
      print('All non-kasur, non-bonus items: ${allAccessories.length}');
      for (var acc in allAccessories) {
        print('  - ${acc.itemType}: "${acc.desc1}" - "${acc.desc2}"');
      }

      // Gunakan method yang paling banyak hasilnya
      if (accessories3.isNotEmpty) {
        relatedAccessories = accessories3;
        print('Using Method 3: ${relatedAccessories.length} accessories');
      } else if (accessories2.isNotEmpty) {
        relatedAccessories = accessories2;
        print('Using Method 2: ${relatedAccessories.length} accessories');
      } else if (accessories1.isNotEmpty) {
        relatedAccessories = accessories1;
        print('Using Method 1: ${relatedAccessories.length} accessories');
      } else {
        print('No accessories found with any method!');
      }

      // Cari bonus yang terkait dengan kasur ini berdasarkan urutan item
      var relatedBonus = <dynamic>[];

      // Cari posisi kasur saat ini dalam array details
      final kasurIndexInDetails = details.indexWhere((d) =>
          d.itemType == 'kasur' &&
          d.desc1 == kasurDetail.desc1 &&
          d.desc2 == kasurDetail.desc2);

      print(
          'Kasur ${kasurDetail.desc1} - ${kasurDetail.desc2} found at index: $kasurIndexInDetails');

      // Cari posisi kasur berikutnya (jika ada)
      int nextKasurIndex = -1;
      for (int i = kasurIndexInDetails + 1; i < details.length; i++) {
        if (details[i].itemType == 'kasur') {
          nextKasurIndex = i;
          break;
        }
      }

      if (nextKasurIndex == -1) {
        nextKasurIndex = details
            .length; // Jika tidak ada kasur berikutnya, gunakan panjang array
      }

      print('Next kasur found at index: $nextKasurIndex');

      // Ambil bonus yang berada antara kasur saat ini dan kasur berikutnya
      for (int i = kasurIndexInDetails + 1; i < nextKasurIndex; i++) {
        if (details[i].itemType == 'Bonus') {
          relatedBonus.add(details[i]);
          print(
              'Added bonus at index $i: ${details[i].desc1} - ${details[i].desc2}');
        }
      }

      print('Total bonus for kasur $kasurIndex: ${relatedBonus.length}');

      print(
          'Found ${relatedAccessories.length} accessories for kasur $kasurIndex');
      print('Found ${relatedBonus.length} bonus for kasur $kasurIndex');

      // Debug: print found accessories
      if (relatedAccessories.isNotEmpty) {
        print('Found accessories:');
        for (var acc in relatedAccessories) {
          print('  - ${acc.itemType}: "${acc.desc1}" - "${acc.desc2}"');
        }
      }

      // Debug: print found bonus
      if (relatedBonus.isNotEmpty) {
        print('Found bonus for kasur $kasurIndex:');
        for (var b in relatedBonus) {
          print(
              '  - ${b.itemType}: "${b.desc1}" - "${b.desc2}" (qty: ${b.qty})');
        }
      } else {
        print('No bonus found for kasur $kasurIndex');
      }

      // Debug: print bonus details
      print('Bonus details for kasur $kasurIndex:');
      for (var b in relatedBonus) {
        print('  - ${b.itemType}: "${b.desc1}" - "${b.desc2}" (qty: ${b.qty})');
      }

      // Debug: print all available bonus items
      final allBonus = details.where((d) => d.itemType == 'Bonus').toList();
      print('All available bonus items: ${allBonus.length}');
      for (var b in allBonus) {
        print('  - ${b.itemType}: "${b.desc1}" - "${b.desc2}" (qty: ${b.qty})');
      }

      // Debug: check case sensitivity
      print('=== CASE SENSITIVITY CHECK ===');
      final bonusLower = details.where((d) => d.itemType == 'bonus').toList();
      final bonusUpper = details.where((d) => d.itemType == 'Bonus').toList();
      final bonusAny = details
          .where((d) => d.itemType.toString().toLowerCase() == 'bonus')
          .toList();
      print('Bonus with "bonus" (lower): ${bonusLower.length}');
      print('Bonus with "Bonus" (upper): ${bonusUpper.length}');
      print('Bonus with any case: ${bonusAny.length}');

      // Show all item types to debug
      final allItemTypes = details.map((d) => d.itemType).toSet().toList();
      print('All item types found: $allItemTypes');

      // Gunakan aksesoris yang sudah difilter, bukan semua aksesoris
      // relatedAccessories = allAccessories; // Hapus baris ini

      cards.add(_buildOrderItemCard(
        kasurIndex: kasurIndex,
        kasurDetail: kasurDetail,
        accessories: relatedAccessories,
        bonus: relatedBonus,
      ));
    }

    return cards;
  }

  Widget _buildOrderItemCard({
    required int kasurIndex,
    required dynamic kasurDetail,
    required List<dynamic> accessories,
    required List<dynamic> bonus,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pricelist = kasurDetail.unitPrice * kasurDetail.qty;
    final nett = _document!.extendedAmount;
    final discount = pricelist - nett;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan nomor urut, icon, nama kasur, dan quantity
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue[700] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$kasurIndex',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark ? Colors.blue[700] : Colors.blue[100],
                  child: Icon(
                    Icons.bed,
                    color: isDark ? Colors.white : Colors.blue[800],
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${kasurDetail.desc1} ${kasurDetail.desc2}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Qty: ${kasurDetail.qty}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Detail Produk Section - Aksesoris selain kasur
            if (accessories.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Detail Produk',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              ...accessories.map((acc) => _buildAccessoryRow(acc, isDark)),
              const SizedBox(height: 8),
            ],

            // Bonus Section
            if (bonus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 18,
                    color: isDark ? Colors.green[400] : Colors.green[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bonus',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...bonus.map((b) => Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${b.qty}x',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${b.desc1} ${b.desc2}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 8),
            ],

            // Informasi Harga Section - Dihapus untuk sementara

            // Total Harga Section - Dihapus untuk sementara
          ],
        ),
      ),
    );
  }

  Widget _buildAccessoryRow(dynamic acc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getAccessoryIcon(acc.itemType),
            size: 20,
            color: isDark ? Colors.grey[400] : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${acc.desc1} ${acc.desc2}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            '${acc.qty}x',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAccessoryIcon(String itemType) {
    switch (itemType) {
      case 'bonus':
        return Icons.card_giftcard;
      case 'chair':
        return Icons.chair;
      case 'bed':
        return Icons.bed;
      case 'divan':
        return Icons.chair; // Assuming divan is a type of chair
      case 'headboard':
        return Icons.chair; // Assuming headboard is a type of chair
      case 'sorong':
        return Icons.chair; // Assuming sorong is a type of chair
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Widget _buildTotalsSection() {
    final details = _document!.details;
    final discounts = _document!.discounts;

    final grandTotal = _document!.extendedAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINCIAN BIAYA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Tampilkan discount sebagai disc1 + disc2 + disc3 + disc4
          if (discounts.isNotEmpty) ...[
            _buildDiscountSection(discounts),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalRow('Grand Total', grandTotal, isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            FormatHelper.formatCurrency(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection(List<OrderLetterDiscountModel> discounts) {
    // Sort discounts by approver_level_id (1=User, 2=Direct Leader, 3=Indirect Leader, 4=Controller, 5=Analyst)
    final sortedDiscounts = List<OrderLetterDiscountModel>.from(discounts);
    sortedDiscounts.sort(
        (a, b) => (a.approverLevelId ?? 0).compareTo(b.approverLevelId ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text(
        //   'DISCOUNT',
        //   style: TextStyle(
        //     fontSize: 14,
        //     fontWeight: FontWeight.bold,
        //     color: Colors.red,
        //   ),
        // ),
        // const SizedBox(height: 8),
        ...sortedDiscounts.map((discount) {
          String levelLabel = '';
          switch (discount.approverLevelId) {
            case 1:
              levelLabel = 'Disc 1';
              break;
            case 2:
              levelLabel = 'Disc 2';
              break;
            case 3:
              levelLabel = 'Disc 3';
              break;
            case 4:
              levelLabel = 'Disc 4';
              break;
            case 5:
              levelLabel = 'Disc 5';
              break;
            default:
              levelLabel = 'Disc ${discount.approverLevelId}';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  levelLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '-${_formatDiscountPercentage(discount.discount)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Format discount percentage dengan maksimal 2 angka di belakang koma
  /// Hanya tampilkan angka di belakang koma jika ada angka selain 0
  String _formatDiscountPercentage(double percentage) {
    // Data discount sudah dalam format persentase, tidak perlu dikalikan 100
    // Jika angka bulat (tidak ada desimal), tampilkan tanpa koma
    if (percentage == percentage.toInt()) {
      return percentage.toInt().toString();
    }

    // Jika ada desimal, format dengan maksimal 2 angka di belakang koma
    final formatted = percentage.toStringAsFixed(2);

    // Hapus trailing zeros (angka 0 di belakang)
    final trimmed =
        formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');

    return trimmed;
  }

  Widget _buildApprovalSection() {
    final discounts = _document!.discounts;
    final approvals = _document!.approvals;

    // Sort discounts by approver_level_id (1=User, 2=Direct Leader, 3=Indirect Leader, 4=Controller, 5=Analyst)
    final sortedDiscounts = List<OrderLetterDiscountModel>.from(discounts);
    sortedDiscounts.sort(
        (a, b) => (a.approverLevelId ?? 0).compareTo(b.approverLevelId ?? 0));

    if (discounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Column(
          children: [
            Text(
              'STATUS APPROVAL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Icon(
              Icons.approval_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Tidak ada data approval',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS APPROVAL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...sortedDiscounts
              .map((discount) => _buildApprovalRow(discount, approvals)),
        ],
      ),
    );
  }

  Widget _buildApprovalRow(OrderLetterDiscountModel discount,
      List<OrderLetterApproveModel> approvals) {
    final approval = approvals.firstWhere(
      (a) => a.orderLetterDiscountId == discount.id,
      orElse: () => OrderLetterApproveModel(
        id: 0,
        orderLetterDiscountId: 0,
        leader: 0,
        jobLevelId: 0,
        createdAt: '',
        updatedAt: '',
      ),
    );

    final isApproved = discount.approved == true;
    final approvalDate =
        discount.approvedAt != null ? _formatDate(discount.approvedAt!) : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green[50] : Colors.orange[50],
        border: Border.all(
          color: isApproved ? Colors.green[300]! : Colors.orange[300]!,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.pending,
            color: isApproved ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discount.approverLevel ?? 'Unknown Level',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(discount.approverName ?? 'Unknown'),
                if (discount.approverWorkTitle != null)
                  Text(
                    discount.approverWorkTitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Text('Disetujui: $approvalDate'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isApproved ? 'DISETUJUI' : 'MENUNGGU',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYARAT DAN KETENTUAN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Surat pesanan ini berlaku setelah disetujui oleh pihak yang berwenang.\n'
            '2. Harga dan spesifikasi dapat berubah sewaktu-waktu.\n'
            '3. Pembayaran dilakukan sesuai dengan ketentuan yang berlaku.\n'
            '4. Pengiriman akan dilakukan setelah pembayaran lunas.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Dibuat oleh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Text('Tanda Tangan'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_document!.creator),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Disetujui oleh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Text('Tanda Tangan'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Pihak Berwenang'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(BuildContext buttonContext) async {
    if (_document == null) return;

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Convert order letter details to cart items format
      final cartItems = _document!.details.map((detail) {
        // extended_amount adalah harga net untuk kasur saja
        // Untuk item kasur, gunakan extended_amount
        // Untuk item lain (bonus), gunakan unit_price (biasanya 0)
        final netPrice = detail.itemType == 'kasur'
            ? _document!.extendedAmount
            : detail.unitPrice;

        return CartEntity(
          product: ProductEntity(
            id: detail.id,
            area: '',
            channel: '',
            brand: detail.brand,
            kasur: detail.desc1,
            divan: '',
            headboard: '',
            sorong: '',
            ukuran: detail.desc2,
            pricelist: detail.unitPrice,
            program: '',
            eupKasur: detail.unitPrice,
            eupDivan: 0,
            eupHeadboard: 0,
            endUserPrice: detail.unitPrice,
            bonus: [],
            discounts: [],
            isSet: false,
            plKasur: detail.unitPrice,
            plDivan: 0,
            plHeadboard: 0,
            plSorong: 0,
            eupSorong: 0,
            bottomPriceAnalyst: 0,
            disc1: 0,
            disc2: 0,
            disc3: 0,
            disc4: 0,
            disc5: 0,
          ),
          quantity: detail.qty,
          netPrice: netPrice,
          discountPercentages: [],
          isSelected: true,
        );
      }).toList();

      // Calculate totals
      final grandTotal = _document!.details.fold<double>(
        0.0,
        (sum, detail) => sum + (detail.qty * detail.unitPrice),
      );

      // Convert approval data to format expected by PDF service
      final approvalData = _document!.discounts.map((discount) {
        return {
          'approved': discount.approved,
          'approver_level': discount.approverLevel,
          'approver_level_id': discount.approverLevelId,
          'approver_name': discount.approverName,
          'approved_at': discount.approvedAt,
        };
      }).toList();

      // Generate PDF using existing service with order letter info
      final pdfBytes = await PDFService.generateCheckoutPDF(
        cartItems: cartItems,
        customerName: _document!.customerName,
        customerAddress: _document!.address,
        shippingAddress: _document!.addressShipTo,
        phoneNumber: _document!.phone,
        deliveryDate: _formatDate(_document!.createdAt),
        paymentMethod: 'Transfer',
        paymentAmount: _document!.extendedAmount,
        repaymentDate: _formatDate(_document!.createdAt),
        grandTotal: _document!.extendedAmount,
        email: _document!.email,
        keterangan: _document!.note,
        salesName: _document!.creator,
        orderLetterNo: _document!.noSp,
        orderLetterStatus: _document!.status,
        orderLetterDate: _formatDate(_document!.createdAt),
        approvalData: approvalData,
        orderLetterExtendedAmount: _document!.extendedAmount,
        orderLetterHargaAwal: _document!.hargaAwal,
        shipToName: _document!.shipToName,
      );

      // Save and share PDF with proper positioning for iOS
      final fileName = 'Surat_Pesanan_${_document!.noSp}.pdf';

      // Get the render box for proper positioning on iOS
      final RenderBox? box = buttonContext.findRenderObject() as RenderBox?;
      final Rect sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(
              200, 400, 120, 48); // Fallback to approximate FAB position

      await PDFService.sharePDFWithPosition(
          pdfBytes, fileName, sharePositionOrigin);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF berhasil dibuat dan dibagikan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
