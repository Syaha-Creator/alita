import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable price presentation for product and cart contexts.
///
/// Function:
/// - Menampilkan harga utama (`price`) sebagai nilai final.
/// - Menampilkan harga coret (`originalPrice`) hanya jika nilainya lebih besar.
/// - Menjaga konsistensi style harga di berbagai fitur tanpa deklarasi ulang.
class PriceBlock extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final String Function(double value) formatPrice;
  final TextStyle? priceStyle;
  final TextStyle? originalPriceStyle;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const PriceBlock({
    super.key,
    required this.price,
    required this.formatPrice,
    this.originalPrice,
    this.priceStyle,
    this.originalPriceStyle,
    this.spacing = 2,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final orig = originalPrice;
    final showOriginal = orig != null && orig > price;

    return Semantics(
      label: showOriginal
          ? 'Harga ${formatPrice(price)}, sebelumnya ${formatPrice(orig)}'
          : 'Harga ${formatPrice(price)}',
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (showOriginal)
            Text(
              formatPrice(orig),
              style:
                  originalPriceStyle ??
                  const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    decoration: TextDecoration.lineThrough,
                  ),
            ),
          if (showOriginal) SizedBox(height: spacing),
          Text(formatPrice(price), style: priceStyle),
        ],
      ),
    );
  }
}
