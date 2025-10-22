import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../theme/app_colors.dart';
import '../../../cart/presentation/widgets/cart_badge.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_state.dart';
import '../widgets/product_action.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final product = state.selectProduct;

        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: const Center(
                child: Text("Produk tidak ditemukan atau belum dipilih.")),
          );
        }

        final netPrice =
            state.roundedPrices[product.id] ?? product.endUserPrice;
        final discountPercentages =
            state.productDiscountsPercentage[product.id] ?? [];
        final editPopupDiscount =
            state.priceChangePercentages[product.id] ?? 0.0;
        final totalDiscount = product.pricelist - netPrice;
        final installmentMonths = state.installmentMonths[product.id];
        final note = state.productNotes[product.id] ?? "";

        final List<String> combinedDiscounts = [];
        final programDiscounts = discountPercentages
            .where((d) => d > 0.0)
            .map((d) =>
                d % 1 == 0 ? "${d.toInt()}%" : "${d.toStringAsFixed(2)}%")
            .toList();
        combinedDiscounts.addAll(programDiscounts);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: _buildCustomAppBar(context, product, isDark),
                automaticallyImplyLeading: false,
                toolbarHeight: ResponsiveHelper.getAppBarHeight(context) + 20,
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildPriceCard(context, product, netPrice, totalDiscount,
                        combinedDiscounts, installmentMonths, isDark),
                    _buildDetailCard(context, product, isDark),
                    _buildBonusAndNotesCard(context, product, note, isDark),
                    const SizedBox(height: 75),
                  ],
                ),
              ),
            ],
          ),
          bottomSheet:
              _buildAdaptiveBottomSheet(context, product, state, isDark),
        );
      },
    );
  }

  /// Build custom AppBar with centered product name
  Widget _buildCustomAppBar(
      BuildContext context, ProductEntity product, bool isDark) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        height: ResponsiveHelper.getAppBarHeight(context) + 20,
        padding: ResponsiveHelper.getAppBarPadding(context),
        child: Row(
          children: [
            // Back button (fixed width)
            Container(
              width: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 40,
                tablet: 44,
                desktop: 48,
              ),
              height: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 40,
                tablet: 44,
                desktop: 48,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  size: ResponsiveHelper.getResponsiveIconSize(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Kembali',
              ),
            ),

            // Expanded center section for product name with proper spacing
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(
                    context,
                    mobile: 8,
                    tablet: 10,
                    desktop: 12,
                  ),
                ),
                child: Center(
                  child: _buildProductNameSection(context, product, isDark),
                ),
              ),
            ),

            // Action bubbles (fixed width)
            _buildActionBubbles(context, product, isDark),
          ],
        ),
      ),
    );
  }

  /// Build product name and size section in AppBar with adaptive sizing
  Widget _buildProductNameSection(
      BuildContext context, ProductEntity product, bool isDark) {
    final theme = Theme.of(context);
    final productName = product.kasur;
    final productSize = product.ukuran;
    final fullText = '$productName ($productSize)';

    // Calculate adaptive dimensions and font sizes
    final adaptiveConfig =
        _calculateAdaptiveTextConfig(productName, productSize, fullText);

    return Container(
      width: adaptiveConfig['bubbleWidth'],
      height: adaptiveConfig['bubbleHeight'],
      padding: EdgeInsets.symmetric(
          horizontal: adaptiveConfig['horizontalPadding'],
          vertical: adaptiveConfig['verticalPadding']),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: adaptiveConfig['useTwoLines']
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Product name (separate line for long text)
                  Text(
                    productName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      fontSize: adaptiveConfig['nameFontSize'],
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  // Product size (separate line)
                  if (productSize.isNotEmpty)
                    Text(
                      '($productSize)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withOpacity(0.8),
                        fontSize: adaptiveConfig['sizeFontSize'],
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              )
            : Text(
                // Short text: single line
                fullText,
                style: theme.textTheme.titleLarge?.copyWith(
                  color:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  fontSize: adaptiveConfig['nameFontSize'],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  /// Build action bubbles (cart and share)
  Widget _buildActionBubbles(
      BuildContext context, ProductEntity product, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cart bubble
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CartBadge(
              onTap: () {
                context.push(RoutePaths.cart);
              },
              child: Icon(
                Icons.shopping_cart_outlined,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Share bubble
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Builder(
              builder: (buttonContext) => IconButton(
                icon: Icon(
                  Icons.share_rounded,
                  color:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  size: 20,
                ),
                onPressed: () => ProductActions.showSharePopupWithPosition(
                  context,
                  product,
                  buttonContext,
                ),
                tooltip: 'Bagikan Produk',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build adaptive bottom sheet that respects device navigation
  Widget _buildAdaptiveBottomSheet(BuildContext context, ProductEntity product,
      ProductState state, bool isDark) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final viewInsets = mediaQuery.viewInsets.bottom;

    // Detect if device has gesture navigation (home indicator)
    final hasGestureNavigation = bottomPadding > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        // Smart bottom padding based on navigation type
        bottom: hasGestureNavigation
            ? bottomPadding + 8 // ✅ Above gesture navigation
            : 16, // ✅ Standard padding for button navigation
      ),
      child: _buildActionButtons(context, product, state, isDark),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProductEntity product,
      ProductState state, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side action bubbles
        Row(
          children: [
            _buildActionBubble(
              context,
              Icons.credit_card,
              "Credit",
              () => ProductActions.showCreditPopup(context, product),
              isDark,
            ),
            const SizedBox(width: 12),
            _buildActionBubble(
              context,
              Icons.edit,
              "Edit",
              () => ProductActions.showEditPopup(context, product),
              isDark,
            ),
            const SizedBox(width: 12),
            _buildActionBubble(
              context,
              Icons.info_outline,
              "Info",
              () => ProductActions.showInfoPopup(context, product),
              isDark,
            ),
          ],
        ),
        // Right side - Add to Cart bubble
        _buildAddToCartBubble(context, product, isDark),
      ],
    );
  }

  Widget _buildPriceCard(
      BuildContext context,
      ProductEntity product,
      double netPrice,
      double totalDiscount,
      List<String> combinedDiscounts,
      int? installmentMonths,
      bool isDark) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Penting untuk scrolling
          children: [
            Text(
              "Rincian Harga",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
            ),
            const Divider(height: 18),
            _buildPriceRow(
              context,
              "Pricelist",
              FormatHelper.formatCurrency(product.pricelist),
              isStrikethrough: true,
              valueColor: AppColors.primaryLight,
              isDark: isDark,
            ),
            _buildPriceRow(
              context,
              "Program",
              product.program.isNotEmpty ? product.program : "Tidak ada promo",
              isDark: isDark,
            ),
            if (combinedDiscounts.isNotEmpty)
              _buildPriceRow(
                context,
                "Diskon Tambahan",
                combinedDiscounts.join(' + '),
                valueColor: AppColors.info,
                isDark: isDark,
              ),
            _buildPriceRow(
              context,
              "Total Diskon",
              "- ${FormatHelper.formatCurrency(totalDiscount)}",
              valueColor: AppColors.error,
              isDark: isDark,
            ),
            const Divider(height: 18, thickness: 1.5),
            _buildPriceRow(
              context,
              "Harga Net",
              FormatHelper.formatCurrency(netPrice),
              isBold: true,
              valueSize: 20,
              valueColor: AppColors.success,
              isDark: isDark,
            ),
            if (installmentMonths != null && installmentMonths > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Center(
                  child: Text(
                    "Cicilan: ${FormatHelper.formatCurrency(netPrice / installmentMonths)} x $installmentMonths bulan",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.accentDark : AppColors.info,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
      BuildContext context, ProductEntity product, bool isDark) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Spesifikasi Set",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
            ),
            const Divider(height: 24),
            _buildSpecRow(
                context, Icons.king_bed, "Tipe Kasur", product.kasur, isDark),
            if (product.divan.isNotEmpty && product.divan != AppStrings.noDivan)
              _buildSpecRow(
                  context, Icons.layers, "Tipe Divan", product.divan, isDark),
            if (product.headboard.isNotEmpty &&
                product.headboard != AppStrings.noHeadboard)
              _buildSpecRow(context, Icons.view_headline, "Tipe Headboard",
                  product.headboard, isDark),
            if (product.sorong.isNotEmpty &&
                product.sorong != AppStrings.noSorong)
              _buildSpecRow(context, Icons.arrow_downward, "Tipe Sorong",
                  product.sorong, isDark),
            _buildSpecRow(
                context, Icons.straighten, "Ukuran", product.ukuran, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusAndNotesCard(
      BuildContext context, ProductEntity product, String note, bool isDark) {
    final theme = Theme.of(context);
    final hasBonus =
        product.bonus.isNotEmpty && product.bonus.any((b) => b.name.isNotEmpty);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Bonus & Catatan",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
            ),
            const Divider(height: 24),
            Text(
              "Complimentary:",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
            ),
            const SizedBox(height: 8),
            if (hasBonus)
              ...product.bonus.where((b) => b.name.isNotEmpty).map(
                    (bonus) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Text(
                        "• ${bonus.quantity}x ${bonus.name}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                    ),
                  )
            else
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Tidak ada bonus.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            isDark ? AppColors.textSecondaryDark : Colors.grey,
                      ),
                ),
              ),
            if (note.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                "Catatan:",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(
                  note,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String title, String value,
      {Color? valueColor,
      bool isStrikethrough = false,
      bool isBold = false,
      double valueSize = 16,
      bool isDark = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: valueSize,
                    color: valueColor,
                    decoration:
                        isStrikethrough ? TextDecoration.lineThrough : null,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(BuildContext context, IconData icon, String title,
      String value, bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? AppColors.accentDark : AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            "$title:",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
          ),
          const Spacer(),
          Text(
            value.isNotEmpty ? value : "-",
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }

  /// Build action bubble with consistent AppBar styling
  Widget _buildActionBubble(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    bool isDark,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          size: 20,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  /// Build Add to Cart bubble with primary styling
  Widget _buildAddToCartBubble(
    BuildContext context,
    ProductEntity product,
    bool isDark,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _addToCart(context, product),
        icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
        label: Text(
          'Add to Cart',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, ProductEntity product) async {
    try {
      // Get current product state for discounts and net price
      final productState = context.read<ProductBloc>().state;
      final discountPercentages =
          productState.productDiscountsPercentage[product.id] ?? [];
      final netPrice =
          productState.roundedPrices[product.id] ?? product.endUserPrice;
      final installmentMonths = productState.installmentMonths[product.id];

      // Add to cart using CartBloc directly, hanya gunakan discountPercentages
      context.read<CartBloc>().add(AddToCart(
            product: product,
            quantity: 1,
            netPrice: netPrice,
            discountPercentages: discountPercentages,
            installmentMonths: installmentMonths,
          ));

      CustomToast.showToast(
          'Product added to cart successfully', ToastType.success);
    } catch (e) {
      CustomToast.showToast('Error adding to cart: $e', ToastType.error);
    }
  }

  /// Calculate adaptive text configuration based on content length
  Map<String, dynamic> _calculateAdaptiveTextConfig(
      String productName, String productSize, String fullText) {
    final nameLength = productName.length;
    final sizeLength = productSize.length;
    final fullLength = fullText.length;

    // Determine if we need two lines
    bool useTwoLines = fullLength > 22 || nameLength > 18;

    // Calculate bubble dimensions based on precise content fitting
    double bubbleWidth;
    double bubbleHeight;
    double nameFontSize;
    double sizeFontSize;
    double horizontalPadding = 12.0;
    double verticalPadding;

    if (useTwoLines) {
      // Two-line layout - calculate based on longest line
      bubbleHeight = 52.0;
      verticalPadding = 6.0;

      final maxLineLength = nameLength > (sizeLength + 2)
          ? nameLength
          : (sizeLength + 2); // +2 for parentheses

      // Precise width calculation: character width * font size + padding
      if (maxLineLength <= 12) {
        nameFontSize = 16.0;
        sizeFontSize = 12.0;
        bubbleWidth = (maxLineLength * 9.0) +
            (horizontalPadding * 2); // ~9px per char at 16px font
      } else if (maxLineLength <= 16) {
        nameFontSize = 15.0;
        sizeFontSize = 11.0;
        bubbleWidth = (maxLineLength * 8.5) +
            (horizontalPadding * 2); // ~8.5px per char at 15px font
      } else if (maxLineLength <= 20) {
        nameFontSize = 14.0;
        sizeFontSize = 10.0;
        bubbleWidth = (maxLineLength * 8.0) +
            (horizontalPadding * 2); // ~8px per char at 14px font
      } else if (maxLineLength <= 25) {
        nameFontSize = 13.0;
        sizeFontSize = 9.0;
        bubbleWidth = (maxLineLength * 7.5) +
            (horizontalPadding * 2); // ~7.5px per char at 13px font
      } else {
        // Very long text
        nameFontSize = 12.0;
        sizeFontSize = 8.0;
        bubbleWidth = (maxLineLength * 7.0) +
            (horizontalPadding * 2); // ~7px per char at 12px font
      }
    } else {
      // Single-line layout - calculate based on full text
      bubbleHeight = 40.0;
      verticalPadding = 8.0;

      // Precise width calculation for single line
      if (fullLength <= 10) {
        nameFontSize = 16.0;
        bubbleWidth = (fullLength * 9.0) + (horizontalPadding * 2);
      } else if (fullLength <= 15) {
        nameFontSize = 15.0;
        bubbleWidth = (fullLength * 8.5) + (horizontalPadding * 2);
      } else if (fullLength <= 20) {
        nameFontSize = 14.0;
        bubbleWidth = (fullLength * 8.0) + (horizontalPadding * 2);
      } else {
        nameFontSize = 13.0;
        bubbleWidth = (fullLength * 7.5) + (horizontalPadding * 2);
      }

      sizeFontSize = nameFontSize; // Same as name for single line
    }

    // Ensure minimum and maximum constraints
    bubbleWidth = bubbleWidth.clamp(120.0, 320.0);
    nameFontSize = nameFontSize.clamp(11.0, 16.0);
    sizeFontSize = sizeFontSize.clamp(9.0, 13.0);

    return {
      'useTwoLines': useTwoLines,
      'bubbleWidth': bubbleWidth,
      'bubbleHeight': bubbleHeight,
      'nameFontSize': nameFontSize,
      'sizeFontSize': sizeFontSize,
      'horizontalPadding': horizontalPadding,
      'verticalPadding': verticalPadding,
    };
  }
}
