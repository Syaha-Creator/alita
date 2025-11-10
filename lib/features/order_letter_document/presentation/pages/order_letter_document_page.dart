import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../services/pdf_services.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/order_letter_service.dart';
import '../../../../services/leader_service.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../theme/app_colors.dart';
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
  bool _isApprovalLoading = false;
  String? _creatorName; // Cache creator name
  bool _hasApprovalChanged = false;
  String? _updatedApprovalStatus;

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

      // Fetch creator name if creator is user ID
      if (document != null) {
        await _fetchCreatorName(document.creator);
      }

      setState(() {
        _document = document;
        _isLoading = false;
        _updatedApprovalStatus = document?.status;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Fetch creator name from user ID
  Future<void> _fetchCreatorName(String creator) async {
    try {
      // Check if creator is a user ID (numeric string)
      final creatorUserId = int.tryParse(creator);

      if (creatorUserId != null) {
        // Creator is user ID, fetch user name
        final leaderService = locator<LeaderService>();
        final leaderData = await leaderService.getLeaderByUser(
          userId: creator,
        );

        if (leaderData != null && leaderData.user.fullName.isNotEmpty) {
          _creatorName = leaderData.user.fullName;
        } else {
          _creatorName = 'User #$creator';
        }
      } else {
        // Creator is already a name
        _creatorName = creator;
      }
    } catch (e) {
      // If fetch fails, use fallback
      final creatorUserId = int.tryParse(creator);
      _creatorName = creatorUserId != null ? 'User #$creator' : creator;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_buildPopResult());
      },
      child: Scaffold(
        backgroundColor: isDark ? colorScheme.surface : Colors.grey[50],
        appBar: _document != null ? _buildCustomAppBar() : null,
        floatingActionButton: _document != null
            ? Builder(
                builder: (buttonContext) => FloatingActionButton.extended(
                  onPressed: () => _showPDFOptionsDialog(buttonContext),
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.picture_as_pdf),
                  elevation: 8,
                  label: const Text('Generate PDF'),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_error',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadDocument,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
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
                        padding: const EdgeInsets.only(bottom: 100),
                        child: _buildDocumentContent(),
                      ),
      ),
    );
  }

  /// Build custom AppBar with document information
  PreferredSizeWidget _buildCustomAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: isDark ? colorScheme.surface : Colors.white,
      foregroundColor: isDark ? colorScheme.onSurface : Colors.grey[800],
      elevation: 2,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.1),
      toolbarHeight: 80,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                isDark ? colorScheme.surfaceContainerHighest : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : Colors.grey[200]!),
          ),
          child: Icon(Icons.arrow_back_ios_new,
              color: isDark ? colorScheme.onSurfaceVariant : Colors.grey[700],
              size: 18),
        ),
        onPressed: _handleBackNavigation,
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.primaryContainer : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : Colors.blue[200]!),
            ),
            child: Icon(Icons.refresh,
                color:
                    isDark ? colorScheme.onPrimaryContainer : Colors.blue[600],
                size: 20),
          ),
          onPressed: _loadDocument,
        ),
      ],
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark ? colorScheme.primaryContainer : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.3)
                          : Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: isDark
                          ? colorScheme.onPrimaryContainer
                          : Colors.blue[600],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'SURAT PESANAN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? colorScheme.onPrimaryContainer
                              : Colors.blue[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_document!.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _getStatusColor(_document!.status)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _document!.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(_document!.status),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _document!.noSp,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? colorScheme.onSurface : Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50],
            border: Border(
              top: BorderSide(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tanggal',
                  value: _formatDate(_document!.createdAt),
                  color: Colors.orange[600]!,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.person_outline,
                  label: 'Creator',
                  value: _creatorName ?? _document!.creator,
                  color: Colors.green[600]!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build info item for AppBar bottom section
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: isDark
                ? Border.all(color: colorScheme.outline.withValues(alpha: 0.2))
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? colorScheme.primary : color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? colorScheme.onSurface : Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentContent() {
    final document = _document!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Customer info section - Clean design
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest
                      : Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                      bottom: BorderSide(
                          color: isDark
                              ? colorScheme.outline.withValues(alpha: 0.2)
                              : Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: isDark
                          ? colorScheme.onSurfaceVariant
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Informasi Customer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? colorScheme.onSurface : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Customer name row
                    _buildInfoRow(
                      icon: Icons.business,
                      label: 'Nama Customer',
                      value: document.customerName,
                      iconColor: Colors.blue[600]!,
                    ),
                    const SizedBox(height: 16),
                    // Phone row
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: 'Nomor Telepon',
                      value: _getAllPhonesForPDF(),
                      iconColor: Colors.green[600]!,
                    ),
                    const SizedBox(height: 16),
                    // Address row
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: 'Alamat',
                      value: document.address,
                      iconColor: Colors.orange[600]!,
                      isAddress: true,
                    ),
                    const SizedBox(height: 16),
                    // Showroom / Pameran row
                    _buildInfoRow(
                      icon: Icons.storefront_outlined,
                      label: 'Showroom / Pameran',
                      value:
                          (document.workPlaceName?.trim().isNotEmpty ?? false)
                              ? document.workPlaceName!.trim()
                              : '-',
                      iconColor: Colors.purple[600]!,
                      isAddress: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items section
        _buildItemsTable(),

        // Totals section
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildTotalsSection(),
        ),

        // Terms and conditions
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildTermsAndConditions(),
        ),

        // Approval Section
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildApprovalSection(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildItemsTable() {
    final details = _document!.details;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    if (details.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: isDark ? colorScheme.onSurfaceVariant : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada detail pesanan',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? colorScheme.onSurfaceVariant : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section dengan design yang menyatu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : Colors.blue[100]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: isDark ? colorScheme.primary : Colors.blue[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'DETAIL PESANAN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? colorScheme.onSurface : Colors.blue[700],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${details.where((d) => d.itemType == 'kasur').length} Produk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? colorScheme.primary : Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content section dengan padding yang konsisten
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

  List<Widget> _buildOrderItemCards(List<OrderLetterDetailModel> details) {
    final List<Widget> cards = [];

    // Kelompokkan detail berdasarkan kasur utama
    final kasurDetails = details.where((d) => d.itemType == 'kasur').toList();

    for (int i = 0; i < kasurDetails.length; i++) {
      final kasurDetail = kasurDetails[i];
      final kasurIndex = i + 1;

      // Coba berbagai cara matching untuk aksesoris
      List<OrderLetterDetailModel> relatedAccessories = [];

      // Method 1: Exact desc1 match
      var accessories1 = details
          .where((d) =>
              d.itemType != 'kasur' &&
              d.itemType != 'Bonus' &&
              d.desc1 == kasurDetail.desc1)
          .toList();

      // Method 2: Partial desc1 match
      var accessories2 = details
          .where((d) =>
              d.itemType != 'kasur' &&
              d.itemType != 'Bonus' &&
              d.desc1.toString().contains(kasurDetail.desc1.toString()))
          .toList();

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

      // Gunakan method yang paling banyak hasilnya
      if (accessories3.isNotEmpty) {
        relatedAccessories = accessories3;
      } else if (accessories2.isNotEmpty) {
        relatedAccessories = accessories2;
      } else if (accessories1.isNotEmpty) {
        relatedAccessories = accessories1;
      }

      // Cari bonus yang terkait dengan kasur ini berdasarkan urutan item
      var relatedBonus = <OrderLetterDetailModel>[];

      // Cari posisi kasur saat ini dalam array details
      final kasurIndexInDetails = details.indexWhere((d) =>
          d.itemType == 'kasur' &&
          d.desc1 == kasurDetail.desc1 &&
          d.desc2 == kasurDetail.desc2);

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

      // Ambil bonus yang berada antara kasur saat ini dan kasur berikutnya
      for (int i = kasurIndexInDetails + 1; i < nextKasurIndex; i++) {
        if (details[i].itemType == 'Bonus') {
          relatedBonus.add(details[i]);
        }
      }

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
    required OrderLetterDetailModel kasurDetail,
    required List<OrderLetterDetailModel> accessories,
    required List<OrderLetterDetailModel> bonus,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark
                ? colorScheme.outline.withValues(alpha: 0.2)
                : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    color: isDark
                        ? colorScheme.primaryContainer
                        : Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$kasurIndex',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? colorScheme.onPrimaryContainer
                          : Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      isDark ? colorScheme.primaryContainer : Colors.blue[100],
                  child: Icon(
                    Icons.bed,
                    color: isDark
                        ? colorScheme.onPrimaryContainer
                        : Colors.blue[800],
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
                      color: isDark ? colorScheme.onSurface : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Qty: ${kasurDetail.qty}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? colorScheme.onSurfaceVariant
                          : Colors.grey[800],
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
                  color: isDark ? colorScheme.onSurface : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              ...accessories
                  .map((acc) => _buildAccessoryRow(acc, isDark, colorScheme)),
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
                      color: isDark ? colorScheme.onSurface : Colors.black87,
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
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.desc1, // Hanya tampilkan desc1 untuk bonus
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark ? colorScheme.onSurface : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 8),
            ],

            // Discount Section - Menampilkan diskon yang terkait dengan kasur ini
            _buildDiscountSectionForKasur(kasurDetail, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSectionForKasur(
      OrderLetterDetailModel kasurDetail, bool isDark) {
    // Get discounts directly from the kasur detail
    final kasurDiscounts = kasurDetail.discounts;

    // Discount information logged for debugging if needed

    if (kasurDiscounts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter out discounts with 0.0 or null values, then sort by approver_level_id
    final filteredDiscounts = kasurDiscounts.where((discount) {
      // Hide discounts with 0.0 or null values
      return discount.discount > 0.0;
    }).toList();

    if (filteredDiscounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDiscounts =
        List<OrderLetterDiscountModel>.from(filteredDiscounts);
    sortedDiscounts.sort(
        (a, b) => (a.approverLevelId ?? 0).compareTo(b.approverLevelId ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Header for discount section
        Row(
          children: [
            Icon(
              Icons.discount,
              size: 16,
              color: isDark ? Colors.orange[400] : Colors.orange[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Diskon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Tampilkan diskon seperti di rincian biaya (sederhana)
        ...sortedDiscounts.asMap().entries.map((entry) {
          final index = entry.key;
          final discount = entry.value;

          String levelLabel = 'Disc ${index + 1}';
          Color statusColor = Colors.grey;
          IconData statusIcon = Icons.pending;

          // Determine status color and icon
          if (discount.approved == true) {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
          } else if (discount.approved == false) {
            // Only show cross for explicitly rejected (not pending)
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
          } else {
            // For pending status, use clock icon instead of cross to avoid confusion
            statusColor = Colors.orange;
            statusIcon = Icons.schedule;
          }

          return Container(
            margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            levelLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '- ${_formatDiscountPercentage(discount.discount)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (discount.approverName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          discount.approverName!,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                      if (discount.approvedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Approved: ${_formatDate(discount.approvedAt!)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAccessoryRow(
      OrderLetterDetailModel acc, bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getAccessoryIcon(acc.itemType),
            size: 20,
            color: isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${acc.desc1} ${acc.desc2}', // Tetap gabungkan desc1 dan desc2 untuk accessories
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? colorScheme.onSurface : Colors.black87,
              ),
            ),
          ),
          Text(
            '${acc.qty}x',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? colorScheme.onSurfaceVariant : Colors.grey[800],
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
    final hargaAwal = _document!.hargaAwal;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final grandTotal = _document!.extendedAmount;
    final totalDiscount = hargaAwal - grandTotal;
    final discountPercentage =
        hargaAwal > 0 ? (totalDiscount / hargaAwal) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : Colors.green[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : Colors.green[100]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment_outlined,
                  color: isDark ? colorScheme.primary : Colors.green[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'RINCIAN PEMBAYARAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? colorScheme.onSurface : Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        // Content section
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Harga Awal
              _buildPaymentRow(
                label: 'Harga Awal',
                amount: hargaAwal,
                color: Colors.grey[600]!,
                isSubtotal: true,
              ),
              const SizedBox(height: 8),

              // Diskon (jika ada)
              if (totalDiscount > 0) ...[
                _buildPaymentRow(
                  label: 'Total Diskon',
                  amount:
                      -totalDiscount, // Negative untuk menunjukkan pengurangan
                  color: Colors.red[600]!,
                  isDiscount: true,
                  percentage: discountPercentage,
                ),
                const SizedBox(height: 12),
                // Divider
                Container(
                  height: 1,
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : Colors.grey[300],
                ),
                const SizedBox(height: 12),
              ],

              // Grand Total
              _buildPaymentRow(
                label: 'Total yang Harus Dibayar',
                amount: grandTotal,
                color: Colors.green[700]!,
                isTotal: true,
              ),

              const SizedBox(height: 16),

              // Info Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark ? colorScheme.primaryContainer : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.3)
                          : Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark
                          ? colorScheme.onPrimaryContainer
                          : Colors.blue[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembayaran dilakukan 100% sebelum pengiriman',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? colorScheme.onPrimaryContainer
                              : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build payment row with different styles for different types
  Widget _buildPaymentRow({
    required String label,
    required double amount,
    required Color color,
    bool isSubtotal = false,
    bool isDiscount = false,
    bool isTotal = false,
    double? percentage,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? (isTotal
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2))
            : (isTotal ? Colors.green[50] : Colors.grey[50]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.2)
              : (isTotal ? Colors.green[200]! : Colors.grey[200]!),
          width: isTotal ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (isDiscount) ...[
                  Icon(
                    Icons.remove_circle_outline,
                    color: isDark ? AppColors.error : Colors.red[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                ] else if (isTotal) ...[
                  Icon(
                    Icons.check_circle_outline,
                    color: isDark ? AppColors.success : Colors.green[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isTotal ? 16 : 14,
                      fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? colorScheme.onSurface : color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (percentage != null && percentage > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.error.withValues(alpha: 0.15)
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.error : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isDiscount && amount < 0
                ? '- ${FormatHelper.formatCurrency(amount.abs())}'
                : FormatHelper.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isDark ? colorScheme.onSurface : color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDiscountPercentage(double percentage) {
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

  Widget _buildTermsAndConditions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : Colors.orange[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : Colors.orange[100]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: isDark ? colorScheme.primary : Colors.orange[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'SYARAT DAN KETENTUAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? colorScheme.onSurface : Colors.orange[700],
                ),
              ),
            ],
          ),
        ),
        // Content section
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTermsItem(
                '1',
                'Konsumen wajib melunasi 100% nilai pesanan sebelum melakukan pengiriman / penyerahan barang pesanan. Pelunasan dilakukan selambat-lambatnya 3 hari kerja sebelum jadwal pengiriman / penyerahan yang dijadwalkan.',
              ),
              const SizedBox(height: 12),
              _buildTermsItem(
                '2',
                'Barang yang sudah dipesan / dibeli, tidak dapat ditukar atau dikembalikan.',
              ),
              const SizedBox(height: 12),
              _buildTermsItem(
                '3',
                'Uang muka yang telah dibayarkan tidak dapat dikembalikan.',
              ),
              const SizedBox(height: 12),
              _buildTermsItem(
                '4',
                'Sleep Center berhak mengubah tanggal pengiriman dengan sebelumnya memberitahukan kepada konsumen.',
              ),
              const SizedBox(height: 12),
              _buildTermsItem(
                '5',
                'Surat Pesanan yang sudah lewat 3 (Tiga) bulan namun belum dikirim harus dilunasi jika tidak akan dianggap batal dan uang muka tidak dapat dikembalikan.',
              ),
              const SizedBox(height: 12),
              _buildTermsItem(
                '6',
                'Apabila konsumen menunda pengiriman selama lebih dari 2 (Dua) Bulan dari tanggal kirim awal, SP dianggap batal dan uang muka tidak dapat dikembalikan.',
              ),
              const SizedBox(height: 12),
              _buildTermsItem(
                '7',
                'Pembeli akan dikenakan biaya tambahan untuk pengiriman, pembongkaran, pengambilan furnitur dll yang disebabkan adanya kesulitan/ketidakcocokan penempatan furnitur di tempat atau ruangan yang dikehendaki oleh pembeli.',
              ),
              const SizedBox(height: 12),
              _buildTermsItem(
                '8',
                'Jika pengiriman dilakukan lebih dari 1 (Satu) kali, konsumen wajib melunasi pembelian sebelum pengiriman pertama.',
              ),
              const SizedBox(height: 12),
              _buildTermsItem(
                '9',
                'Untuk tipe dan ukuran khusus, pelunasan harus dilakukan saat pemesanan dan tidak dapat dibatalkan/diganti.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Check if current user can approve this order
    return FutureBuilder<bool>(
      future: _canUserApprove(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.approval,
                    color: isDark ? colorScheme.primary : Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Approval',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isApprovalLoading
                          ? null
                          : () => _showApprovalDialog('approve'),
                      icon: _isApprovalLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isApprovalLoading
                          ? null
                          : () => _showApprovalDialog('reject'),
                      icon: Icon(Icons.close, color: Colors.white),
                      label: Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _canUserApprove() async {
    try {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return false;

      final orderLetterService = locator<OrderLetterService>();
      final rawDiscounts = await orderLetterService.getOrderLetterDiscounts(
        orderLetterId: widget.orderLetterId,
      );

      return _canUserApproveSequentially(rawDiscounts, currentUserId);
    } catch (e) {
      return false;
    }
  }

  bool _canUserApproveSequentially(
      List<Map<String, dynamic>> discounts, int currentUserId) {
    if (discounts.isEmpty) return false;

    // Sort discounts by approver_level_id
    final sortedDiscounts = List<Map<String, dynamic>>.from(discounts)
      ..sort((a, b) =>
          (a['approver_level_id'] ?? 0).compareTo(b['approver_level_id'] ?? 0));

    // Find current user's discount level
    int? currentUserLevel;
    for (final discount in sortedDiscounts) {
      final approverId = discount['approver'];
      final approverName = discount['approver_name'];
      final approverLevelId = discount['approver_level_id'];

      if (approverId == currentUserId ||
          _isNameMatch(approverName, currentUserId)) {
        currentUserLevel = approverLevelId;
        break;
      }
    }

    if (currentUserLevel == null) return false;

    // Check if all previous levels are approved
    for (final discount in sortedDiscounts) {
      final level = discount['approver_level_id'] ?? 0;
      final approved = discount['approved'];

      if (level < currentUserLevel) {
        // Previous levels must be approved
        if (approved != true) {
          return false;
        }
      } else if (level == currentUserLevel) {
        // Current level should be pending
        if (approved != null) {
          return false;
        }
      }
    }

    return true;
  }

  bool _isNameMatch(String? approverName, int currentUserId) {
    // Simple name matching logic - you can enhance this
    return false;
  }

  void _showApprovalDialog(String action) {
    final isApprove = action == 'approve';
    final title = isApprove ? 'Approve Order' : 'Reject Order';
    final message = isApprove
        ? 'Are you sure you want to approve this order?'
        : 'Are you sure you want to reject this order?';
    final confirmText = isApprove ? 'Approve' : 'Reject';
    final confirmColor = isApprove ? Colors.green : Colors.red;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleApprovalAction(action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprovalAction(String action) async {
    try {
      setState(() {
        _isApprovalLoading = true;
      });

      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) {
        _showErrorSnackBar('User information not available');
        return;
      }

      final orderLetterService = locator<OrderLetterService>();
      final rawDiscounts = await orderLetterService.getOrderLetterDiscounts(
        orderLetterId: widget.orderLetterId,
      );

      // Get user's job level
      int jobLevelId = 1;
      for (final discount in rawDiscounts) {
        final approverId = discount['approver'];
        final approverName = discount['approver_name'];
        final approverLevelId = discount['approver_level_id'];

        if ((approverId == currentUserId ||
                _isNameMatch(approverName, currentUserId)) &&
            approverLevelId != null) {
          jobLevelId = approverLevelId;
          break;
        }
      }

      // Use batch approval for all pending discounts at user's level
      final result = await orderLetterService.batchApproveOrderLetterDiscounts(
        orderLetterId: widget.orderLetterId,
        leaderId: currentUserId,
        jobLevelId: jobLevelId,
      );

      final approvedCount = result['approved_count'] ?? 0;
      if (result['success'] == true && approvedCount > 0) {
        _showSuccessSnackBar(
            '$action - $approvedCount diskon berhasil diproses');

        await _loadDocument();

        setState(() {
          _hasApprovalChanged = true;
          _updatedApprovalStatus = _document?.status;
        });
      } else {
        _showErrorSnackBar(result['message'] ?? 'Approval failed');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to process approval: $e');
    } finally {
      setState(() {
        _isApprovalLoading = false;
      });
    }
  }

  void _handleBackNavigation() {
    Navigator.of(context).pop(_buildPopResult());
  }

  dynamic _buildPopResult() {
    if (_hasApprovalChanged) {
      return {
        'changed': true,
        'status': _updatedApprovalStatus ?? _document?.status,
      };
    }
    return false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showPDFOptionsDialog(BuildContext buttonContext) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Jenis PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue[600]),
              title: const Text('PDF Customer'),
              subtitle: const Text('PDF untuk customer (tanpa kolom approval)'),
              onTap: () {
                Navigator.of(context).pop();
                _generatePDF(buttonContext, showApprovalColumn: false);
              },
            ),
            ListTile(
              leading: Icon(Icons.approval, color: Colors.green[600]),
              title: const Text('PDF Approval'),
              subtitle: const Text('PDF dengan kolom approval dan stempel'),
              onTap: () {
                Navigator.of(context).pop();
                _generatePDF(buttonContext, showApprovalColumn: true);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(BuildContext buttonContext,
      {required bool showApprovalColumn}) async {
    if (_document == null) return;

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Group order letter details by kasur and create single CartEntity per group
      final kasurDetails = _document!.details
          .where((d) => d.itemType.toLowerCase() == 'kasur')
          .toList();
      final cartItems = <CartEntity>[];

      for (int i = 0; i < kasurDetails.length; i++) {
        final kasurDetail = kasurDetails[i];

        // Find position of this kasur in the details list
        final kasurIndexInDetails = _document!.details.indexWhere((d) =>
            d.id == kasurDetail.id && d.itemType.toLowerCase() == 'kasur');

        // Find next kasur position (or end of list)
        int nextKasurIndex = _document!.details.length;
        for (int j = kasurIndexInDetails + 1;
            j < _document!.details.length;
            j++) {
          if (_document!.details[j].itemType.toLowerCase() == 'kasur') {
            nextKasurIndex = j;
            break;
          }
        }

        // Get accessories and bonus for this kasur (items between this kasur and next kasur)
        final relatedItems =
            _document!.details.sublist(kasurIndexInDetails + 1, nextKasurIndex);

        // Initialize product fields
        String kasur = kasurDetail.desc1;
        String divan = '';
        String headboard = '';
        String sorong = '';
        double plKasur = kasurDetail.unitPrice, // Pricelist (harga asli)
            plDivan = 0,
            plHeadboard = 0,
            plSorong = 0;
        double eupKasur = kasurDetail.netPrice ??
                kasurDetail.unitPrice, // Harga net (setelah discount)
            eupDivan = 0,
            eupHeadboard = 0,
            eupSorong = 0;

        final bonusItems = <BonusItem>[];

        // Process related items (accessories and bonus)
        for (final item in relatedItems) {
          switch (item.itemType.toLowerCase()) {
            case 'divan':
              divan = '${item.desc1} ${item.desc2}';
              plDivan = item.unitPrice; // Pricelist (harga asli)
              eupDivan = item.netPrice ??
                  item.unitPrice; // Harga net (setelah discount)
              break;
            case 'headboard':
              headboard = '${item.desc1} ${item.desc2}';
              plHeadboard = item.unitPrice; // Pricelist (harga asli)
              eupHeadboard = item.netPrice ??
                  item.unitPrice; // Harga net (setelah discount)
              break;
            case 'sorong':
              sorong = '${item.desc1} ${item.desc2}';
              plSorong = item.unitPrice; // Pricelist (harga asli)
              eupSorong = item.netPrice ??
                  item.unitPrice; // Harga net (setelah discount)
              break;
            case 'bonus':
              bonusItems.add(BonusItem(
                name: item.desc1,
                quantity: item.qty,
                takeAway: item.takeAway ?? false, // Add take away status
              ));
              break;
          }
        }

        cartItems.add(CartEntity(
          cartLineId:
              'doc_${kasurDetail.id}_${i}_${DateTime.now().microsecondsSinceEpoch}',
          product: ProductEntity(
            id: kasurDetail.id, // This is the order_letter_detail_id we need
            area: '',
            channel: '',
            brand: kasurDetail.brand,
            kasur: kasur,
            divan: divan,
            headboard: headboard,
            sorong: sorong,
            ukuran: kasurDetail.desc2,
            pricelist: kasurDetail.unitPrice,
            program: '',
            eupKasur: eupKasur,
            eupDivan: eupDivan,
            eupHeadboard: eupHeadboard,
            eupSorong: eupSorong,
            endUserPrice: kasurDetail.unitPrice,
            bonus: bonusItems,
            discounts: [],
            isSet: false,
            plKasur: plKasur,
            plDivan: plDivan,
            plHeadboard: plHeadboard,
            plSorong: plSorong,
            bottomPriceAnalyst: 0,
            disc1: 0,
            disc2: 0,
            disc3: 0,
            disc4: 0,
            disc5: 0,
          ),
          quantity: kasurDetail.qty,
          netPrice: kasurDetail.netPrice ?? kasurDetail.unitPrice,
          discountPercentages: [],
          isSelected: true,
        ));
      }

      // Convert approval data to format expected by PDF service
      final approvalData =
          await Future.wait(_document!.discounts.map((discount) async {
        // Check if approver_name is a user ID (numeric), if so fetch real name
        String displayName = discount.approverName ?? 'Unknown';

        if (int.tryParse(displayName) != null) {
          // It's a user ID, fetch the real name
          try {
            final leaderService = locator<LeaderService>();
            final leaderData = await leaderService.getLeaderByUser(
              userId: displayName,
            );

            if (leaderData != null && leaderData.user.fullName.isNotEmpty) {
              displayName = leaderData.user.fullName;
            } else {
              displayName = 'User #$displayName';
            }
          } catch (e) {
            displayName = 'User #$displayName';
          }
        }

        return {
          'approved': discount.approved,
          'approver_level': discount.approverLevel,
          'approver_level_id': discount.approverLevelId,
          'approver_name': displayName,
          'approved_at': discount.approvedAt,
        };
      }));

      // Convert discount data for pricelist calculation
      // Map discounts by product description (desc_1 + desc_2) instead of order_letter_detail_id
      final discountData = <Map<String, dynamic>>[];

      // Group discounts by product name (desc1) to apply same discounts to all variants
      final Map<String, List<OrderLetterDiscountModel>> discountsByProduct = {};

      for (final discount in _document!.discounts) {
        // Find the corresponding detail to get desc_1 and desc_2
        final detail = _document!.details.firstWhere(
          (d) => d.id == discount.orderLetterDetailId,
          orElse: () => _document!.details.first, // fallback
        );

        final productName =
            detail.desc1; // Use only desc1 (product name) as key
        if (!discountsByProduct.containsKey(productName)) {
          discountsByProduct[productName] = [];
        }
        discountsByProduct[productName]!.add(discount);
      }

      // Now create discount data for all product variants
      for (final detail in _document!.details) {
        final productName = detail.desc1;
        final productKey = '${detail.desc1}_${detail.desc2}';

        // Check if we have discounts for this product name
        if (discountsByProduct.containsKey(productName)) {
          final productDiscounts = discountsByProduct[productName]!;

          // Apply all discounts for this product to this variant
          for (final discount in productDiscounts) {
            discountData.add({
              'id': discount.id,
              'order_letter_detail_id': discount.orderLetterDetailId,
              'order_letter_id': discount.orderLetterId,
              'discount': discount.discount,
              'approver_level_id': discount.approverLevelId,
              'product_key': productKey,
            });
          }
        }
      }

      // Generate PDF using existing service with order letter info
      final pdfBytes = await PDFService.generateCheckoutPDF(
        cartItems: cartItems,
        customerName: _document!.customerName,
        customerAddress: _document!.address,
        shippingAddress: _document!.addressShipTo,
        phoneNumber: _getAllPhonesForPDF(),
        deliveryDate: _formatDate(_document!.requestDate),
        orderDate: _formatDate(_document!.orderDate),
        paymentMethod: 'Transfer',
        paymentAmount: _document!.extendedAmount,
        repaymentDate: _formatDate(_document!.requestDate),
        grandTotal: _document!.extendedAmount,
        email: _document!.email,
        keterangan: _document!.note,
        salesName: _creatorName ?? _document!.creator,
        spgCode: _document!.spgCode,
        orderLetterNo: _document!.noSp,
        orderLetterStatus: _document!.status,
        orderLetterDate: _formatDate(_document!.createdAt),
        workPlaceName: _document!.workPlaceName,
        approvalData: approvalData,
        orderLetterExtendedAmount: _document!.extendedAmount,
        orderLetterHargaAwal: _document!.hargaAwal,
        shipToName: _document!.shipToName,
        discountData: discountData,
        showApprovalColumn: showApprovalColumn,
      );

      final pdfType = showApprovalColumn ? 'Approval' : 'Customer';
      final fileName =
          '${_document!.customerName}_${_document!.noSp}_$pdfType.pdf';

      // Get the render box for proper positioning on iOS
      if (!buttonContext.mounted) return;
      final RenderBox? box = buttonContext.findRenderObject() as RenderBox?;
      final Rect sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(
              200, 400, 120, 48); // Fallback to approximate FAB position

      await PDFService.sharePDFWithPosition(
          pdfBytes, fileName, sharePositionOrigin);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF berhasil dibuat dan dibagikan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  /// Build info row with icon, label and value
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isAddress = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: isDark
                ? Border.all(color: colorScheme.outline.withValues(alpha: 0.2))
                : null,
          ),
          child: Icon(
            icon,
            color: isDark ? colorScheme.primary : iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? colorScheme.onSurfaceVariant : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isAddress ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? colorScheme.onSurface : Colors.grey[800],
                  height: isAddress ? 1.3 : 1.2,
                ),
                maxLines: isAddress ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get all phone numbers from contacts as a formatted string for PDF
  String _getAllPhonesForPDF() {
    if (_document?.contacts.isNotEmpty == true) {
      return _document!.contacts.map((contact) => contact.phone).join(', ');
    }
    // Fallback to main phone field if no contacts
    return _document?.phone ?? '-';
  }

  /// Build individual terms and conditions item with proper formatting
  Widget _buildTermsItem(String number, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.primaryContainer : Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? colorScheme.onPrimaryContainer : Colors.blue[800],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.justify, // Rata kanan kiri
            style: TextStyle(
              fontSize: 12,
              height: 1.4, // Line height for better readability
              color: isDark ? colorScheme.onSurface : null,
            ),
          ),
        ),
      ],
    );
  }
}
