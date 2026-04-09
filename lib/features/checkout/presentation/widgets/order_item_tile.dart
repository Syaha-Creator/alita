import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../cart/data/cart_item.dart';
import '../../../pricelist/logic/product_display_image_provider.dart';
import 'order_summary_bonus_section.dart';
import 'order_summary_item_header.dart';
import 'order_summary_set_details.dart';

/// Single order item tile inside the checkout Order Summary card.
///
/// Displays item header, set details (divan/headboard/sorong), and optionally
/// bonus section with take-away controls. When [showBonusSection] is false,
/// bonus is rendered once in a combined section below all items.
class OrderItemTile extends ConsumerWidget {
  final CartItem item;
  final String Function(num) priceFmt;
  final bool Function(CartBonusSnapshot) isBonusTakeAwayChecked;
  final int Function(CartBonusSnapshot) currentTakeAwayQty;
  final void Function(CartBonusSnapshot, bool) onTakeAwayToggled;
  final void Function(CartBonusSnapshot, int) onTakeAwayQtyChanged;

  /// When false, only header + set details are shown (bonus shown once below all items).
  final bool showBonusSection;

  const OrderItemTile({
    super.key,
    required this.item,
    required this.priceFmt,
    required this.isBonusTakeAwayChecked,
    required this.currentTakeAwayQty,
    required this.onTakeAwayToggled,
    required this.onTakeAwayQtyChanged,
    this.showBonusSection = true,
  });

  static String _primarySkuLabel(CartItem item) {
    bool present(String f) {
      final v = f.trim().toLowerCase();
      return v.isNotEmpty && !v.startsWith('tanpa');
    }

    String format(String sku, String kain, String warna) {
      if (sku.isEmpty) return '';
      final k = kain.isNotEmpty && kain != '-' && kain != 'null' ? kain : '';
      final w =
          warna.isNotEmpty && warna != '-' && warna != 'null' ? warna : '';
      if (k.isEmpty && w.isEmpty) return sku;
      if (k.isEmpty) return '$sku ($w)';
      if (w.isEmpty) return '$sku ($k)';
      return '$sku ($k - $w)';
    }

    final p = item.product;
    if (present(p.kasur) && item.kasurSku.isNotEmpty) return item.kasurSku;
    if (present(p.divan) && item.divanSku.isNotEmpty) {
      return format(item.divanSku, item.divanKain, item.divanWarna);
    }
    if (present(p.headboard) && item.sandaranSku.isNotEmpty) {
      return format(item.sandaranSku, item.sandaranKain, item.sandaranWarna);
    }
    if (present(p.sorong) && item.sorongSku.isNotEmpty) {
      return format(item.sorongSku, item.sorongKain, item.sorongWarna);
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = item.product;
    final thumbUrl = ref.watch(productDisplayImageProvider(p));
    final hasDivan = p.isSet &&
        p.divan.isNotEmpty &&
        !p.divan.toLowerCase().contains('tanpa');
    final hasHeadboard = p.isSet &&
        p.headboard.isNotEmpty &&
        !p.headboard.toLowerCase().contains('tanpa');
    final hasSorong = p.isSet &&
        p.sorong.isNotEmpty &&
        !p.sorong.toLowerCase().contains('tanpa');

    String bundleTypeLabel() {
      if (!p.isSet) return 'Kasur Saja';

      final hasKasur = p.kasur.trim().isNotEmpty &&
          !p.kasur.trim().toLowerCase().startsWith('tanpa');

      if (hasKasur && hasDivan && hasHeadboard) {
        return hasSorong ? 'Set Lengkap + Sorong' : 'Set Lengkap';
      }

      final selected = <String>[
        if (hasDivan) 'Divan',
        if (hasHeadboard) 'Sandaran',
        if (hasSorong) 'Sorong',
      ];
      if (selected.isEmpty) return hasKasur ? 'Kasur Saja' : 'Produk';
      if (!hasKasur && selected.length == 1) return '${selected[0]} Saja';
      return 'Set ${selected.join(' + ')}';
    }

    final tipe = bundleTypeLabel();
    var configText = p.ukuran.isNotEmpty && !p.name.contains(p.ukuran)
        ? '${p.ukuran} · $tipe'
        : tipe;
    if (item.isFocVoucherActive) {
      configText = '$configText · FOC 100%';
    }

    final hasKasur = p.kasur.trim().isNotEmpty &&
        !p.kasur.trim().toLowerCase().startsWith('tanpa');
    final visibleComponentCount =
        [hasKasur, hasDivan, hasHeadboard, hasSorong].where((v) => v).length;
    final showSetDetails = visibleComponentCount > 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderSummaryItemHeader(
            imageUrl: thumbUrl,
            name: item.displayName,
            configText: configText,
            skuLabel: _primarySkuLabel(item),
            quantity: item.quantity,
            totalPriceText: priceFmt(item.totalPrice),
          ),
          if (showSetDetails) ...[
            OrderSummarySetDetails(
              divanLabel: p.divan,
              divanSku: item.divanSku,
              showDivan: hasDivan,
              headboardLabel: p.headboard,
              headboardSku: item.sandaranSku,
              showHeadboard: hasHeadboard,
              sorongLabel: p.sorong,
              sorongSku: item.sorongSku,
              showSorong: hasSorong,
            ),
          ],
          if (showBonusSection && item.bonusSnapshots.isNotEmpty)
            OrderSummaryBonusSection(
              bonuses: item.bonusSnapshots,
              itemQuantity: item.quantity,
              isChecked: isBonusTakeAwayChecked,
              currentTakeAwayQty: currentTakeAwayQty,
              onCheckedChanged: onTakeAwayToggled,
              onSetTakeAwayQty: onTakeAwayQtyChanged,
            ),
        ],
      ),
    );
  }
}
