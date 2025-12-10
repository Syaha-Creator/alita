import 'dart:convert';
import '../../../../config/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/pdf_services.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/cart_entity.dart';
import '../widgets/draft_checkout/draft_checkout_widgets.dart';
import 'checkout_pages.dart';

class DraftCheckoutPage extends StatefulWidget {
  const DraftCheckoutPage({super.key});

  @override
  State<DraftCheckoutPage> createState() => _DraftCheckoutPageState();
}

class _DraftCheckoutPageState extends State<DraftCheckoutPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _drafts = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDrafts();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;

      final key = 'checkout_drafts_$userId';
      final draftStrings = prefs.getStringList(key) ?? [];

      final drafts = draftStrings.map((draftString) {
        final draft = jsonDecode(draftString) as Map<String, dynamic>;
        return draft;
      }).toList();

      // Sort by saved date (newest first)
      drafts.sort((a, b) {
        final dateA = DateTime.parse(a['savedAt'] as String);
        final dateB = DateTime.parse(b['savedAt'] as String);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CustomToast.showToast('Gagal memuat draft: $e', ToastType.error);
    }
  }

  Future<void> _deleteDraft(int index) async {
    try {
      // Get the draft at this index to find its unique identifier
      if (index < 0 || index >= _drafts.length) return;

      final draftToDelete = _drafts[index];
      final savedAt = draftToDelete['savedAt'] as String?;

      if (savedAt == null) {
        CustomToast.showToast(
            'Gagal menghapus draft: Data tidak valid', ToastType.error);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;

      final key = 'checkout_drafts_$userId';
      final draftStrings = prefs.getStringList(key) ?? [];

      // Find and remove draft by savedAt (unique identifier) instead of index
      int foundIndex = -1;
      for (int i = 0; i < draftStrings.length; i++) {
        try {
          final draft = jsonDecode(draftStrings[i]) as Map<String, dynamic>;
          if (draft['savedAt'] == savedAt) {
            foundIndex = i;
            break;
          }
        } catch (e) {
          // Skip invalid draft data
          continue;
        }
      }

      if (foundIndex != -1) {
        draftStrings.removeAt(foundIndex);
        await prefs.setStringList(key, draftStrings);
        await _loadDrafts();
        CustomToast.showToast('Draft berhasil dihapus', ToastType.success);
      } else {
        CustomToast.showToast('Draft tidak ditemukan', ToastType.error);
      }
    } catch (e) {
      CustomToast.showToast('Gagal menghapus draft: $e', ToastType.error);
    }
  }

  Future<void> _shareToWhatsApp(Map<String, dynamic> draft) async {
    try {
      final customerName = draft['customerName'] as String? ?? 'Customer';
      final customerPhone = draft['customerPhone'] as String? ?? '';
      final grandTotal = draft['grandTotal'] as double? ?? 0.0;
      final items = (draft['selectedItems'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [];

      if (customerPhone.isEmpty) {
        CustomToast.showToast(
            'Nomor telepon customer tidak tersedia', ToastType.warning);
        return;
      }

      // Create WhatsApp message
      final message = _createWhatsAppMessage(customerName, items, grandTotal);

      // Launch WhatsApp
      final whatsappUrl =
          'https://wa.me/$customerPhone?text=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        CustomToast.showToast('Tidak dapat membuka WhatsApp', ToastType.error);
      }
    } catch (e) {
      CustomToast.showToast(
          'Gagal membagikan ke WhatsApp: $e', ToastType.error);
    }
  }

  Future<void> _sharePDF(Map<String, dynamic> draft) async {
    try {
      CustomToast.showToast('Generating PDF...', ToastType.info);

      // Convert draft items to CartEntity list
      final cartItems = _convertDraftToCartItems(draft);

      if (cartItems.isEmpty) {
        CustomToast.showToast('Tidak ada item dalam draft', ToastType.warning);
        return;
      }

      final customerName = draft['customerName'] as String? ?? 'Customer';
      final customerAddress = draft['customerAddress'] as String? ?? '';
      final shippingAddress =
          draft['shippingAddress'] as String? ?? customerAddress;
      final customerPhone = draft['customerPhone'] as String? ?? '';
      final deliveryDate = draft['deliveryDate'] as String? ?? '';
      final grandTotal = draft['grandTotal'] as double? ?? 0.0;
      final email = draft['email'] as String? ?? '';
      final notes = draft['notes'] as String? ?? '';
      final spgCode = draft['spgCode'] as String? ?? '';
      final savedAt = draft['savedAt'] as String? ?? '';

      // Get current logged-in user's name for sales name
      final currentUserName = await AuthService.getCurrentUserName() ?? 'Sales';

      // Build pricingData for customer-facing PDF
      // Divan, Headboard, Sorong: Pricelist = actual, Net = 0, Discount = Pricelist
      final Map<String, List<Map<String, dynamic>>> pricingData = {};
      final itemsData = draft['selectedItems'] as List<dynamic>? ?? [];

      String pricingKey(String type, String name, String size) =>
          '${type.toLowerCase()}|${name.trim()}|${size.trim()}';

      for (final itemData in itemsData) {
        final item = itemData as Map<String, dynamic>;
        final productData = item['product'] as Map<String, dynamic>;
        final quantity = item['quantity'] as int? ?? 1;

        final kasur = productData['kasur'] as String? ?? '';
        final divan = productData['divan'] as String? ?? '';
        final headboard = productData['headboard'] as String? ?? '';
        final sorong = productData['sorong'] as String? ?? '';
        final ukuran = productData['ukuran'] as String? ?? '';

        final plDivan = (productData['plDivan'] as num?)?.toDouble() ?? 0.0;
        final plHeadboard =
            (productData['plHeadboard'] as num?)?.toDouble() ?? 0.0;
        final plSorong = (productData['plSorong'] as num?)?.toDouble() ?? 0.0;

        // Divan: pricelist = plDivan, net = 0 (customer sees as free/included)
        if (divan.isNotEmpty && divan != 'Tanpa Divan') {
          final key = pricingKey('divan', divan, ukuran);
          pricingData.putIfAbsent(key, () => []).add({
            'detail_id': 0,
            'unit_price_per_unit': plDivan, // Pricelist
            'customer_price_per_unit':
                plDivan, // Show pricelist as customer price
            'net_price_per_unit': 0.0, // Net = 0 for customer
            'quantity': quantity,
            'has_customer_price': true,
          });
        }

        // Headboard: pricelist = plHeadboard, net = 0
        if (headboard.isNotEmpty && headboard != 'Tanpa Headboard') {
          final key = pricingKey('headboard', headboard, ukuran);
          pricingData.putIfAbsent(key, () => []).add({
            'detail_id': 0,
            'unit_price_per_unit': plHeadboard,
            'customer_price_per_unit': plHeadboard,
            'net_price_per_unit': 0.0,
            'quantity': quantity,
            'has_customer_price': true,
          });
        }

        // Sorong: pricelist = plSorong, net = 0
        if (sorong.isNotEmpty && sorong != 'Tanpa Sorong') {
          final key = pricingKey('sorong', sorong, ukuran);
          pricingData.putIfAbsent(key, () => []).add({
            'detail_id': 0,
            'unit_price_per_unit': plSorong,
            'customer_price_per_unit': plSorong,
            'net_price_per_unit': 0.0,
            'quantity': quantity,
            'has_customer_price': true,
          });
        }

        // Kasur: keep original pricing from cart
        final plKasur = (productData['plKasur'] as num?)?.toDouble() ?? 0.0;
        final netPrice = (item['netPrice'] as num?)?.toDouble() ?? 0.0;
        final key = pricingKey('kasur', kasur, ukuran);
        pricingData.putIfAbsent(key, () => []).add({
          'detail_id': 0,
          'unit_price_per_unit': plKasur,
          'customer_price_per_unit': netPrice, // Customer sees net price
          'net_price_per_unit': netPrice,
          'quantity': quantity,
          'has_customer_price': true,
        });
      }

      // Generate PDF
      final pdfBytes = await PDFService.generateCheckoutPDF(
        cartItems: cartItems,
        customerName: customerName,
        customerAddress: customerAddress,
        shippingAddress: shippingAddress,
        phoneNumber: customerPhone,
        deliveryDate: deliveryDate,
        paymentMethod: 'Draft',
        paymentAmount: 0,
        repaymentDate: '',
        grandTotal: grandTotal,
        email: email.isNotEmpty ? email : null,
        keterangan: notes.isNotEmpty ? notes : null,
        salesName: currentUserName,
        spgCode: spgCode.isNotEmpty ? spgCode : null,
        orderLetterNo:
            'DRAFT-${savedAt.isNotEmpty ? savedAt.substring(0, 10) : DateTime.now().toString().substring(0, 10)}',
        orderLetterStatus: 'DRAFT',
        orderLetterDate: savedAt.isNotEmpty
            ? _formatDateForPDF(savedAt)
            : _formatDateForPDF(DateTime.now().toIso8601String()),
        pricingData: pricingData,
      );

      final fileName = '${customerName}_DRAFT.pdf';

      // Share PDF
      await PDFService.sharePDF(pdfBytes, fileName);

      CustomToast.showToast('PDF berhasil dibuat!', ToastType.success);
    } catch (e) {
      CustomToast.showToast('Gagal membuat PDF: $e', ToastType.error);
    }
  }

  /// Convert draft data to CartEntity list for PDF generation
  List<CartEntity> _convertDraftToCartItems(Map<String, dynamic> draft) {
    final cartItems = <CartEntity>[];
    final itemsData = draft['selectedItems'] as List<dynamic>? ?? [];

    for (int i = 0; i < itemsData.length; i++) {
      try {
        final item = itemsData[i] as Map<String, dynamic>;
        final productData = item['product'] as Map<String, dynamic>;

        // Reconstruct bonus items
        final bonusData = productData['bonus'] as List<dynamic>? ?? [];
        final bonusItems = bonusData.map((bonus) {
          final bonusMap = bonus as Map<String, dynamic>;
          return BonusItem(
            name: bonusMap['name'] as String? ?? '',
            quantity: bonusMap['quantity'] as int? ?? 1,
            originalQuantity: bonusMap['originalQuantity'] as int? ??
                (bonusMap['quantity'] as int? ?? 1),
            takeAway: bonusMap['takeAway'] as bool? ?? false,
          );
        }).toList();

        // Reconstruct product entity with actual values from draft
        // Note: pricingData is used to control what appears in PDF for accessories
        final product = ProductEntity(
          id: productData['id'] as int? ?? 0,
          area: '',
          channel: '',
          brand: productData['brand'] as String? ?? '',
          kasur: productData['kasur'] as String? ?? '',
          divan: productData['divan'] as String? ?? '',
          headboard: productData['headboard'] as String? ?? '',
          sorong: productData['sorong'] as String? ?? '',
          ukuran: productData['ukuran'] as String? ?? '',
          pricelist: (productData['pricelist'] as num?)?.toDouble() ?? 0.0,
          program: '',
          eupKasur: (productData['eupKasur'] as num?)?.toDouble() ?? 0.0,
          eupDivan: (productData['eupDivan'] as num?)?.toDouble() ?? 0.0,
          eupHeadboard:
              (productData['eupHeadboard'] as num?)?.toDouble() ?? 0.0,
          eupSorong: (productData['eupSorong'] as num?)?.toDouble() ?? 0.0,
          endUserPrice: (productData['pricelist'] as num?)?.toDouble() ?? 0.0,
          bonus: bonusItems,
          discounts: [],
          isSet: productData['isSet'] as bool? ?? false,
          plKasur: (productData['plKasur'] as num?)?.toDouble() ?? 0.0,
          plDivan: (productData['plDivan'] as num?)?.toDouble() ?? 0.0,
          plHeadboard: (productData['plHeadboard'] as num?)?.toDouble() ?? 0.0,
          plSorong: (productData['plSorong'] as num?)?.toDouble() ?? 0.0,
          bottomPriceAnalyst: 0,
          disc1: 0,
          disc2: 0,
          disc3: 0,
          disc4: 0,
          disc5: 0,
        );

        // Create CartEntity
        final cartEntity = CartEntity(
          cartLineId: 'draft_${i}_${DateTime.now().microsecondsSinceEpoch}',
          product: product,
          quantity: item['quantity'] as int? ?? 1,
          netPrice: (item['netPrice'] as num?)?.toDouble() ?? 0.0,
          discountPercentages: (item['discountPercentages'] as List<dynamic>?)
                  ?.map((d) => (d as num).toDouble())
                  .toList() ??
              [],
          isSelected: true,
        );

        cartItems.add(cartEntity);
      } catch (e) {
        // Skip invalid item
        continue;
      }
    }

    return cartItems;
  }

  String _formatDateForPDF(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _createWhatsAppMessage(String customerName,
      List<Map<String, dynamic>> items, double grandTotal) {
    final buffer = StringBuffer();

    buffer.writeln('*SURAT PESANAN - DRAFT*');
    buffer.writeln('');
    buffer.writeln('Halo $customerName,');
    buffer.writeln('');
    buffer.writeln('Berikut adalah draft surat pesanan Anda:');
    buffer.writeln('');

    for (final item in items) {
      final product = item['product'] as Map<String, dynamic>;
      final quantity = item['quantity'] as int? ?? 1;
      final netPrice = item['netPrice'] as double? ?? 0.0;
      final total = netPrice * quantity;

      buffer.writeln('• ${product['kasur'] ?? 'Produk'} (${quantity}x)');
      buffer.writeln('  Rp ${FormatHelper.formatNumber(total)}');
      buffer.writeln('');
    }

    buffer.writeln('*Total: Rp ${FormatHelper.formatNumber(grandTotal)}*');
    buffer.writeln('');
    buffer.writeln(
        'Silakan konfirmasi pesanan ini atau hubungi kami untuk informasi lebih lanjut.');
    buffer.writeln('');
    buffer.writeln('Terima kasih!');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: StandardAppBar(
        title: 'Draft Checkout',
        icon: Icons.description_rounded,
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            onPressed: _loadDrafts,
            icon: Icon(
              Icons.refresh_rounded,
              color: theme.brightness == Brightness.dark
                  ? AppColors.textPrimaryDark
                  : Colors.white,
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: _isLoading
                    ? _buildLoadingState(colorScheme)
                    : _drafts.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : _buildDraftsList(colorScheme),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppPadding.p20),
          Text(
            'Memuat Draft...',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    // Menggunakan EmptyState widget untuk konsistensi
    return const EmptyState(
      icon: Icons.description_rounded,
      title: 'Belum Ada Draft',
      subtitle:
          'Draft checkout akan muncul di sini setelah Anda menyimpan pesanan',
    );
  }

  Widget _buildDraftsList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return DraftCard(
          key: ValueKey('draft_${draft['timestamp'] ?? index}_$index'),
          draft: draft,
          index: index,
          onContinueCheckout: () => _continueCheckout(draft),
          onDelete: () => _showDeleteConfirmation(index),
          onShareWhatsApp: () => _shareToWhatsApp(draft),
          onSharePDF: () => _sharePDF(draft),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(int index) async {
    // Menggunakan ConfirmationDialog.showDelete untuk konsistensi UI
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Hapus Draft',
      message: 'Apakah Anda yakin ingin menghapus draft ini?',
    );

    if (confirmed == true) {
      await _deleteDraft(index);
    }

    return confirmed;
  }

  // Continue checkout from draft
  Future<void> _continueCheckout(Map<String, dynamic> draft) async {
    try {
      // Navigate to checkout page with draft data
      // Cart items will be restored in the checkout page initState
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPages.fromDraft(
            draftData: draft,
          ),
        ),
      );
    } catch (e) {
      CustomToast.showToast('Gagal memuat draft: $e', ToastType.error);
      // Error already handled via CustomToast
    }
  }
}
