import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/network_image_view.dart';
import '../../../../core/widgets/price_block.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../data/cart_item.dart';
import '../../logic/cart_provider.dart';
import '../../../pricelist/data/models/product.dart';
import '../../../pricelist/logic/product_display_image_provider.dart';
import '../../../../core/utils/product_image_utils.dart';
import 'cart_foc_voucher_tile.dart';

/// Kartu item keranjang (e-commerce layout: Checkbox → Image → Detail).
/// Detail berisi judul, varian/SKU, baris Harga + Stepper kuantitas, dan rincian Set jika ada.
class CartItemCard extends ConsumerStatefulWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.anchorContext,
    required this.onReturnFromProductDetail,
  });

  final CartItem item;
  final int index;

  /// Halaman di bawah sheet (list/detail); dipakai untuk [GoRouter.push] setelah sheet ditutup.
  final BuildContext anchorContext;

  /// Setelah kembali dari detail produk (refresh snapshot): buka ulang sheet jika perlu.
  final VoidCallback onReturnFromProductDetail;

  @override
  ConsumerState<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<CartItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final index = widget.index;
    final p = item.product;
    final thumbUrl = ref.watch(productDisplayImageProvider(p));
    final thumbAsset = thumbUrl.startsWith(ProductImageUtils.assetUriPrefix);
    final isFoc = item.isFocVoucherActive;
    final hasDiscount =
        !isFoc && p.pricelist > p.price && p.pricelist > 0;
    final tipe = _resolveTypeLabel(p);
    final configText = p.ukuran.isNotEmpty && !p.name.contains(p.ukuran)
        ? '${p.ukuran} • $tipe'
        : tipe;

    final cardRadius = BorderRadius.circular(12);
    Future<void> openDetail() async {
      final anchor = widget.anchorContext;
      final router = GoRouter.of(anchor);
      final extra = <String, dynamic>{
        'product': item.masterProduct ?? p,
        'editItem': item,
        'cartIndex': index,
      };

      Navigator.of(context, rootNavigator: true).pop();
      await Future<void>.delayed(Duration.zero);
      if (!anchor.mounted) return;

      await router.push('/product/${p.id}', extra: extra);
      if (!anchor.mounted) return;
      widget.onReturnFromProductDetail();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: openDetail,
            borderRadius: item.isIndirectSale
                ? const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  )
                : cardRadius,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox.adaptive(
                      value: ref
                          .watch(selectedCartItemIdsProvider)
                          .contains(cartItemKey(item)),
                      onChanged: (v) {
                        ref
                            .read(selectedCartItemIdsProvider.notifier)
                            .toggleSelectItem(cartItemKey(item), v ?? false);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColoredBox(
                      color: AppColors.surfaceLight,
                      child: NetworkImageView(
                        imageUrl: thumbUrl,
                        width: 72,
                        height: 72,
                        fit: thumbAsset ? BoxFit.contain : BoxFit.cover,
                        memCacheWidth: 150,
                        errorWidget: Container(
                          width: 72,
                          height: 72,
                          color: AppColors.surfaceLight,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textTertiary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          configText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${_primarySkuLabel(item)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: PriceBlock(
                                price: isFoc ? 0 : p.price,
                                originalPrice: isFoc
                                    ? (p.pricelist > 0 ? p.pricelist : p.price)
                                    : (hasDiscount ? p.pricelist : null),
                                formatPrice: _formatPrice,
                                priceStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.accent,
                                ),
                                originalPriceStyle: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            QuantityStepper(
                              quantity: item.quantity,
                              onDecrement: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .decrementItem(index);
                              },
                              onIncrement: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .incrementItem(index);
                              },
                              decrementIcon: item.quantity == 1
                                  ? Icons.delete_outline_rounded
                                  : Icons.remove,
                              decrementIconColor: item.quantity == 1
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                            ),
                          ],
                        ),
                        if (_hasVisibleDetails(item)) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            child: Text(
                              _isExpanded
                                  ? 'Tutup Rincian'
                                  : 'Lihat Rincian Item',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildComponentDetails(item),
                            ),
                            crossFadeState: _isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item.isIndirectSale)
            CartFocVoucherBar(
              active: isFoc,
              onChanged: (v) {
                ref.read(cartProvider.notifier).setItemFocVoucher(index, v);
              },
            ),
        ],
      ),
    );
  }

  /// True when there are lines worth showing in the rincian expandable.
  static bool _hasVisibleDetails(CartItem item) {
    final componentCount = _visibleComponentCount(item.product);
    final bonusCount =
        item.bonusSnapshots.where((b) => b.name.trim().isNotEmpty).length;

    // Multiple components → always show details
    if (componentCount > 1) return true;
    // Single component but has bonus → show bonus section
    if (bonusCount > 0) return true;
    return false;
  }

  static int _visibleComponentCount(Product p) {
    bool present(String f) {
      final v = f.trim().toLowerCase();
      return v.isNotEmpty && !v.startsWith('tanpa');
    }

    return [p.kasur, p.divan, p.headboard, p.sorong].where(present).length;
  }

  Widget _buildComponentDetails(CartItem item) {
    final p = item.product;
    const indent = EdgeInsets.only(left: 12);
    const itemStyle = TextStyle(
      fontSize: 10,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    );
    const skuStyle = TextStyle(fontSize: 10, color: AppColors.textTertiary);

    bool present(String f) {
      final v = f.trim().toLowerCase();
      return v.isNotEmpty && !v.startsWith('tanpa');
    }

    String fabricSuffix(String kain, String warna) {
      final k = kain.isNotEmpty && kain != '-' ? kain : '';
      final w = warna.isNotEmpty && warna != '-' ? warna : '';
      if (k.isEmpty && w.isEmpty) return '';
      if (k.isEmpty) return ' ($w)';
      if (w.isEmpty) return ' ($k)';
      return ' ($k - $w)';
    }

    Widget row(String nameText, String sku) => Padding(
          padding: indent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nameText, style: itemStyle),
              Text('SKU: ${sku.isNotEmpty ? sku : "—"}', style: skuStyle),
            ],
          ),
        );

    final componentCount = _visibleComponentCount(p);
    final isSingleComponent = componentCount <= 1;

    final lines = <Widget>[
      // Only show component rows when there are multiple; single component
      // is already represented by the card title + SKU header.
      if (!isSingleComponent) ...[
        if (present(p.kasur)) row('Kasur: ${p.kasur}', item.kasurSku),
        if (present(p.divan))
          row(
            'Divan: ${p.divan}${fabricSuffix(item.divanKain, item.divanWarna)}',
            item.divanSku,
          ),
        if (present(p.headboard))
          row(
            'Sandaran: ${p.headboard}'
            '${fabricSuffix(item.sandaranKain, item.sandaranWarna)}',
            item.sandaranSku,
          ),
        if (present(p.sorong))
          row(
            'Sorong: ${p.sorong}${fabricSuffix(item.sorongKain, item.sorongWarna)}',
            item.sorongSku,
          ),
      ],
      for (final b in item.bonusSnapshots)
        if (b.name.trim().isNotEmpty) row('Item: ${b.name}', b.sku),
    ];

    if (lines.isEmpty) {
      return const Padding(
        padding: indent,
        child: Text('Rincian komponen tidak tersedia.', style: itemStyle),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  /// Builds the primary SKU label for the card header.
  /// Format: `item_number (Jenis Kain - Warna Kain)` or just `item_number`.
  static String _primarySkuLabel(CartItem item) {
    bool present(String f) {
      final v = f.trim().toLowerCase();
      return v.isNotEmpty && !v.startsWith('tanpa');
    }

    String format(String sku, String kain, String warna) {
      if (sku.isEmpty) return item.product.id;
      final k = kain.isNotEmpty && kain != '-' && kain != 'null' ? kain : '';
      final w =
          warna.isNotEmpty && warna != '-' && warna != 'null' ? warna : '';
      if (k.isEmpty && w.isEmpty) return sku;
      if (k.isEmpty) return '$sku ($w)';
      if (w.isEmpty) return '$sku ($k)';
      return '$sku ($k - $w)';
    }

    final p = item.product;
    if (present(p.kasur) && item.kasurSku.isNotEmpty) {
      return item.kasurSku;
    }
    if (present(p.divan) && item.divanSku.isNotEmpty) {
      return format(item.divanSku, item.divanKain, item.divanWarna);
    }
    if (present(p.headboard) && item.sandaranSku.isNotEmpty) {
      return format(item.sandaranSku, item.sandaranKain, item.sandaranWarna);
    }
    if (present(p.sorong) && item.sorongSku.isNotEmpty) {
      return format(item.sorongSku, item.sorongKain, item.sorongWarna);
    }
    return item.product.id;
  }

  static String _resolveTypeLabel(Product p) {
    if (!p.isSet) return 'Kasur Saja';

    bool present(String f) {
      final v = f.trim().toLowerCase();
      return v.isNotEmpty && !v.startsWith('tanpa');
    }

    final parts = <String>[
      if (present(p.kasur)) 'Kasur',
      if (present(p.divan)) 'Divan',
      if (present(p.headboard)) 'Sandaran',
      if (present(p.sorong)) 'Sorong',
    ];
    if (parts.length > 1) return 'Set Lengkap';
    if (parts.length == 1) return '${parts[0]} Saja';
    return 'Kasur Saja';
  }

  String _formatPrice(double value) {
    return AppFormatters.currencyIdr(value);
  }
}
