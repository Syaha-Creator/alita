import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../theme/app_colors.dart';
import 'draft_helper_widgets.dart';

/// Modal for displaying detailed items from a draft
class ItemsDetailModal extends StatelessWidget {
  final Map<String, dynamic> draft;

  const ItemsDetailModal({
    super.key,
    required this.draft,
  });

  /// Show the modal as a bottom sheet
  static Future<void> show(BuildContext context, Map<String, dynamic> draft) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemsDetailModal(draft: draft),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = (draft['selectedItems'] as List<dynamic>?) ?? [];
    final customerName = draft['customerName'] as String? ?? 'Unknown';
    final colorScheme = Theme.of(context).colorScheme;
    final grandTotal = draft['grandTotal'] as double? ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          _buildHandleBar(colorScheme),

          // Header
          _buildHeader(context, colorScheme, customerName),

          // Items List
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return KeyedSubtree(
                  key: ValueKey('item_${item.product.id}_$index'),
                  child: _buildItemCard(context, item, index, colorScheme),
                );
              },
            ),
          ),

          // Summary Footer
          _buildSummaryFooter(context, colorScheme, items.length, grandTotal),
        ],
      ),
    );
  }

  Widget _buildHandleBar(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ColorScheme colorScheme, String customerName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.primary.withValues(alpha: 0.03),
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
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppPadding.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontSize: 20,
                      ),
                ),
                const SizedBox(height: AppPadding.p4),
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppPadding.p6),
                    Text(
                      customerName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(width: AppPadding.p12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
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
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
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
    );
  }

  Widget _buildItemCard(
      BuildContext context, dynamic item, int index, ColorScheme colorScheme) {
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
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Item Header
          _buildItemHeader(colorScheme, kasur, quantity, index),

          // Item Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Specifications
                if (ukuran.isNotEmpty) ...[
                  DraftSpecificationRow(
                    label: 'Ukuran',
                    value: ukuran,
                    icon: Icons.straighten_rounded,
                  ),
                  const SizedBox(height: AppPadding.p8),
                ],
                if (divan.isNotEmpty && divan != 'Tanpa Divan') ...[
                  DraftSpecificationRow(
                    label: 'Divan',
                    value: divan,
                    icon: Icons.chair_rounded,
                  ),
                  const SizedBox(height: AppPadding.p8),
                ],
                if (headboard.isNotEmpty && headboard != 'Tanpa Headboard') ...[
                  DraftSpecificationRow(
                    label: 'Headboard',
                    value: headboard,
                    icon: Icons.headset_rounded,
                  ),
                  const SizedBox(height: AppPadding.p8),
                ],
                if (sorong.isNotEmpty && sorong != 'Tanpa Sorong') ...[
                  DraftSpecificationRow(
                    label: 'Sorong',
                    value: sorong,
                    icon: Icons.drag_handle_rounded,
                  ),
                  const SizedBox(height: AppPadding.p8),
                ],

                // Price Details
                _buildPriceDetails(colorScheme, netPrice, totalPrice),

                // Bonus Items
                if (bonus.isNotEmpty) ...[
                  const SizedBox(height: AppPadding.p12),
                  _buildBonusSection(colorScheme, bonus),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHeader(
      ColorScheme colorScheme, String kasur, int quantity, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.05),
            colorScheme.primary.withValues(alpha: 0.02),
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
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bed_rounded,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: AppPadding.p12),
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
                const SizedBox(height: AppPadding.p2),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
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
    );
  }

  Widget _buildPriceDetails(
      ColorScheme colorScheme, double netPrice, double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DraftPriceRow(
              label: 'Unit Price',
              value: 'Rp ${FormatHelper.formatNumber(netPrice)}',
              icon: Icons.attach_money_rounded,
              color: AppColors.info,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          Expanded(
            child: DraftPriceRow(
              label: 'Total',
              value: 'Rp ${FormatHelper.formatNumber(totalPrice)}',
              icon: Icons.calculate_rounded,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusSection(ColorScheme colorScheme, List<dynamic> bonus) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: colorScheme.secondary,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppPadding.p8),
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
          const SizedBox(height: AppPadding.p8),
          ...bonus.map((bonusItem) {
            final name = bonusItem['name'] as String? ?? '';
            final qty = bonusItem['quantity'] as int? ?? 0;
            return DraftBonusItem(name: name, quantity: qty);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryFooter(BuildContext context, ColorScheme colorScheme,
      int itemCount, double grandTotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: AppColors.info,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: AppPadding.p8),
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
                  const SizedBox(height: AppPadding.p8),
                  Text(
                    '$itemCount items',
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
          const SizedBox(width: AppPadding.p12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.attach_money_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: AppPadding.p8),
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.p8),
                  Text(
                    'Rp ${FormatHelper.formatNumber(grandTotal)}',
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
    );
  }
}

