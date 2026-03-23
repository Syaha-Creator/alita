import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/platform_utils.dart';

/// Bottom bar di halaman detail produk: tombol favorit + tombol utama (Add to Cart / Simpan Perubahan).
/// Logic (validasi, add to cart) tetap di page via [onAddToCartTap] dan [onFavoriteTap].
class ProductDetailBottomBar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddToCartTap;
  final bool isEditMode;
  final String priceLabel;

  const ProductDetailBottomBar({
    super.key,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onAddToCartTap,
    required this.isEditMode,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final buttonText = isEditMode
        ? 'Simpan Perubahan · $priceLabel'
        : 'Add to Cart · $priceLabel';

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                _FavoriteButton(
                  isFavorite: isFavorite,
                  onTap: onFavoriteTap,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        hapticConfirm();
                        onAddToCartTap();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          buttonText,
                          maxLines: 1,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: isFavorite ? AppColors.accent : AppColors.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
        ),
        color: isFavorite
            ? AppColors.accent
            : AppColors.textSecondary,
        iconSize: 22,
        padding: EdgeInsets.zero,
        onPressed: () {
          hapticTap();
          onTap();
        },
      ),
    );
  }
}
