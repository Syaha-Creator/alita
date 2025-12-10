import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../config/app_constant.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../services/pdf_services.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/order_letter_service.dart';
import '../../../../services/order_letter_payment_service.dart';
import '../../../../services/leader_service.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/order_letter_document_model.dart';
import '../../data/repositories/order_letter_document_repository.dart';
import '../../../cart/domain/entities/cart_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../widgets/document/document_widgets.dart';

/// Helper class to represent a grouped package
class _GroupedPackage {
  final List<OrderLetterDetailModel> kasurDetails;
  final List<OrderLetterDetailModel> accessories;
  final List<OrderLetterDetailModel> bonus;
  final int totalQty;

  _GroupedPackage({
    required this.kasurDetails,
    required this.accessories,
    required this.bonus,
    required this.totalQty,
  });
}

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
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final repository = GetIt.instance<OrderLetterDocumentRepository>();
      final document =
          await repository.getOrderLetterDocument(widget.orderLetterId);

      if (!mounted) return;

      if (document == null) {
        setState(() {
          _error = 'Dokumen tidak ditemukan atau tidak dapat dimuat';
          _isLoading = false;
        });
        return;
      }

      // Fetch creator name if creator is user ID
      try {
        await _fetchCreatorName(document.creator);
      } catch (e) {
        // Don't fail document loading if creator name fetch fails
        if (kDebugMode) {
          debugPrint('Failed to fetch creator name: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _document = document;
        _isLoading = false;
        _updatedApprovalStatus = document.status;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;

      // Log error for debugging
      if (kDebugMode) {
        debugPrint('OrderLetterDocumentPage: Error loading document: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      // Provide user-friendly error message
      String errorMessage = 'Gagal memuat dokumen';
      final errorString = e.toString();

      if (errorString.contains('Token not available') ||
          errorString.contains('Token tidak tersedia')) {
        errorMessage = 'Token tidak tersedia. Silakan login ulang.';
      } else if (errorString.contains('Status 404') ||
          errorString.contains('tidak ditemukan')) {
        errorMessage = 'Dokumen tidak ditemukan. ID: ${widget.orderLetterId}';
      } else if (errorString.contains('Status 401') ||
          errorString.contains('Status 403') ||
          errorString.contains('Tidak memiliki akses')) {
        errorMessage = 'Tidak memiliki akses untuk melihat dokumen ini';
      } else if (errorString.contains('Invalid response format') ||
          errorString.contains('Format data')) {
        errorMessage =
            'Format data dari server tidak valid. Silakan coba lagi.';
      } else if (errorString.contains('order_letter is null') ||
          errorString.contains('Data order letter')) {
        errorMessage = 'Data order letter tidak ditemukan di server';
      } else {
        // Use the error message from exception if it's already user-friendly
        errorMessage = errorString.replaceAll('Exception: ', '');
      }

      setState(() {
        _error = errorMessage;
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
        backgroundColor: isDark
            ? colorScheme.surface
            : AppColors.dominantLight, // 60% - Background
        appBar: _document != null
            ? DocumentAppBar(
                noSp: _document!.noSp,
                status: _document!.status,
                createdAt: _document!.createdAt,
                creatorName: _creatorName ?? _document!.creator,
                onBack: _handleBackNavigation,
                onRefresh: _loadDocument,
              )
            : null,
        floatingActionButton: _document != null
            ? Builder(
                builder: (buttonContext) => FloatingActionButton.extended(
                  onPressed: () => PDFOptionsDialog.show(
                    context,
                    onOptionSelected: (showApprovalColumn) => _generatePDF(
                        buttonContext,
                        showApprovalColumn: showApprovalColumn),
                  ),
                  backgroundColor: AppColors.error, // Status color
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.picture_as_pdf),
                  elevation: 8,
                  label: const Text('Generate PDF'),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: _isLoading
            ? const LoadingState()
            : _error != null
                ? EmptyState.error(
                    title: 'Error',
                    subtitle: _error,
                    action: ElevatedButton.icon(
                      onPressed: _loadDocument,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  )
                : _document == null
                    ? const EmptyState(
                        icon: Icons.description_outlined,
                        title: 'Dokumen tidak ditemukan',
                        subtitle: 'Pastikan order letter ID valid',
                        iconSize: 64,
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: _buildDocumentContent(),
                      ),
      ),
    );
  }

  // _buildCustomAppBar, _buildInfoItem dipindahkan ke document_widgets

  Widget _buildDocumentContent() {
    if (_document == null) return const SizedBox.shrink();

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
            color: isDark
                ? colorScheme.surface
                : AppColors.surfaceLight, // 30% - Surface
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : AppColors.borderLight), // 30% - Border
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.shadowLight,
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
                      : AppColors.cardLight, // 30% - Card
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                      bottom: BorderSide(
                          color: isDark
                              ? colorScheme.outline.withValues(alpha: 0.2)
                              : AppColors.borderLight)), // 30% - Border
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: isDark
                          ? colorScheme.onSurfaceVariant
                          : AppColors.textSecondaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: AppPadding.p12),
                    Text(
                      'Informasi Customer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? colorScheme.onSurface
                            : AppColors.textPrimaryLight,
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
                    DocumentInfoRow(
                      icon: Icons.business,
                      label: 'Nama Customer',
                      value: document.customerName,
                      iconColor: AppColors.accentLight, // 10% - Accent
                    ),
                    const SizedBox(height: AppPadding.p16),
                    // Phone row
                    DocumentInfoRow(
                      icon: Icons.phone,
                      label: 'Nomor Telepon',
                      value: _getAllPhonesForPDF(),
                      iconColor: AppColors.success, // Status color
                    ),
                    const SizedBox(height: AppPadding.p16),
                    // Address row
                    DocumentInfoRow(
                      icon: Icons.location_on,
                      label: 'Alamat',
                      value: document.address,
                      iconColor: AppColors.warning, // Status color
                      isAddress: true,
                    ),
                    const SizedBox(height: AppPadding.p16),
                    // Showroom / Pameran row
                    DocumentInfoRow(
                      icon: Icons.storefront_outlined,
                      label: 'Showroom / Pameran',
                      value:
                          (document.workPlaceName?.trim().isNotEmpty ?? false)
                              ? document.workPlaceName!.trim()
                              : '-',
                      iconColor: AppColors.purple, // Status color
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
            color: isDark
                ? colorScheme.surface
                : AppColors.surfaceLight, // 30% - Surface
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : AppColors.borderLight), // 30% - Border
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.shadowLight,
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
            color: isDark
                ? colorScheme.surface
                : AppColors.surfaceLight, // 30% - Surface
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : AppColors.borderLight), // 30% - Border
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.shadowLight,
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const TermsSection(),
        ),

        // Approval Section
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surface
                : AppColors.surfaceLight, // 30% - Surface
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : AppColors.borderLight), // 30% - Border
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.shadowLight,
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildApprovalSection(),
        ),
        const SizedBox(height: AppPadding.p20),
      ],
    );
  }

  Widget _buildItemsTable() {
    if (_document == null) return const SizedBox.shrink();

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
          color: isDark
              ? colorScheme.surface
              : AppColors.surfaceLight, // 30% - Surface
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : AppColors.borderLight), // 30% - Border
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
              color: isDark
                  ? colorScheme.onSurfaceVariant
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppPadding.p12),
            Text(
              'Tidak ada detail pesanan',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? colorScheme.onSurfaceVariant
                    : AppColors.textSecondaryLight,
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
        color: isDark
            ? colorScheme.surface
            : AppColors.surfaceLight, // 30% - Surface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight), // 30% - Border
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
                  : AppColors.accentLight
                      .withValues(alpha: 0.1), // 10% dengan opacity
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : AppColors.accentLight
                          .withValues(alpha: 0.2), // 10% dengan opacity
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
                        : AppColors.accentLight
                            .withValues(alpha: 0.2), // 10% dengan opacity
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: isDark
                        ? colorScheme.primary
                        : AppColors.accentLight, // 10% - Accent
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppPadding.p12),
                Text(
                  'DETAIL PESANAN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? colorScheme.onSurface
                        : AppColors.accentLight, // 10% - Accent
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : AppColors.accentLight
                            .withValues(alpha: 0.2), // 10% dengan opacity
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_groupKasurByPackage(details).length} Produk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? colorScheme.primary
                          : AppColors.accentLight, // 10% - Accent
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

  List<_GroupedPackage> _groupKasurByPackage(
      List<OrderLetterDetailModel> details) {
    final List<_GroupedPackage> groups = [];
    final processedIds = <int>{};

    // Helper: Check if item type is accessory
    bool isAccessoryType(String type) {
      final lower = type.toLowerCase();
      return lower == 'divan' || lower == 'headboard' || lower == 'sorong';
    }

    // Helper: Check if item type is main item (kasur or accessory)
    bool isMainItemType(String type) {
      final lower = type.toLowerCase();
      return lower == 'kasur' ||
          lower == 'divan' ||
          lower == 'headboard' ||
          lower == 'sorong';
    }

    // Helper: Find accessories that appear IMMEDIATELY after main item (before any bonus)
    List<OrderLetterDetailModel> findImmediateAccessories(
        OrderLetterDetailModel mainItem) {
      final mainPosition = details.indexWhere((d) => d.id == mainItem.id);
      final List<OrderLetterDetailModel> accessories = [];

      for (int j = mainPosition + 1; j < details.length; j++) {
        final d = details[j];
        final type = d.itemType.toLowerCase();

        // Stop if we hit a bonus or another kasur - accessories must be IMMEDIATELY after
        if (type == 'bonus' || type == 'kasur') break;

        // Only include accessories with matching ukuran and brand
        if (isAccessoryType(type) &&
            !processedIds.contains(d.id) &&
            d.desc2 == mainItem.desc2 &&
            d.brand == mainItem.brand) {
          accessories.add(d);
        }
      }
      return accessories;
    }

    // Helper: Find bonus items after main item and its accessories
    List<OrderLetterDetailModel> findBonusItems(OrderLetterDetailModel mainItem,
        List<OrderLetterDetailModel> accessories) {
      // Find the last position of main item or its accessories
      int lastPosition = details.indexWhere((d) => d.id == mainItem.id);
      for (final acc in accessories) {
        final accPos = details.indexWhere((d) => d.id == acc.id);
        if (accPos > lastPosition) lastPosition = accPos;
      }

      final List<OrderLetterDetailModel> bonusItems = [];
      for (int j = lastPosition + 1; j < details.length; j++) {
        final d = details[j];
        final type = d.itemType.toLowerCase();

        // Stop at next main item (kasur, divan, headboard, sorong)
        if (isMainItemType(type)) break;

        if (type == 'bonus' && !processedIds.contains(d.id)) {
          bonusItems.add(d);
        }
      }
      return bonusItems;
    }

    // Process each detail in order
    for (int i = 0; i < details.length; i++) {
      final item = details[i];
      if (processedIds.contains(item.id)) continue;

      final type = item.itemType.toLowerCase();

      // Skip bonus items - they will be grouped with main items
      if (type == 'bonus') continue;

      // This is a main item (kasur, divan, headboard, or sorong)
      processedIds.add(item.id);

      // Find immediate accessories (only those directly after, before any bonus)
      final accessories = findImmediateAccessories(item);
      for (final acc in accessories) {
        processedIds.add(acc.id);
      }

      // Find bonus items after this group
      final bonusItems = findBonusItems(item, accessories);
      for (final b in bonusItems) {
        processedIds.add(b.id);
      }

      // Create the group
      groups.add(_GroupedPackage(
        kasurDetails: [item],
        accessories: accessories,
        bonus: bonusItems,
        totalQty: item.qty,
      ));
    }

    return groups;
  }

  List<Widget> _buildOrderItemCards(List<OrderLetterDetailModel> details) {
    final List<Widget> cards = [];

    // Group kasur by package (same desc1, desc2, brand, and accessories)
    final groups = _groupKasurByPackage(details);

    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final kasurIndex = i + 1;

      // Use the first kasur as representative (they're all the same)
      final kasurDetail = group.kasurDetails.first;

      // Calculate total qty for each accessory type in the group
      final Map<String, int> accessoryQtyMap = {};
      for (final acc in group.accessories) {
        final key = '${acc.itemType}_${acc.desc1}_${acc.desc2}_${acc.brand}';
        accessoryQtyMap[key] = (accessoryQtyMap[key] ?? 0) + acc.qty;
      }

      // Create accessory list with aggregated qty
      final Map<String, OrderLetterDetailModel> uniqueAccessories = {};
      for (final acc in group.accessories) {
        final key = '${acc.itemType}_${acc.desc1}_${acc.desc2}_${acc.brand}';
        if (!uniqueAccessories.containsKey(key)) {
          uniqueAccessories[key] = acc;
        }
      }

      // Calculate total qty for each bonus type in the group
      final Map<String, int> bonusQtyMap = {};
      for (final b in group.bonus) {
        bonusQtyMap[b.desc1] = (bonusQtyMap[b.desc1] ?? 0) + b.qty;
      }

      // Create bonus list with aggregated qty
      final Map<String, OrderLetterDetailModel> uniqueBonus = {};
      for (final b in group.bonus) {
        if (!uniqueBonus.containsKey(b.desc1)) {
          uniqueBonus[b.desc1] = b;
        }
      }

      cards.add(
        _buildOrderItemCard(
          kasurIndex: kasurIndex,
          kasurDetail: kasurDetail,
          accessories: uniqueAccessories.values.toList(),
          bonus: uniqueBonus.values.toList(),
          totalQty: group.totalQty,
          accessoryQtyMap: accessoryQtyMap,
          bonusQtyMap: bonusQtyMap,
        ),
      );
    }

    return cards;
  }

  Widget _buildOrderItemCard({
    required int kasurIndex,
    required OrderLetterDetailModel kasurDetail,
    required List<OrderLetterDetailModel> accessories,
    required List<OrderLetterDetailModel> bonus,
    int? totalQty,
    Map<String, int>? accessoryQtyMap,
    Map<String, int>? bonusQtyMap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface
            : AppColors.surfaceLight, // 30% - Surface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark
                ? colorScheme.outline.withValues(alpha: 0.2)
                : AppColors.borderLight), // 30% - Border
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
                        : AppColors.accentLight
                            .withValues(alpha: 0.2), // 10% dengan opacity
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$kasurIndex',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? colorScheme.onPrimaryContainer
                          : AppColors.accentLight, // 10% - Accent
                    ),
                  ),
                ),
                const SizedBox(width: AppPadding.p12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark
                      ? colorScheme.primaryContainer
                      : AppColors.accentLight
                          .withValues(alpha: 0.15), // 10% dengan opacity
                  child: Icon(
                    Icons.bed,
                    color: isDark
                        ? colorScheme.onPrimaryContainer
                        : AppColors.accentLight, // 10% - Accent
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppPadding.p12),
                Expanded(
                  child: Text(
                    '${kasurDetail.desc1} ${kasurDetail.desc2}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? colorScheme.onSurface
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : AppColors.cardLight, // 30% - Card
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Qty: ${totalQty ?? kasurDetail.qty}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? colorScheme.onSurfaceVariant
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.p8),

            // Detail Produk Section - Aksesoris selain kasur
            if (accessories.isNotEmpty) ...[
              const SizedBox(height: AppPadding.p6),
              Text(
                'Detail Produk',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? colorScheme.onSurface
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppPadding.p6),
              ...accessories.map((acc) {
                final key =
                    '${acc.itemType}_${acc.desc1}_${acc.desc2}_${acc.brand}';
                final qty = accessoryQtyMap?[key] ?? acc.qty;
                return _buildAccessoryRow(acc, isDark, colorScheme, qty: qty);
              }),
              const SizedBox(height: AppPadding.p8),
            ],

            // Bonus Section
            if (bonus.isNotEmpty) ...[
              const SizedBox(height: AppPadding.p6),
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 18,
                    color: AppColors.success, // Status color
                  ),
                  const SizedBox(width: AppPadding.p8),
                  Text(
                    'Bonus',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? colorScheme.onSurface
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppPadding.p6),
              ...bonus.map((b) {
                final qty = bonusQtyMap?[b.desc1] ?? b.qty;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success, // Status color
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${qty}x',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppPadding.p8),
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
                );
              }),
              const SizedBox(height: AppPadding.p8),
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
        const SizedBox(height: AppPadding.p12),
        // Header for discount section
        Row(
          children: [
            Icon(
              Icons.discount,
              size: 16,
              color: AppColors.warning, // Status color
            ),
            const SizedBox(width: AppPadding.p8),
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
        const SizedBox(height: AppPadding.p6),
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
              color: isDark
                  ? AppColors.cardDark
                  : AppColors.dominantLight, // 30% atau 60% - Background
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
                const SizedBox(width: AppPadding.p8),
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
                        const SizedBox(height: AppPadding.p2),
                        Text(
                          discount.approverName!,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                      if (discount.approvedAt != null) ...[
                        const SizedBox(height: AppPadding.p2),
                        Text(
                          'Approved: ${_formatDate(discount.approvedAt!)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
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
      OrderLetterDetailModel acc, bool isDark, ColorScheme colorScheme,
      {int? qty}) {
    final displayQty = qty ?? acc.qty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getAccessoryIcon(acc.itemType),
            size: 20,
            color: isDark ? colorScheme.onSurfaceVariant : Colors.grey.shade600,
          ),
          const SizedBox(width: AppPadding.p8),
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
            '${displayQty}x',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? colorScheme.onSurfaceVariant
                  : AppColors.textPrimaryLight,
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
    if (_document == null) return const SizedBox.shrink();

    final hargaAwal = _document!.hargaAwal;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final grandTotal = _document!.extendedAmount;
    final totalDiscount = hargaAwal - grandTotal;
    final discountPercentage =
        hargaAwal > 0 ? (totalDiscount / hargaAwal) * 100 : 0.0;

    // Calculate total paid from payments
    final totalPaid = _document!.payments.fold<double>(
      0.0,
      (sum, payment) => sum + payment.paymentAmount,
    );
    final sisaPembayaran = grandTotal - totalPaid;
    final isFullyPaid = sisaPembayaran <= 0;

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
                : AppColors.success
                    .withValues(alpha: 0.1), // Status color dengan opacity
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.2)
                    : AppColors.success
                        .withValues(alpha: 0.3), // Status color dengan opacity
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
                      : AppColors.success.withValues(
                          alpha: 0.2), // Status color dengan opacity
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment_outlined,
                  color: isDark
                      ? colorScheme.primary
                      : AppColors.success, // Status color
                  size: 20,
                ),
              ),
              const SizedBox(width: AppPadding.p12),
              Expanded(
                child: Text(
                  'RINCIAN PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? colorScheme.onSurface
                        : AppColors.success, // Status color
                  ),
                ),
              ),
              // Show add payment button if not fully paid
              if (!isFullyPaid)
                InkWell(
                  onTap: () =>
                      _showAddPaymentDialog(isDark, grandTotal, totalPaid),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : AppColors.primaryLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: isDark
                              ? colorScheme.primary
                              : AppColors.primaryLight,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bayar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? colorScheme.primary
                                : AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
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
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                isSubtotal: true,
              ),
              const SizedBox(height: AppPadding.p8),

              // Diskon (jika ada)
              if (totalDiscount > 0) ...[
                _buildPaymentRow(
                  label: 'Total Diskon',
                  amount:
                      -totalDiscount, // Negative untuk menunjukkan pengurangan
                  color: AppColors.error, // Status color
                  isDiscount: true,
                  percentage: discountPercentage,
                ),
                const SizedBox(height: AppPadding.p12),
                // Divider
                Container(
                  height: 1,
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : AppColors.borderLight, // 30% - Border
                ),
                const SizedBox(height: AppPadding.p12),
              ],

              // Grand Total
              _buildPaymentRow(
                label: 'Total yang Harus Dibayar',
                amount: grandTotal,
                color: AppColors.success, // Status color
                isTotal: true,
              ),

              const SizedBox(height: AppPadding.p12),

              // Divider before payment status
              Container(
                height: 1,
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : AppColors.borderLight,
              ),
              const SizedBox(height: AppPadding.p12),

              // Sudah Dibayar
              _buildPaymentRow(
                label: 'Sudah Dibayar',
                amount: totalPaid,
                color: isDark ? AppColors.accentLight : AppColors.accentLight,
                isPaid: true,
              ),
              const SizedBox(height: AppPadding.p8),

              // Sisa Pembayaran
              _buildPaymentRow(
                label: 'Sisa Pembayaran',
                amount: sisaPembayaran > 0 ? sisaPembayaran : 0,
                color: isFullyPaid ? AppColors.success : AppColors.warning,
                isRemaining: true,
                isFullyPaid: isFullyPaid,
              ),

              const SizedBox(height: AppPadding.p16),

              // Info Box - dynamic based on payment status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primaryContainer
                      : (isFullyPaid
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.3)
                          : (isFullyPaid
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.warning.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFullyPaid
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: isDark
                          ? colorScheme.onPrimaryContainer
                          : (isFullyPaid
                              ? AppColors.success
                              : AppColors.warning),
                      size: 16,
                    ),
                    const SizedBox(width: AppPadding.p8),
                    Expanded(
                      child: Text(
                        isFullyPaid
                            ? 'Pembayaran telah lunas'
                            : 'Masih ada sisa pembayaran ${FormatHelper.formatCurrency(sisaPembayaran)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? colorScheme.onPrimaryContainer
                              : (isFullyPaid
                                  ? AppColors.success
                                  : AppColors.warning),
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
    bool isPaid = false,
    bool isRemaining = false,
    bool isFullyPaid = false,
    double? percentage,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Determine background color
    Color backgroundColor;
    if (isDark) {
      backgroundColor = isTotal || isRemaining
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);
    } else {
      if (isTotal) {
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
      } else if (isPaid) {
        backgroundColor = AppColors.accentLight.withValues(alpha: 0.1);
      } else if (isRemaining) {
        backgroundColor = isFullyPaid
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1);
      } else {
        backgroundColor = AppColors.cardLight;
      }
    }

    // Determine border color
    Color borderColor;
    if (isDark) {
      borderColor = colorScheme.outline.withValues(alpha: 0.2);
    } else {
      if (isTotal) {
        borderColor = AppColors.success.withValues(alpha: 0.3);
      } else if (isPaid) {
        borderColor = AppColors.accentLight.withValues(alpha: 0.3);
      } else if (isRemaining) {
        borderColor = isFullyPaid
            ? AppColors.success.withValues(alpha: 0.3)
            : AppColors.warning.withValues(alpha: 0.3);
      } else {
        borderColor = AppColors.borderLight;
      }
    }

    // Determine icon
    IconData? icon;
    Color? iconColor;
    if (isDiscount) {
      icon = Icons.remove_circle_outline;
      iconColor = AppColors.error;
    } else if (isTotal) {
      icon = Icons.check_circle_outline;
      iconColor = AppColors.success;
    } else if (isPaid) {
      icon = Icons.account_balance_wallet_outlined;
      iconColor = AppColors.accentLight;
    } else if (isRemaining) {
      icon = isFullyPaid ? Icons.check_circle : Icons.schedule;
      iconColor = isFullyPaid ? AppColors.success : AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: (isTotal || isRemaining) ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: AppPadding.p8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: (isTotal || isRemaining) ? 16 : 14,
                      fontWeight: (isTotal || isRemaining)
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isDark ? colorScheme.onSurface : color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (percentage != null && percentage > 0) ...[
                  const SizedBox(width: AppPadding.p8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.error.withValues(
                              alpha: 0.2), // Status color dengan opacity
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error, // Status color
                      ),
                    ),
                  ),
                ],
                // Show "LUNAS" badge if fully paid
                if (isRemaining && isFullyPaid) ...[
                  const SizedBox(width: AppPadding.p8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LUNAS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppPadding.p12),
          Text(
            isDiscount && amount < 0
                ? '- ${FormatHelper.formatCurrency(amount.abs())}'
                : FormatHelper.formatCurrency(amount),
            style: TextStyle(
              fontSize: (isTotal || isRemaining) ? 18 : 14,
              fontWeight:
                  (isTotal || isRemaining) ? FontWeight.bold : FontWeight.w600,
              color: isDark ? colorScheme.onSurface : color,
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to add new payment
  void _showAddPaymentDialog(bool isDark, double grandTotal, double totalPaid) {
    final sisaPembayaran = grandTotal - totalPaid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Controllers
    final amountController = TextEditingController(
      text: FormatHelper.formatCurrency(sisaPembayaran).replaceAll('Rp ', ''),
    );
    final referenceController = TextEditingController();
    final noteController = TextEditingController();

    // State
    String selectedMethod = 'transfer';
    String selectedBank = 'BCA';
    String? receiptImagePath;
    bool isLoading = false;

    // Bank options by method
    final bankOptions = {
      'transfer': ['BCA', 'BRI', 'Mandiri', 'BNI', 'BTN', 'Lainnya'],
      'credit': ['BCA', 'BRI', 'Mandiri', 'BNI', 'CIMB', 'Lainnya'],
      'paylater': ['Kredivo', 'Akulaku', 'Indodana', 'Lainnya'],
      'other': ['QRIS', 'GoPay', 'OVO', 'DANA', 'ShopeePay', 'Lainnya'],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_card,
                        color: AppColors.primaryLight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Pembayaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Sisa: ${FormatHelper.formatCurrency(sisaPembayaran)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Dismiss keyboard when tapping outside input fields
                    FocusScope.of(context).unfocus();
                  },
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Method Selector
                        Text(
                          'Metode Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMethodChip('Transfer Bank', 'transfer',
                                selectedMethod, isDark, (v) {
                              setModalState(() {
                                selectedMethod = v;
                                selectedBank = bankOptions[v]!.first;
                              });
                            }),
                            _buildMethodChip('Kartu Kredit', 'credit',
                                selectedMethod, isDark, (v) {
                              setModalState(() {
                                selectedMethod = v;
                                selectedBank = bankOptions[v]!.first;
                              });
                            }),
                            _buildMethodChip(
                                'PayLater', 'paylater', selectedMethod, isDark,
                                (v) {
                              setModalState(() {
                                selectedMethod = v;
                                selectedBank = bankOptions[v]!.first;
                              });
                            }),
                            _buildMethodChip(
                                'Lainnya', 'other', selectedMethod, isDark,
                                (v) {
                              setModalState(() {
                                selectedMethod = v;
                                selectedBank = bankOptions[v]!.first;
                              });
                            }),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Bank Selector
                        Text(
                          'Bank / Provider',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerHighest
                                : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? colorScheme.outline.withValues(alpha: 0.3)
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedBank,
                              isExpanded: true,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              dropdownColor: isDark
                                  ? colorScheme.surfaceContainerHighest
                                  : AppColors.cardLight,
                              items: bankOptions[selectedMethod]!.map((bank) {
                                return DropdownMenuItem(
                                  value: bank,
                                  child: Text(bank),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() => selectedBank = value!);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Amount Field
                        Text(
                          'Nominal Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            hintText: '0',
                            filled: true,
                            fillColor: isDark
                                ? colorScheme.surfaceContainerHighest
                                : AppColors.cardLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? colorScheme.outline.withValues(alpha: 0.3)
                                    : AppColors.borderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? colorScheme.outline.withValues(alpha: 0.3)
                                    : AppColors.borderLight,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            // Format currency on change
                            final numericValue =
                                value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (numericValue.isNotEmpty) {
                              final formatted = FormatHelper.formatCurrency(
                                      double.parse(numericValue))
                                  .replaceAll('Rp ', '');
                              if (formatted != value) {
                                amountController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                      offset: formatted.length),
                                );
                              }
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        // Reference Field
                        Text(
                          'No. Referensi (Opsional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: referenceController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nomor referensi',
                            filled: true,
                            fillColor: isDark
                                ? colorScheme.surfaceContainerHighest
                                : AppColors.cardLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? colorScheme.outline.withValues(alpha: 0.3)
                                    : AppColors.borderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? colorScheme.outline.withValues(alpha: 0.3)
                                    : AppColors.borderLight,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Note Field
                        Text(
                          'Catatan (Opsional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Tambahkan catatan',
                            filled: true,
                            fillColor: isDark
                                ? colorScheme.surfaceContainerHighest
                                : AppColors.cardLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? colorScheme.outline.withValues(alpha: 0.3)
                                    : AppColors.borderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? colorScheme.outline.withValues(alpha: 0.3)
                                    : AppColors.borderLight,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Receipt Image
                        Text(
                          'Foto Struk Pembayaran *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showImageSourceDialog(
                              context, setModalState, colorScheme, isDark,
                              (path) {
                            setModalState(() => receiptImagePath = path);
                          }),
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? colorScheme.surface
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? colorScheme.outline
                                    : colorScheme.outline,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: receiptImagePath != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(receiptImagePath!),
                                          width: double.infinity,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return _buildImagePlaceholder(
                                                colorScheme, isDark);
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.6),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              setModalState(() =>
                                                  receiptImagePath = null);
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : _buildImagePlaceholder(colorScheme, isDark),
                          ),
                        ),

                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ),

              // Submit Button
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : AppColors.surfaceLight,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading || receiptImagePath == null
                          ? null
                          : () async {
                              // Validate
                              final amountText = amountController.text
                                  .replaceAll(RegExp(r'[^0-9]'), '');
                              if (amountText.isEmpty ||
                                  int.parse(amountText) <= 0) {
                                CustomToast.showToast(
                                  'Masukkan nominal pembayaran yang valid',
                                  ToastType.error,
                                );
                                return;
                              }

                              // Validate maximum (cannot exceed remaining balance)
                              final paymentAmount = double.parse(amountText);
                              if (paymentAmount > sisaPembayaran) {
                                CustomToast.showToast(
                                  'Nominal tidak boleh melebihi sisa pembayaran (${FormatHelper.formatCurrency(sisaPembayaran)})',
                                  ToastType.error,
                                );
                                return;
                              }

                              // Capture navigator before async operation
                              final navigator = Navigator.of(context);

                              setModalState(() => isLoading = true);

                              try {
                                final paymentService =
                                    GetIt.instance<OrderLetterPaymentService>();
                                final userId =
                                    await AuthService.getCurrentUserId();

                                await paymentService.createPayment(
                                  orderLetterId: _document!.id,
                                  paymentMethod: selectedMethod,
                                  paymentBank: selectedBank,
                                  paymentNumber:
                                      referenceController.text.isEmpty
                                          ? '-'
                                          : referenceController.text,
                                  paymentAmount: double.parse(amountText),
                                  creator: userId ?? 0,
                                  note: noteController.text.isEmpty
                                      ? null
                                      : noteController.text,
                                  receiptImagePath: receiptImagePath,
                                  paymentDate: DateTime.now()
                                      .toIso8601String()
                                      .split('T')
                                      .first,
                                );

                                if (mounted) {
                                  navigator.pop();
                                  CustomToast.showToast(
                                    'Pembayaran berhasil ditambahkan',
                                    ToastType.success,
                                  );
                                  // Reload document to refresh payment data
                                  _loadDocument();
                                }
                              } catch (e) {
                                if (mounted) {
                                  CustomToast.showToast(
                                    'Gagal menambahkan pembayaran: $e',
                                    ToastType.error,
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setModalState(() => isLoading = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        disabledBackgroundColor: AppColors.disabledLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Pembayaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodChip(String label, String value, String selected,
      bool isDark, Function(String) onTap) {
    final isSelected = value == selected;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.15)
              : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : (isDark ? Colors.white24 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AppColors.primaryLight
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
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
            color: isDark
                ? colorScheme.surface
                : AppColors.dominantLight, // 60% - Background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : AppColors.borderLight, // 30% - Border
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.approval,
                    color: isDark
                        ? colorScheme.primary
                        : AppColors.accentLight, // 10% - Accent
                    size: 20,
                  ),
                  const SizedBox(width: AppPadding.p8),
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
              const SizedBox(height: AppPadding.p16),
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
                        backgroundColor: AppColors.success, // Status color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppPadding.p12),
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
                        backgroundColor: AppColors.error, // Status color
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

  void _showApprovalDialog(String action) async {
    final isApprove = action == 'approve';
    final title = isApprove ? 'Approve Order' : 'Reject Order';
    final message = isApprove
        ? 'Are you sure you want to approve this order?'
        : 'Are you sure you want to reject this order?';
    final confirmText = isApprove ? 'Approve' : 'Reject';

    // Menggunakan ConfirmationDialog untuk konsistensi UI
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: 'Cancel',
      type: isApprove ? ConfirmationType.success : ConfirmationType.delete,
    );

    if (confirmed == true) {
      _handleApprovalAction(action);
    }
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
    CustomToast.showToast(message, ToastType.error);
  }

  void _showSuccessSnackBar(String message) {
    CustomToast.showToast(message, ToastType.success);
  }

  // _showPDFOptionsDialog dipindahkan ke PDFOptionsDialog widget

  Future<void> _generatePDF(BuildContext buttonContext,
      {required bool showApprovalColumn}) async {
    if (_document == null) return;

    try {
      // Show loading
      CustomToast.showToast('Generating PDF...', ToastType.info);

      // Group order letter details by kasur and create single CartEntity per group
      final cartItems = <CartEntity>[];
      final Map<String, List<Map<String, dynamic>>> pricingSummary = {};

      String pricingKey(String type, String name, String size) =>
          '${type.toLowerCase()}|${name.trim()}|${size.trim()}';

      void addPricing(
        String type,
        String name,
        String size,
        int detailId,
        double unitPrice,
        double customerPrice,
        double netPrice,
        int quantity,
        bool hasExplicitCustomerPrice, {
        String? itemDescription,
      }) {
        final key = pricingKey(type, name, size);
        final list =
            pricingSummary.putIfAbsent(key, () => <Map<String, dynamic>>[]);

        // Helper function to compare doubles with tolerance (for floating point precision)
        bool isDoubleEqual(double a, double b) {
          return (a - b).abs() < 0.01;
        }

        final existingEntry = list.firstWhere(
          (entry) {
            final entryUnitPrice =
                (entry['unit_price_per_unit'] as num).toDouble();
            final entryCustomerPrice =
                (entry['customer_price_per_unit'] as num).toDouble();
            final entryNetPrice =
                (entry['net_price_per_unit'] as num).toDouble();
            final entryHasCustomerPrice = (entry['has_customer_price'] as bool);

            return isDoubleEqual(entryUnitPrice, unitPrice) &&
                isDoubleEqual(entryCustomerPrice, customerPrice) &&
                isDoubleEqual(entryNetPrice, netPrice) &&
                entryHasCustomerPrice == hasExplicitCustomerPrice;
          },
          orElse: () => <String, dynamic>{},
        );

        if (existingEntry.isNotEmpty) {
          // Merge: add quantity to existing entry
          existingEntry['quantity'] =
              (existingEntry['quantity'] as num).toDouble() +
                  quantity.toDouble();
        } else {
          // Add new entry
          list.add({
            'detail_id': detailId,
            'unit_price_per_unit': unitPrice,
            'customer_price_per_unit': customerPrice,
            'net_price_per_unit': netPrice,
            'quantity': quantity.toDouble(),
            'has_customer_price': hasExplicitCustomerPrice,
            if (itemDescription != null && itemDescription.isNotEmpty)
              'item_description': itemDescription,
          });
        }
      }

      // Group kasur by package (same desc1, desc2, brand, and accessories)
      final groups = _groupKasurByPackage(_document!.details);

      for (int i = 0; i < groups.length; i++) {
        final group = groups[i];
        final kasurDetail =
            group.kasurDetails.first; // Use first kasur as representative

        // Initialize product fields
        String kasur = kasurDetail.desc1;
        String divan = '';
        String headboard = '';
        String sorong = '';
        double plKasur = kasurDetail.unitPrice,
            plDivan = 0,
            plHeadboard = 0,
            plSorong = 0;
        double customerKasur =
            kasurDetail.customerPrice ?? kasurDetail.unitPrice;
        double netKasur = kasurDetail.netPrice ??
            kasurDetail.customerPrice ??
            kasurDetail.unitPrice;
        final bool kasurHasExplicitCustomerPrice =
            (kasurDetail.customerPrice != null &&
                kasurDetail.customerPrice! > 0);
        double customerDivan = 0, customerHeadboard = 0, customerSorong = 0;
        double netDivan = 0, netHeadboard = 0, netSorong = 0;

        final bonusItems = <BonusItem>[];

        // Process related items (accessories and bonus) from the group
        // Group accessories by itemType+desc1+desc2+brand to handle duplicates correctly
        final Map<String, Map<String, dynamic>> accessoryGroups = {};
        for (final item in group.accessories) {
          final itemType = item.itemType.toLowerCase();
          if (itemType == 'bonus') continue; // Bonus handled separately

          // Create key: itemType_desc1_desc2_brand (IGNORES item_number)
          final accessoryKey =
              '${itemType}_${item.desc1}_${item.desc2}_${item.brand}';

          if (!accessoryGroups.containsKey(accessoryKey)) {
            accessoryGroups[accessoryKey] = {
              'item': item,
              'total_qty': 0,
            };
          }
          // Sum qty for same accessory
          accessoryGroups[accessoryKey]!['total_qty'] =
              (accessoryGroups[accessoryKey]!['total_qty'] as int) + item.qty;
        }

        // Process each unique accessory group
        for (final entry in accessoryGroups.values) {
          final item = entry['item'] as OrderLetterDetailModel;
          final totalQty = entry['total_qty'] as int;
          final itemType = item.itemType.toLowerCase();

          switch (itemType) {
            case 'divan':
              divan = '${item.desc1} ${item.desc2}'.trim();
              plDivan = item.unitPrice;
              customerDivan = item.customerPrice ?? item.unitPrice;
              netDivan = item.netPrice ?? customerDivan;
              final bool divanHasExplicit =
                  (item.customerPrice != null && item.customerPrice! > 0);
              addPricing(
                item.itemType,
                divan,
                kasurDetail.desc2,
                item.id,
                plDivan,
                customerDivan,
                netDivan,
                totalQty,
                divanHasExplicit,
                itemDescription: item.itemDescription,
              );
              break;
            case 'headboard':
              headboard = '${item.desc1} ${item.desc2}'.trim();
              plHeadboard = item.unitPrice;
              customerHeadboard = item.customerPrice ?? item.unitPrice;
              netHeadboard = item.netPrice ?? customerHeadboard;
              final bool headboardHasExplicit =
                  (item.customerPrice != null && item.customerPrice! > 0);
              addPricing(
                item.itemType,
                headboard,
                kasurDetail.desc2,
                item.id,
                plHeadboard,
                customerHeadboard,
                netHeadboard,
                totalQty,
                headboardHasExplicit,
                itemDescription: item.itemDescription,
              );
              break;
            case 'sorong':
              sorong = '${item.desc1} ${item.desc2}'.trim();
              plSorong = item.unitPrice;
              customerSorong = item.customerPrice ?? item.unitPrice;
              netSorong = item.netPrice ?? customerSorong;
              final bool sorongHasExplicit =
                  (item.customerPrice != null && item.customerPrice! > 0);
              addPricing(
                item.itemType,
                sorong,
                kasurDetail.desc2,
                item.id,
                plSorong,
                customerSorong,
                netSorong,
                totalQty,
                sorongHasExplicit,
                itemDescription: item.itemDescription,
              );
              break;
          }
        }

        // Process bonus items - group by desc1 and sum qty
        final Map<String, Map<String, dynamic>> bonusGroups = {};
        for (final item in group.bonus) {
          final bonusKey = item.desc1;
          if (!bonusGroups.containsKey(bonusKey)) {
            bonusGroups[bonusKey] = {
              'item': item,
              'total_qty': 0,
            };
          }
          // Sum qty for same bonus
          bonusGroups[bonusKey]!['total_qty'] =
              (bonusGroups[bonusKey]!['total_qty'] as int) + item.qty;
        }

        // Add unique bonus items with aggregated qty
        for (final entry in bonusGroups.values) {
          final item = entry['item'] as OrderLetterDetailModel;
          final totalQty = entry['total_qty'] as int;
          bonusItems.add(BonusItem(
            name: item.desc1,
            quantity: totalQty,
            takeAway: item.takeAway ?? false, // Add take away status
          ));
        }

        // Add pricing for kasur (sum all kasur in this group)
        addPricing(
          'kasur',
          kasurDetail.desc1,
          kasurDetail.desc2,
          kasurDetail.id,
          plKasur,
          customerKasur,
          netKasur,
          group.totalQty,
          kasurHasExplicitCustomerPrice,
          itemDescription: kasurDetail.itemDescription,
        );

        cartItems.add(CartEntity(
          cartLineId:
              'doc_${kasurDetail.id}_${i}_${DateTime.now().microsecondsSinceEpoch}',
          product: ProductEntity(
            id: kasurDetail.id,
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
            eupKasur: customerKasur,
            eupDivan: customerDivan,
            eupHeadboard: customerHeadboard,
            eupSorong: customerSorong,
            endUserPrice: netKasur,
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
          quantity: group.totalQty, // Use total qty from group
          netPrice: netKasur,
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
      final discountData = <Map<String, dynamic>>[];
      final Map<int, List<OrderLetterDiscountModel>> discountsByDetailId = {};

      for (final discount in _document!.discounts) {
        discountsByDetailId
            .putIfAbsent(discount.orderLetterDetailId, () => [])
            .add(discount);
      }

      for (final detail in _document!.details) {
        final detailDiscounts = discountsByDetailId[detail.id];
        if (detailDiscounts == null || detailDiscounts.isEmpty) {
          continue;
        }

        final productKey = '${detail.desc1}_${detail.desc2}';
        for (final discount in detailDiscounts) {
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

      // Calculate total paid from payments (sync with backend)
      final totalPaidFromPayments = _document!.payments.fold<double>(
        0.0,
        (sum, payment) => sum + payment.paymentAmount,
      );

      // Get payment method summary for PDF (simplified)
      String paymentMethodDisplay = '-';
      if (_document!.payments.isNotEmpty) {
        if (_document!.payments.length == 1) {
          // Single payment - show method and bank
          final p = _document!.payments.first;
          final bank = p.paymentBank?.isNotEmpty == true ? p.paymentBank! : '';
          paymentMethodDisplay =
              bank.isNotEmpty ? bank : _getPaymentMethodLabel(p.paymentMethod);
        } else {
          // Multiple payments - show count
          paymentMethodDisplay = '${_document!.payments.length}x Pembayaran';
        }
      }

      // Get payment date from payments (use first payment with payment_date, fallback to requestDate)
      String repaymentDate = _formatDate(_document!.requestDate);
      if (_document!.payments.isNotEmpty) {
        final paymentWithDate = _document!.payments.firstWhere(
          (payment) =>
              payment.paymentDate != null && payment.paymentDate!.isNotEmpty,
          orElse: () => _document!.payments.first,
        );
        if (paymentWithDate.paymentDate != null &&
            paymentWithDate.paymentDate!.isNotEmpty) {
          repaymentDate = _formatDate(paymentWithDate.paymentDate!);
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
        paymentMethod: paymentMethodDisplay,
        paymentAmount:
            totalPaidFromPayments, // Use actual paid amount from backend
        repaymentDate: repaymentDate,
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
        pricingData: pricingSummary,
        showApprovalColumn: showApprovalColumn,
        postage: _document!.postage,
        orderLetterCreatedAt: _formatDateTimeWithTime(_document!.createdAt),
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
        CustomToast.showToast(
            'PDF berhasil dibuat dan dibagikan!', ToastType.success);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        CustomToast.showToast('Error: $e', ToastType.error);
      }
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

  String _formatDateTimeWithTime(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      if (date.isUtc) {
        date = date.toLocal();
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  /// Get all phone numbers from contacts as a formatted string for PDF
  String _getAllPhonesForPDF() {
    if (_document?.contacts.isNotEmpty == true) {
      return _document!.contacts.map((contact) => contact.phone).join(', ');
    }
    // Fallback to main phone field if no contacts
    return _document?.phone ?? '-';
  }

  /// Get readable label for payment method
  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'transfer':
        return 'Transfer';
      case 'credit':
        return 'Kartu Kredit';
      case 'paylater':
        return 'PayLater';
      case 'other':
        return 'Lainnya';
      default:
        return method;
    }
  }

  /// Show image source dialog (matching payment_method_dialog)
  void _showImageSourceDialog(
    BuildContext context,
    StateSetter setModalState,
    ColorScheme colorScheme,
    bool isDark,
    Function(String) onImageSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            _buildImageSourceOption(
              context: context,
              colorScheme: colorScheme,
              icon: Icons.camera_alt,
              iconColor: AppColors.success,
              title: 'Ambil Foto',
              subtitle: 'Gunakan kamera untuk mengambil foto struk',
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImage(
                    ImageSource.camera, setModalState, onImageSelected);
              },
            ),
            _buildImageSourceOption(
              context: context,
              colorScheme: colorScheme,
              icon: Icons.photo_library,
              iconColor: colorScheme.primary,
              title: 'Pilih dari Galeri',
              subtitle: 'Pilih foto struk dari galeri',
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImage(
                    ImageSource.gallery, setModalState, onImageSelected);
              },
            ),
            _buildImageSourceOption(
              context: context,
              colorScheme: colorScheme,
              icon: Icons.folder_open,
              iconColor: Colors.orange,
              title: 'Pilih File',
              subtitle: 'Pilih file gambar dari penyimpanan',
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImageFromFile(setModalState, onImageSelected);
              },
            ),
            const SizedBox(height: AppPadding.p20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _pickReceiptImage(
    ImageSource source,
    StateSetter setModalState,
    Function(String) onImageSelected,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        onImageSelected(image.path);
      }
    } catch (e) {
      CustomToast.showToast(
        'Gagal mengambil foto: ${e.toString()}',
        ToastType.error,
      );
    }
  }

  Future<void> _pickReceiptImageFromFile(
    StateSetter setModalState,
    Function(String) onImageSelected,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          onImageSelected(filePath);
        }
      }
    } catch (e) {
      CustomToast.showToast(
        'Gagal memilih file: ${e.toString()}',
        ToastType.error,
      );
    }
  }

  /// Build image placeholder for receipt upload (matching payment_method_dialog)
  Widget _buildImagePlaceholder(ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppPadding.p8),
          Text(
            'Tap untuk ambil foto atau pilih dari galeri',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
