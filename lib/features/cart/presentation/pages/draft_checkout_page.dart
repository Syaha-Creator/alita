import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../theme/app_colors.dart';
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
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;

      final key = 'checkout_drafts_$userId';
      final draftStrings = prefs.getStringList(key) ?? [];

      if (index < draftStrings.length) {
        draftStrings.removeAt(index);
        await prefs.setStringList(key, draftStrings);
        await _loadDrafts();
        CustomToast.showToast('Draft berhasil dihapus', ToastType.success);
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
      final items = (draft['selectedItems'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [];

      // Convert items to CartEntity format for PDF generation
      final cartItems = items.map((item) {
        final product = item['product'] as Map<String, dynamic>;
        final quantity = item['quantity'] as int? ?? 1;
        final netPrice = item['netPrice'] as double? ?? 0.0;

        // Create a simple CartEntity-like structure
        return {
          'product': product,
          'quantity': quantity,
          'netPrice': netPrice,
        };
      }).toList();

      // For now, we'll skip PDF generation for drafts and just show a message
      CustomToast.showToast(
          'Fitur PDF untuk draft akan segera hadir', ToastType.info);
    } catch (e) {
      CustomToast.showToast('Gagal membuat PDF: $e', ToastType.error);
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

  // Helper method to get draft status and color
  Map<String, dynamic> _getDraftStatus(Map<String, dynamic> draft) {
    final savedAt = DateTime.parse(draft['savedAt'] as String);
    final now = DateTime.now();
    final difference = now.difference(savedAt);

    if (difference.inDays > 7) {
      return {
        'status': 'Expired',
        'color': AppColors.error,
        'icon': Icons.schedule_rounded,
        'bgColor': AppColors.error.withOpacity(0.1),
      };
    } else if (difference.inDays > 3) {
      return {
        'status': 'Pending',
        'color': AppColors.warning,
        'icon': Icons.pending_rounded,
        'bgColor': AppColors.warning.withOpacity(0.1),
      };
    } else {
      return {
        'status': 'Recent',
        'color': AppColors.success,
        'icon': Icons.check_circle_rounded,
        'bgColor': AppColors.success.withOpacity(0.1),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface),
        ),
        title: Text(
          'Draft Checkout',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDrafts,
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
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
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.description_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Draft',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Draft checkout akan muncul di sini setelah Anda menyimpan pesanan',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return _buildDraftCard(draft, index, colorScheme);
      },
    );
  }

  Widget _buildDraftCard(
      Map<String, dynamic> draft, int index, ColorScheme colorScheme) {
    final customerName = draft['customerName'] as String? ?? 'Unknown';
    final customerPhone = draft['customerPhone'] as String? ?? '';
    final grandTotal = draft['grandTotal'] as double? ?? 0.0;
    final savedAt = DateTime.parse(draft['savedAt'] as String);
    final items = (draft['selectedItems'] as List<dynamic>?) ?? [];
    final status = _getDraftStatus(draft);

    // Get the first item to extract kasur info for title
    String title = customerName;
    if (items.isNotEmpty) {
      final firstItem = items.first as Map<String, dynamic>;
      final product = firstItem['product'] as Map<String, dynamic>?;
      if (product != null) {
        final kasur = product['kasur'] as String? ?? 'Unknown Kasur';
        final ukuran = product['ukuran'] as String? ?? '';
        final isSet = product['isSet'] as bool? ?? false;
        final setStatus = isSet ? 'SET' : 'Tidak SET';
        title = '$customerName - $kasur $ukuran ($setStatus)';
      }
    }

    return Dismissible(
      key: Key('draft_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(index);
      },
      onDismissed: (direction) {
        _deleteDraft(index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: status['color'].withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: status['color'].withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: status['bgColor'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: status['color'],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: status['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      status['icon'],
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customerPhone.isNotEmpty
                                  ? customerPhone
                                  : 'No phone',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: status['color'].withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status['status'],
                                style: TextStyle(
                                  color: status['color'],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Quick Actions Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'checkout':
                          await _continueCheckout(draft);
                          break;
                        case 'delete':
                          await _showDeleteConfirmation(index);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'checkout',
                        child: Row(
                          children: [
                            Icon(Icons.shopping_cart_checkout,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text('Lanjutkan Checkout',
                                style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Order Summary (Clickable)
                  GestureDetector(
                    onTap: () => _showItemsDetail(draft),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildCompactInfoCard(
                              'Items',
                              '${items.length} produk',
                              Icons.inventory_2_rounded,
                              AppColors.info,
                              colorScheme,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                          Expanded(
                            child: _buildCompactInfoCard(
                              'Total',
                              'Rp ${FormatHelper.formatNumber(grandTotal)}',
                              Icons.attach_money_rounded,
                              colorScheme.primary,
                              colorScheme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Date Info with better styling
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Terakhir di edit: ${FormatHelper.formatSimpleDate(savedAt)}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons with improved design
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModernActionButton(
                      'WhatsApp',
                      Icons.chat_rounded,
                      AppColors.success,
                      () => _shareToWhatsApp(draft),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernActionButton(
                      'PDF',
                      Icons.picture_as_pdf_rounded,
                      AppColors.error,
                      () => _sharePDF(draft),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoCard(String label, String value, IconData icon,
      Color color, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Draft'),
        content: Text('Apakah Anda yakin ingin menghapus draft ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteDraft(index);
    }

    return confirmed;
  }

  void _showItemsDetail(Map<String, dynamic> draft) async {
    final items = (draft['selectedItems'] as List<dynamic>?) ?? [];
    final customerName = draft['customerName'] as String? ?? 'Unknown';
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Header with Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.08),
                    colorScheme.primary.withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Items',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    fontSize: 20,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              customerName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Draft',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Items List
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final product = item['product'] as Map<String, dynamic>?;
                  final quantity = item['quantity'] as int? ?? 1;
                  final netPrice = item['netPrice'] as double? ?? 0.0;
                  final totalPrice = netPrice * quantity;

                  if (product == null) return const SizedBox.shrink();

                  final kasur = product['kasur'] as String? ?? '';
                  final ukuran = product['ukuran'] as String? ?? '';
                  final divan = product['divan'] as String? ?? '';
                  final headboard = product['headboard'] as String? ?? '';
                  final sorong = product['sorong'] as String? ?? '';
                  final bonus = (product['bonus'] as List<dynamic>?) ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Item Header with gradient
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.05),
                                colorScheme.primary.withOpacity(0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.bed_rounded,
                                  color: colorScheme.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Item ${index + 1}',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      kasur.isNotEmpty ? kasur : 'Tanpa Kasur',
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.primary.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Qty: $quantity',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Item Details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Specifications
                              if (ukuran.isNotEmpty) ...[
                                _buildSpecificationRow('Ukuran', ukuran,
                                    Icons.straighten_rounded, colorScheme),
                                const SizedBox(height: 8),
                              ],
                              if (divan.isNotEmpty &&
                                  divan != 'Tanpa Divan') ...[
                                _buildSpecificationRow('Divan', divan,
                                    Icons.chair_rounded, colorScheme),
                                const SizedBox(height: 8),
                              ],
                              if (headboard.isNotEmpty &&
                                  headboard != 'Tanpa Headboard') ...[
                                _buildSpecificationRow('Headboard', headboard,
                                    Icons.headset_rounded, colorScheme),
                                const SizedBox(height: 8),
                              ],
                              if (sorong.isNotEmpty &&
                                  sorong != 'Tanpa Sorong') ...[
                                _buildSpecificationRow('Sorong', sorong,
                                    Icons.drag_handle_rounded, colorScheme),
                                const SizedBox(height: 8),
                              ],

                              // Price Details with enhanced styling
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedPriceRow(
                                        'Unit Price',
                                        'Rp ${FormatHelper.formatNumber(netPrice)}',
                                        Icons.attach_money_rounded,
                                        AppColors.info,
                                        colorScheme,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color:
                                          colorScheme.outline.withOpacity(0.2),
                                    ),
                                    Expanded(
                                      child: _buildEnhancedPriceRow(
                                        'Total',
                                        'Rp ${FormatHelper.formatNumber(totalPrice)}',
                                        Icons.calculate_rounded,
                                        colorScheme.primary,
                                        colorScheme,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Enhanced Bonus Items
                              if (bonus.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.secondary.withOpacity(0.1),
                                        colorScheme.secondary.withOpacity(0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.secondary
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondary
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.card_giftcard_rounded,
                                              color: colorScheme.secondary,
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Bonus Items',
                                            style: TextStyle(
                                              color: colorScheme.secondary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...bonus.map((bonusItem) {
                                        final name =
                                            bonusItem['name'] as String? ?? '';
                                        final qty =
                                            bonusItem['quantity'] as int? ?? 0;
                                        if (name.isNotEmpty && qty > 0) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: colorScheme.outline
                                                    .withOpacity(0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  color: colorScheme.secondary,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.onSurface,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.secondary
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    '${qty}x',
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.secondary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Enhanced Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceVariant.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: AppColors.info,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total Items',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${items.length} items',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.attach_money_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total Amount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rp ${FormatHelper.formatNumber(draft['grandTotal'] as double? ?? 0.0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationRow(
      String label, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPriceRow(String label, String value, IconData icon,
      Color color, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
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
      print('Error loading draft for checkout: $e');
    }
  }
}
