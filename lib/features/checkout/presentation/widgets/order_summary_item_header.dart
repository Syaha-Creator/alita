import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/network_image_view.dart';

/// Header row for one order summary item card.
class OrderSummaryItemHeader extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String configText;
  final String kasurSku;
  final int quantity;
  final String totalPriceText;

  const OrderSummaryItemHeader({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.configText,
    required this.kasurSku,
    required this.quantity,
    required this.totalPriceText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: NetworkImageView(
            imageUrl: imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            memCacheWidth: 100,
            errorWidget: Container(
              width: 50,
              height: 50,
              color: AppColors.divider,
              child: const Icon(
                Icons.image_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                configText,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if (kasurSku.isNotEmpty)
                Text(
                  'SKU: $kasurSku',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Qty: $quantity',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          totalPriceText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
        ),
      ],
    );
  }
}
