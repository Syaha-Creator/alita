import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/cart_entity.dart';

/// Widget untuk menampilkan fabric selector per component di cart item
class FabricSelector extends StatelessWidget {
  final CartEntity item;
  final bool isDark;
  final String itemType;
  final void Function(String itemType, int unitIndex) onOpenFabricSelector;

  const FabricSelector({
    super.key,
    required this.item,
    required this.isDark,
    required this.itemType,
    required this.onOpenFabricSelector,
  });

  String _buildLabel(Map<String, String>? sel) {
    if (sel == null) return 'Pilih kain';
    final jk = (sel['jenis_kain'] ?? '').trim();
    final wk = (sel['warna_kain'] ?? '').trim();
    final combined = [jk, wk].where((e) => e.isNotEmpty).join(' - ');
    return combined.isEmpty ? (sel['item_number'] ?? 'Pilih kain') : combined;
  }

  @override
  Widget build(BuildContext context) {
    final qty = item.quantity;
    final perUnit = item.selectedItemNumbersPerUnit?[itemType];
    final selLegacy = item.selectedItemNumbers?[itemType];

    final children = <Widget>[];
    
    // Header line
    children.add(Row(
      children: [
        Expanded(
          child: Text(
            'Kain ${itemType[0].toUpperCase()}${itemType.substring(1)}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
        // For qty==1, keep single selector; for qty>1, show Unit #1 here
        TextButton(
          onPressed: () => onOpenFabricSelector(itemType, 0),
          child: Text(
            _buildLabel((perUnit != null && perUnit.isNotEmpty)
                ? perUnit[0]
                : selLegacy),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDark ? AppColors.accentDark : AppColors.accentLight,
            ),
          ),
        )
      ],
    ));

    // If more than 1 quantity, show selectors per additional unit
    if (qty > 1) {
      for (int i = 1; i < qty; i++) {
        final label = _buildLabel(
            (perUnit != null && i < perUnit.length) ? perUnit[i] : null);
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Unit #${i + 1}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => onOpenFabricSelector(itemType, i),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark ? AppColors.accentDark : AppColors.accentLight,
                  ),
                ),
              )
            ],
          ),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

