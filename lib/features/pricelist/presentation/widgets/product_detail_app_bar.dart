import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/widgets/floating_badge.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../../cart/presentation/widgets/cart_bottom_sheet.dart';
import 'product_anchor_type.dart';

/// AppBar for [ProductDetailPage], extracted as a standalone ConsumerWidget
/// to reduce file size. All parameters are forwarded 1:1 — no behavioral change.
class ProductDetailAppBar extends ConsumerWidget {
  const ProductDetailAppBar({
    super.key,
    required this.productName,
    required this.effectiveSize,
    required this.isKasurOnly,
    required this.isScrolled,
    required this.buildAnchor,
    required this.divanHasSet,
    required this.isSharing,
    required this.sharingProvider,
    required this.onShareTap,
    required this.onBackTap,
  });

  final String productName;
  final String effectiveSize;
  final bool isKasurOnly;
  final bool isScrolled;
  final AnchorType buildAnchor;
  final bool divanHasSet;
  final bool isSharing;
  final AutoDisposeStateProvider<bool> sharingProvider;
  final VoidCallback onShareTap;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final cartCount = ref.watch(cartTotalItemsProvider);

    return AppBar(
      backgroundColor: isScrolled ? AppColors.background : Colors.transparent,
      elevation: isScrolled ? 2 : 0,
      scrolledUnderElevation: isScrolled ? 2 : 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: isScrolled
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: onBackTap,
            ),
          ),
        ),
      ),
      centerTitle: false,
      title: AnimatedOpacity(
        opacity: isScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              (buildAnchor == AnchorType.kasur ||
                      (buildAnchor == AnchorType.divan && divanHasSet))
                  ? '$effectiveSize • ${isKasurOnly ? 'Satuan' : 'Set Lengkap'}'
                  : effectiveSize,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isScrolled
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: ref.watch(sharingProvider)
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: isOffline
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    size: 22,
                  ),
                  tooltip: isOffline ? 'Membutuhkan internet' : null,
                  onPressed: () {
                    if (ifOfflineShowFeedback(context,
                        isOffline: isOffline)) {
                      return;
                    }
                    onShareTap();
                  },
                ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isScrolled
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                onPressed: () {
                  showCartSheet(context);
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.surface, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: FloatingBadge(
                      count: cartCount,
                      maxCount: 9,
                      padding: const EdgeInsets.all(4),
                      backgroundColor: AppColors.error,
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      textStyle: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
