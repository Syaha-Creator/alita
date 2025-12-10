import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../core/widgets/styled_container.dart';
import '../../../../../theme/app_colors.dart';
import 'draft_helper_widgets.dart';
import 'items_detail_modal.dart';

/// Card widget for displaying a draft order
class DraftCard extends StatelessWidget {
  final Map<String, dynamic> draft;
  final int index;
  final VoidCallback? onContinueCheckout;
  final VoidCallback? onDelete;
  final VoidCallback? onShareWhatsApp;
  final VoidCallback? onSharePDF;

  const DraftCard({
    super.key,
    required this.draft,
    required this.index,
    this.onContinueCheckout,
    this.onDelete,
    this.onShareWhatsApp,
    this.onSharePDF,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customerName = draft['customerName'] as String? ?? 'Unknown';
    final customerPhone = draft['customerPhone'] as String? ?? '';
    final grandTotal = draft['grandTotal'] as double? ?? 0.0;
    final savedAtString = draft['savedAt'] as String? ?? '';
    final savedAt = savedAtString.isNotEmpty
        ? DateTime.parse(savedAtString)
        : DateTime.now();
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

    // Use savedAt as unique key
    final uniqueKey =
        savedAtString.isNotEmpty ? savedAtString : 'unknown_$index';

    return Dismissible(
      key: Key('draft_$uniqueKey'),
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
        onDelete?.call();
        return false; // Let parent handle the actual deletion
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: status['color'].withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: status['color'].withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Status
            _buildHeader(
                context, colorScheme, status, title, customerPhone),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Order Summary (Clickable)
                  GestureDetector(
                    onTap: () => ItemsDetailModal.show(context, draft),
                    child: StyledContainer.surface(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
                      borderWidth: 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: DraftCompactInfoCard(
                              label: 'Items',
                              value: '${items.length} produk',
                              icon: Icons.inventory_2_rounded,
                              color: AppColors.info,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: DraftCompactInfoCard(
                              label: 'Total',
                              value: 'Rp ${FormatHelper.formatNumber(grandTotal)}',
                              icon: Icons.attach_money_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppPadding.p12),

                  // Date Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppPadding.p8),
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

            // Action Buttons
            _buildActionButtons(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme,
      Map<String, dynamic> status, String title, String customerPhone) {
    return Container(
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
                  color: status['color'].withValues(alpha: 0.3),
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
          const SizedBox(width: AppPadding.p12),
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
                const SizedBox(height: AppPadding.p4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppPadding.p4),
                    Text(
                      customerPhone.isNotEmpty ? customerPhone : 'No phone',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppPadding.p12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status['color'].withValues(alpha: 0.2),
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
            onSelected: (value) {
              switch (value) {
                case 'checkout':
                  onContinueCheckout?.call();
                  break;
                case 'delete':
                  onDelete?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'checkout',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart_checkout,
                        size: 16, color: Colors.green),
                    SizedBox(width: AppPadding.p8),
                    Text('Lanjutkan Checkout',
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                    SizedBox(width: AppPadding.p8),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DraftActionButton(
              label: 'WhatsApp',
              icon: Icons.chat_rounded,
              color: AppColors.success,
              onPressed: () => onShareWhatsApp?.call(),
            ),
          ),
          const SizedBox(width: AppPadding.p12),
          Expanded(
            child: DraftActionButton(
              label: 'PDF',
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.error,
              onPressed: () => onSharePDF?.call(),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDraftStatus(Map<String, dynamic> draft) {
    final items = (draft['selectedItems'] as List<dynamic>?) ?? [];
    final customerName = draft['customerName'] as String? ?? '';
    final grandTotal = draft['grandTotal'] as double? ?? 0.0;

    // Check if draft is complete
    if (items.isNotEmpty && customerName.isNotEmpty && grandTotal > 0) {
      return {
        'status': 'Ready',
        'color': AppColors.success,
        'bgColor': AppColors.success.withValues(alpha: 0.08),
        'icon': Icons.check_circle_rounded,
      };
    }

    // Check if draft has items but missing customer info
    if (items.isNotEmpty) {
      return {
        'status': 'Incomplete',
        'color': AppColors.warning,
        'bgColor': AppColors.warning.withValues(alpha: 0.08),
        'icon': Icons.edit_note_rounded,
      };
    }

    // Draft is empty
    return {
      'status': 'Empty',
      'color': AppColors.info,
      'bgColor': AppColors.info.withValues(alpha: 0.08),
      'icon': Icons.inventory_2_outlined,
    };
  }
}

