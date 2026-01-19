import 'package:flutter/material.dart';
import '../../../../config/app_constant.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/app_colors.dart';
import '../../../../services/accessories_service.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

/// Dialog untuk menambahkan bonus baru ke cart item
class AddBonusDialog extends StatefulWidget {
  final List<AccessoryEntity> accessories;
  final int productId;
  final double netPrice;
  final String cartLineId;
  final int productQuantity;

  const AddBonusDialog({
    super.key,
    required this.accessories,
    required this.productId,
    required this.netPrice,
    required this.cartLineId,
    required this.productQuantity,
  });

  @override
  State<AddBonusDialog> createState() => _AddBonusDialogState();
}

class _AddBonusDialogState extends State<AddBonusDialog> {
  List<AccessoryEntity> filteredAccessories = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredAccessories = widget.accessories;
    _searchController.addListener(_filterAccessories);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAccessories);
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  void _filterAccessories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredAccessories = widget.accessories;
      } else {
        filteredAccessories = widget.accessories.where((accessory) {
          final itemName = accessory.item.toLowerCase();
          final brand = accessory.brand.toLowerCase();
          final ukuran = accessory.ukuran.toLowerCase();
          return itemName.contains(query) ||
              brand.contains(query) ||
              ukuran.contains(query);
        }).toList();
      }
    });
  }

  /// Calculate max quantity for new bonus (same formula as existing bonuses)
  /// Formula: maxQuantity = originalQuantity * 2 * productQuantity
  /// For new bonus, originalQuantity = 1
  int _calculateMaxQuantity() {
    return 1 * 2 * widget.productQuantity; // Same as BonusItem.calculateMaxQuantity
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxQty = _calculateMaxQuantity();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: isDark ? AppColors.accentDark : AppColors.accentLight,
            size: 24,
          ),
          const SizedBox(width: AppPadding.p8),
          const Expanded(
            child: Text(
              'Tambah Bonus Baru',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info text about max quantity
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.info.withValues(alpha: 0.15)
                    : AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 16,
                  ),
                  const SizedBox(width: AppPadding.p8),
                  Expanded(
                    child: Text(
                      'Bonus akan ditambahkan dengan qty 1 (Max: $maxQty)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.p12),
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari item bonus...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: AppPadding.p12),
            // List of accessories
            Expanded(
              child: filteredAccessories.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada item yang ditemukan',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredAccessories.length + 1, // +1 for Custom
                      itemBuilder: (context, index) {
                        // Custom option as first item
                        if (index == 0) {
                          return _buildCustomOption(context);
                        }

                        // Regular accessory items
                        final accessory = filteredAccessories[index - 1];
                        return _buildAccessoryItem(context, accessory);
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomOption(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.accentDark.withValues(alpha: 0.2)
              : AppColors.accentLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.edit_rounded,
          color: isDark ? AppColors.accentDark : AppColors.accentLight,
          size: 20,
        ),
      ),
      title: const Text(
        'Custom',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        'Masukkan item bonus custom',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
        ),
      ),
      onTap: () => _showCustomBonusDialog(context),
    );
  }

  Widget _buildAccessoryItem(BuildContext context, AccessoryEntity accessory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayText = accessory.ukuran.isNotEmpty
        ? '${accessory.item} (${accessory.ukuran})'
        : accessory.item;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark
              : AppColors.accentLight.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.card_giftcard,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          size: 20,
        ),
      ),
      title: Text(
        displayText,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Brand: ${accessory.brand}',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      onTap: () {
        // Add new bonus with quantity 1
        context.read<CartBloc>().add(AddCartBonus(
              productId: widget.productId,
              netPrice: widget.netPrice,
              bonusName: displayText,
              bonusQuantity: 1, // Start with quantity 1
              cartLineId: widget.cartLineId,
            ));
        Navigator.pop(context);
      },
    );
  }

  void _showCustomBonusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text(
            'Item Bonus Custom',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          content: TextField(
            controller: _customController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Masukkan nama item bonus...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Batal',
                style: TextStyle(fontFamily: 'Inter'),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_customController.text.isNotEmpty) {
                  context.read<CartBloc>().add(AddCartBonus(
                        productId: widget.productId,
                        netPrice: widget.netPrice,
                        bonusName: _customController.text,
                        bonusQuantity: 1, // Start with quantity 1
                        cartLineId: widget.cartLineId,
                      ));
                  Navigator.pop(dialogCtx);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Tambah',
                style: TextStyle(fontFamily: 'Inter'),
              ),
            ),
          ],
        );
      },
    );
  }
}
