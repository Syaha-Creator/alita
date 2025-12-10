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
import '../widgets/product_detail/product_detail_widgets.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
        final totalDiscount = product.pricelist - netPrice;
        final installmentMonths = state.installmentMonths[product.id];

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
                    // Compact Hero Section (1 line)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildCompactHero(product, isDark),
                      ),
                    ),

                    // Price Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: PriceCard(
                          product: product,
                          netPrice: netPrice,
                          totalDiscount: totalDiscount,
                          combinedDiscounts: combinedDiscounts,
                          installmentMonths: installmentMonths,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // Specification Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child:
                            SpecificationCard(product: product, isDark: isDark),
                      ),
                    ),

                    // Bonus Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: BonusCard(product: product, isDark: isDark),
                      ),
                    ),

                    const SizedBox(height: AppPadding.p100),
                  ],
                ),
              ),
            ],
          ),
          bottomSheet: _buildAdaptiveBottomSheet(
              context, product, state, netPrice, isDark),
        );
      },
    );
  }

  /// Compact hero section - single line with brand info
  Widget _buildCompactHero(ProductEntity product, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? AppColors.primaryDark.withValues(alpha: 0.12)
            : AppColors.primaryLight.withValues(alpha: 0.08),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.2)
              : AppColors.primaryLight.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Left: Brand with logo (flexible to handle long names)
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getBrandLogo(product.brand),
                const SizedBox(width: AppPadding.p6),
                Flexible(
                  child: Text(
                    product.brand.toUpperCase(),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppPadding.p8),
          // Center: Channel with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                size: 14,
              ),
              const SizedBox(width: AppPadding.p4),
              Text(
                product.channel,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppPadding.p8),
          // Right: Area with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                size: 14,
              ),
              const SizedBox(width: AppPadding.p4),
              Text(
                product.area,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get brand logo from assets
  Widget _getBrandLogo(String brand) {
    final lower = brand.toLowerCase();
    String? logoPath;

    if (lower.contains('comforta')) {
      logoPath = 'assets/logo/comforta_logo.png';
    } else if (lower.contains('isleep') || lower.contains('i-sleep')) {
      logoPath = 'assets/logo/isleep_logo.png';
    } else if (lower.contains('sleepcenter') ||
        lower.contains('sleep center')) {
      logoPath = 'assets/logo/sleepcenter_logo.png';
    } else if (lower.contains('sleepspa') || lower.contains('sleep spa')) {
      logoPath = 'assets/logo/sleepspa_logo.png';
    } else if (lower.contains('springair') || lower.contains('spring air')) {
      logoPath = 'assets/logo/springair_logo.png';
    } else if (lower.contains('superfit') || lower.contains('super fit')) {
      logoPath = 'assets/logo/superfit_logo.png';
    } else if (lower.contains('therapedic')) {
      logoPath = 'assets/logo/therapedic_logo.png';
    }

    if (logoPath != null) {
      return Image.asset(
        logoPath,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.hotel_rounded, size: 16);
        },
      );
    }

    // Default icon if no logo found
    return const Icon(Icons.hotel_rounded, size: 16);
  }

  /// Build custom AppBar with centered product name
  Widget _buildCustomAppBar(
      BuildContext context, ProductEntity product, bool isDark) {
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
                color: isDark ? AppColors.cardDark : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
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

  /// Get display name with fallback: Kasur → Divan → Headboard → Sorong
  String _getProductDisplayName(ProductEntity product) {
    // Helper to check if value is valid for display
    bool isValid(String value) {
      if (value.isEmpty) return false;
      if (value.trim() == '-') return false;
      if (value.trim().toLowerCase().startsWith('tanpa')) return false;
      return true;
    }

    // Priority: Kasur → Divan → Headboard → Sorong
    if (isValid(product.kasur)) return product.kasur;
    if (isValid(product.divan)) return product.divan;
    if (isValid(product.headboard)) return product.headboard;
    if (isValid(product.sorong)) return product.sorong;

    // Fallback to brand if nothing else
    return product.brand;
  }

  /// Build product name and size section in AppBar with adaptive sizing
  Widget _buildProductNameSection(
      BuildContext context, ProductEntity product, bool isDark) {
    final theme = Theme.of(context);
    final productName = _getProductDisplayName(product);
    final productSize = product.ukuran;
    final nameLength = productName.length;

    // Fixed width dan height untuk konsistensi proporsi
    const double containerWidth = 220;
    const double containerHeight = 60;

    // Dynamic font size based on name length untuk single line
    double nameFontSize;
    if (nameLength <= 10) {
      nameFontSize = 15;
    } else if (nameLength <= 15) {
      nameFontSize = 14;
    } else if (nameLength <= 20) {
      nameFontSize = 13;
    } else {
      nameFontSize = 12;
    }

    return Container(
      width: containerWidth,
      height: containerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Product name - single line dengan ukuran font dinamis
          Text(
            productName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              fontSize: nameFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppPadding.p2),
          // Product size - selalu terlihat di bawah
          if (productSize.isNotEmpty)
            Text(
              '($productSize)',
              style: theme.textTheme.titleMedium?.copyWith(
                color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
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
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
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
          const SizedBox(width: AppPadding.p8),
          // Share bubble
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
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
      ProductState state, double netPrice, bool isDark) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    // Detect if device has gesture navigation (home indicator)
    final hasGestureNavigation = bottomPadding > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
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
      child: _buildActionButtons(context, product, state, netPrice, isDark),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProductEntity product,
      ProductState state, double netPrice, bool isDark) {
    return Row(
      children: [
        // Left side action bubbles
        _buildActionBubble(
          context,
          Icons.credit_card_rounded,
          "Credit",
          () => ProductActions.showCreditPopup(context, product),
          isDark,
        ),
        const SizedBox(width: AppPadding.p8),
        _buildActionBubble(
          context,
          Icons.edit_rounded,
          "Edit",
          () => ProductActions.showEditPopup(context, product),
          isDark,
        ),
        const SizedBox(width: AppPadding.p8),
        _buildActionBubble(
          context,
          Icons.info_outline_rounded,
          "Info",
          () => ProductActions.showInfoPopup(context, product),
          isDark,
        ),

        const SizedBox(width: AppPadding.p12),

        // Right side - Add to Cart with price
        Expanded(
          child: _buildAddToCartButton(context, product, netPrice, isDark),
        ),
      ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark
                : AppColors.primaryLight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.primaryLight.withValues(alpha: 0.2),
            ),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Build Add to Cart button with price display
  Widget _buildAddToCartButton(
    BuildContext context,
    ProductEntity product,
    double netPrice,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addToCart(context, product),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryLight,
                AppColors.primaryLight.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Price section
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  FormatHelper.formatCurrency(netPrice),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppPadding.p12),

              // Divider
              Container(
                width: 1,
                height: 24,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: AppPadding.p12),

              // Add to cart icon and text
              const Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppPadding.p8),
              const Text(
                'Add to Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
}
