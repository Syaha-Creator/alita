import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/network_image_view.dart';
import '../../../../core/widgets/price_block.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../data/cart_item.dart';
import '../../logic/cart_provider.dart';
import '../../../pricelist/presentation/pages/product_detail_page.dart';

/// Kartu item keranjang (e-commerce layout: Checkbox → Image → Detail).
/// Detail berisi judul, varian/SKU, baris Harga + Stepper kuantitas, dan rincian Set jika ada.
class CartItemCard extends ConsumerStatefulWidget {
  const CartItemCard({super.key, required this.item, required this.index});

  final CartItem item;
  final int index;

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
    final hasDiscount = p.pricelist > p.price && p.pricelist > 0;
    final tipe = p.isSet ? 'Set Lengkap' : 'Kasur Saja';
    final configText = p.ukuran.isNotEmpty && !p.name.contains(p.ukuran)
        ? '${p.ukuran} • $tipe'
        : tipe;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => ProductDetailPage(
              product: item.masterProduct ?? p,
              editItem: item,
              cartIndex: index,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: ref
                    .watch(selectedCartItemIdsProvider)
                    .contains(cartItemKey(item)),
                onChanged: (v) {
                  ref
                      .read(selectedCartItemIdsProvider.notifier)
                      .toggleSelectItem(cartItemKey(item), v ?? false);
                },
                activeColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetworkImageView(
                imageUrl: p.imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                memCacheWidth: 150,
                errorWidget: Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF5F5F5),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFFBDBDBD),
                    size: 22,
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
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF424242),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    configText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${p.id}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFBDBDBD),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: PriceBlock(
                          price: p.price,
                          originalPrice: hasDiscount ? p.pricelist : null,
                          formatPrice: _formatPrice,
                          priceStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFFE91E8C),
                          ),
                          originalPriceStyle: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFBDBDBD),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      QuantityStepper(
                        quantity: item.quantity,
                        onDecrement: () {
                          ref.read(cartProvider.notifier).decrementItem(index);
                        },
                        onIncrement: () {
                          ref.read(cartProvider.notifier).incrementItem(index);
                        },
                        decrementIcon: item.quantity == 1
                            ? Icons.delete_outline_rounded
                            : Icons.remove,
                        decrementIconColor: item.quantity == 1
                            ? const Color(0xFFEF5350)
                            : const Color(0xFF424242),
                      ),
                    ],
                  ),
                  if (p.isSet) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(
                        _isExpanded ? 'Tutup Rincian' : 'Lihat Rincian Item',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE91E8C),
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
    );
  }

  Widget _buildComponentDetails(CartItem item) {
    final p = item.product;
    const indent = EdgeInsets.only(left: 12);
    const itemStyle = TextStyle(
      fontSize: 10,
      color: Color(0xFF616161),
      fontWeight: FontWeight.w500,
    );
    const skuStyle = TextStyle(fontSize: 10, color: Color(0xFFBDBDBD));

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

    final lines = <Widget>[
      row('Kasur: ${p.kasur}', item.kasurSku),
      if (p.divan.isNotEmpty && !p.divan.toLowerCase().contains('tanpa'))
        row(
          'Divan: ${p.divan}${fabricSuffix(item.divanKain, item.divanWarna)}',
          item.divanSku,
        ),
      if (p.headboard.isNotEmpty &&
          !p.headboard.toLowerCase().contains('tanpa'))
        row(
          'Sandaran: ${p.headboard}'
          '${fabricSuffix(item.sandaranKain, item.sandaranWarna)}',
          item.sandaranSku,
        ),
      if (p.sorong.isNotEmpty && !p.sorong.toLowerCase().contains('tanpa'))
        row(
          'Sorong: ${p.sorong}${fabricSuffix(item.sorongKain, item.sorongWarna)}',
          item.sorongSku,
        ),
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

  String _formatPrice(double value) {
    return AppFormatters.currencyIdr(value);
  }
}
