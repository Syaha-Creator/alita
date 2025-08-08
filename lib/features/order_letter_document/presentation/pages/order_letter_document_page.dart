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
          ? FloatingActionButton.extended(
              onPressed: _generatePDF,
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.picture_as_pdf),
              elevation: 8,
              label: const Text('Generate PDF'),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('NO')),
                DataColumn(label: Text('QTY')),
                DataColumn(label: Text('NAMA BARANG')),
                DataColumn(label: Text('HARGA\nPRICELIST')),
                DataColumn(label: Text('DISC/\nPROGRAM')),
                DataColumn(label: Text('HARGA\nNETT')),
              ],
              rows: details.asMap().entries.map((entry) {
                final index = entry.key;
                final detail = entry.value;
                final pricelist = detail.unitPrice * detail.qty;
                final nett = detail.itemType == 'kasur'
                    ? _document!.extendedAmount
                    : detail.unitPrice * detail.qty;
                final discount = pricelist - nett;

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text('${detail.qty}')),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${detail.desc1} ${detail.desc2}'),
                          if (detail.itemType == 'bonus')
                            Text(
                              '(BONUS)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text(FormatHelper.formatCurrency(pricelist))),
                    DataCell(Text(FormatHelper.formatCurrency(discount))),
                    DataCell(Text(FormatHelper.formatCurrency(nett))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final details = _document!.details;
    final discounts = _document!.discounts;

    final subtotal =
        _document!.extendedAmount * 0.89; // 89% dari extended amount
    final ppn = _document!.extendedAmount * 0.11; // 11% PPN
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalRow('Subtotal', subtotal),
                    _buildTotalRow('PPN 11%', ppn),
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

  Future<void> _generatePDF() async {
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

      // Save and share PDF
      final fileName = 'Surat_Pesanan_${_document!.noSp}.pdf';
      await PDFService.sharePDF(pdfBytes, fileName);

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
