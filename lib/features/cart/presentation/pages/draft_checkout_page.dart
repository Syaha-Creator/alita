import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../theme/app_colors.dart';

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
    final items = (draft['selectedItems'] as List<dynamic>?)?.length ?? 0;

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
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
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
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        customerPhone.isNotEmpty ? customerPhone : 'No phone',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) async {
                    switch (value) {
                      case 'delete':
                        await _showDeleteConfirmation(index);
                        break;
                      case 'edit':
                        // TODO: Implement edit functionality
                        CustomToast.showToast(
                            'Fitur edit akan segera hadir', ToastType.info);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text('Edit'),
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
                // Order Summary
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Items',
                        '$items produk',
                        Icons.inventory_2_rounded,
                        AppColors.info,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        'Total',
                        'Rp ${FormatHelper.formatNumber(grandTotal)}',
                        Icons.attach_money_rounded,
                        colorScheme.primary,
                        colorScheme,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date Info
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Disimpan: ${FormatHelper.formatSimpleDate(savedAt)}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
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
                  child: _buildActionButton(
                    'WhatsApp',
                    Icons.chat_rounded,
                    AppColors.success,
                    () => _shareToWhatsApp(draft),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
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
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color,
      ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
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
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(int index) async {
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
  }
}
