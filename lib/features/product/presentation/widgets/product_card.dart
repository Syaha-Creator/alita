// lib/features/product/presentation/widgets/product_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import 'product_card/product_card_widgets.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) {
        return previous.roundedPrices[product.id] !=
            current.roundedPrices[product.id];
      },
      builder: (context, state) {
        final netPrice =
            state.roundedPrices[product.id] ?? product.endUserPrice;
        final totalDiscount = product.pricelist - netPrice;
        final discountPercentage = product.pricelist > 0
            ? ((totalDiscount / product.pricelist) * 100).round()
            : 0;
        final setProduct = _findSetProduct(state, product);
        final individualKasurProduct =
            _findIndividualKasurProduct(state, product);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: ResponsiveHelper.isMobile(context) ? 280 : 320,
              maxWidth: ResponsiveHelper.getResponsiveMaxWidth(context),
            ),
            child: Container(
              margin: ResponsiveHelper.getResponsiveMargin(context),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark
                    ? AppColors.cardDark
                    : AppColors.surfaceLight, // 30% - Card/Surface
                border: isDark
                    ? Border.all(
                        color: AppColors.borderDark, // 30% - Border
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.shadowDark
                        : AppColors.accentLight
                            .withValues(alpha: 0.08), // 10% dengan opacity
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: isDark
                        ? AppColors.shadowDark.withValues(alpha: 0.5)
                        : AppColors.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<ProductBloc>().add(SelectProduct(product));
                    context.pushNamed(RoutePaths.productDetail, extra: product);
                  },
                  borderRadius: BorderRadius.circular(24),
                  splashColor: AppColors.accentLight
                      .withValues(alpha: 0.1), // 10% dengan opacity
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === HEADER dengan Gradient ===
                      _buildHeader(context, isDark, discountPercentage),

                      // === CONTENT ===
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            _buildProductName(context, isDark),

                            // Specifications (with conditional spacing)
                            _buildSpecificationsWithSpacing(context, isDark),

                            // Price Section
                            _buildPriceSection(
                                context, isDark, netPrice, totalDiscount),

                            // Bonus (with conditional spacing)
                            _buildBonusWithSpacing(isDark),

                            // Comparison sections
                            if (product.isSet) ...[
                              const SizedBox(height: AppPadding.p10),
                              IndividualPricingSection(product: product),
                              // Perbandingan dengan Kasur Only
                              if (individualKasurProduct != null) ...[
                                const SizedBox(height: AppPadding.p10),
                                IndividualComparisonSection(
                                  setNetPrice: netPrice,
                                  individualNetPrice: state.roundedPrices[
                                          individualKasurProduct.id] ??
                                      individualKasurProduct.endUserPrice,
                                  isDark: isDark,
                                ),
                              ],
                            ],

                            // Perbandingan dengan Set (untuk produk individual)
                            if (!product.isSet && setProduct != null) ...[
                              const SizedBox(height: AppPadding.p10),
                              SetComparisonSection(
                                setNetPrice:
                                    state.roundedPrices[setProduct.id] ??
                                        setProduct.endUserPrice,
                                currentNetPrice: netPrice,
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          logoPath,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.bed_rounded, color: Colors.white, size: 28);
          },
        ),
      );
    }

    return const Icon(Icons.bed_rounded, color: Colors.white, size: 28);
  }

  /// Check if program is valid for display
  bool _isValidProgram(String program) {
    if (program.isEmpty) return false;
    if (program.trim() == '-') return false;
    return true;
  }

  /// Header dengan gradient dan badges
  Widget _buildHeader(
      BuildContext context, bool isDark, int discountPercentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primaryLight.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Row(
        children: [
          // Brand logo with white background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _getBrandLogo(product.brand),
          ),
          const SizedBox(width: AppPadding.p12),

          // Brand name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_isValidProgram(product.program))
                  Text(
                    product.program,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Badges
          Row(
            children: [
              if (discountPercentage > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer,
                          color: Colors.white, size: 12),
                      const SizedBox(width: AppPadding.p4),
                      Text(
                        "$discountPercentage%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (product.isSet)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "SET",
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to check if value is valid for display
  bool _isValidValue(String value) {
    if (value.isEmpty) return false;
    if (value.trim() == '-') return false;
    if (value.trim().toLowerCase().startsWith('tanpa')) return false;
    return true;
  }

  /// Get main display type: 'kasur', 'divan', 'headboard', 'sorong', or 'brand'
  String _getMainDisplayType() {
    if (_isValidValue(product.kasur)) return 'kasur';
    if (_isValidValue(product.divan)) return 'divan';
    if (_isValidValue(product.headboard)) return 'headboard';
    if (_isValidValue(product.sorong)) return 'sorong';
    return 'brand';
  }

  /// Get display name with fallback: Kasur → Divan → Headboard → Sorong
  String _getProductDisplayName() {
    if (_isValidValue(product.kasur)) return product.kasur;
    if (_isValidValue(product.divan)) return product.divan;
    if (_isValidValue(product.headboard)) return product.headboard;
    if (_isValidValue(product.sorong)) return product.sorong;
    return product.brand;
  }

  /// Product name dengan ukuran
  Widget _buildProductName(BuildContext context, bool isDark) {
    final displayName = _getProductDisplayName();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryDark.withValues(alpha: 0.1)
            : AppColors.primaryLight.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.2)
              : AppColors.primaryLight.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Kasur icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.king_bed_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppPadding.p12),

          // Name and size
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppPadding.p2),
                Row(
                  children: [
                    Icon(
                      Icons.straighten_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppPadding.p4),
                    Text(
                      product.ukuran,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arrow
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.primaryLight.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  /// Specifications grid - excludes the main display item
  Widget _buildSpecifications(BuildContext context, bool isDark) {
    final specs = <Map<String, dynamic>>[];
    final mainType = _getMainDisplayType();

    // Only add items that are NOT the main display and are valid
    // Kasur is never shown in specs (always main or not shown)
    if (mainType != 'divan' && _isValidValue(product.divan)) {
      specs.add({
        'icon': Icons.layers_rounded,
        'label': 'Divan',
        'value': product.divan,
        'color': AppColors.info,
      });
    }
    if (mainType != 'headboard' && _isValidValue(product.headboard)) {
      specs.add({
        'icon': Icons.view_headline_rounded,
        'label': 'Headboard',
        'value': product.headboard,
        'color': AppColors.warning,
      });
    }
    if (mainType != 'sorong' && _isValidValue(product.sorong)) {
      specs.add({
        'icon': Icons.arrow_downward_rounded,
        'label': 'Sorong',
        'value': product.sorong,
        'color': AppColors.success,
      });
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: specs.map((spec) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (spec['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (spec['color'] as Color).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                spec['icon'] as IconData,
                size: 14,
                color: spec['color'] as Color,
              ),
              const SizedBox(width: AppPadding.p6),
              Text(
                spec['value'] as String,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Check if there are valid specs to show
  bool _hasValidSpecs() {
    final mainType = _getMainDisplayType();
    if (mainType != 'divan' && _isValidValue(product.divan)) return true;
    if (mainType != 'headboard' && _isValidValue(product.headboard)) {
      return true;
    }
    if (mainType != 'sorong' && _isValidValue(product.sorong)) return true;
    return false;
  }

  /// Check if there are valid bonus items
  bool _hasValidBonus() {
    return product.bonus.any((b) =>
        b.name.isNotEmpty &&
        b.name.trim() != '0' &&
        b.name.trim() != '-' &&
        b.quantity > 0);
  }

  /// Specifications with conditional spacing
  Widget _buildSpecificationsWithSpacing(BuildContext context, bool isDark) {
    if (!_hasValidSpecs()) {
      // No specs - minimal spacing before price
      return const SizedBox(height: AppPadding.p12);
    }

    return Column(
      children: [
        const SizedBox(height: AppPadding.p12),
        _buildSpecifications(context, isDark),
        const SizedBox(height: AppPadding.p12),
      ],
    );
  }

  /// Bonus section with conditional spacing
  Widget _buildBonusWithSpacing(bool isDark) {
    if (!_hasValidBonus()) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: AppPadding.p10),
        BonusInfoSection(product: product, isDark: isDark),
      ],
    );
  }

  /// Price section dengan visual hierarchy
  Widget _buildPriceSection(BuildContext context, bool isDark, double netPrice,
      double totalDiscount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.success.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Pricelist (original)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.sell_outlined,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  const SizedBox(width: AppPadding.p6),
                  Text(
                    "Pricelist",
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                FormatHelper.formatCurrency(product.pricelist),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p10),

          // Net Price (highlighted)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppPadding.p8),
                    Text(
                      "Harga Net",
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  FormatHelper.formatCurrency(netPrice),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Discount savings - only show if there's a discount
          if (totalDiscount > 0) ...[
            const SizedBox(height: AppPadding.p10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.savings_outlined,
                        size: 16, color: AppColors.error),
                    SizedBox(width: AppPadding.p6),
                    Text(
                      "Hemat",
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "- ${FormatHelper.formatCurrency(totalDiscount)}",
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods
  ProductEntity? _findSetProduct(
      ProductState state, ProductEntity currentProduct) {
    try {
      return state.products.firstWhere(
        (product) =>
            product.isSet == true &&
            product.kasur == currentProduct.kasur &&
            product.divan == currentProduct.divan &&
            product.headboard == currentProduct.headboard &&
            product.sorong == currentProduct.sorong &&
            product.ukuran == currentProduct.ukuran &&
            product.brand == currentProduct.brand &&
            product.channel == currentProduct.channel &&
            product.area == currentProduct.area,
      );
    } catch (e) {
      return null;
    }
  }

  ProductEntity? _findIndividualKasurProduct(
      ProductState state, ProductEntity currentProduct) {
    // Helper function to check if value indicates "no item"
    bool isNoItem(String value) {
      if (value.isEmpty) return true;
      if (value.trim() == '-') return true;
      if (value.trim().toLowerCase().startsWith('tanpa')) return true;
      if (value == AppStrings.noDivan) return true;
      if (value == AppStrings.noHeadboard) return true;
      if (value == AppStrings.noSorong) return true;
      return false;
    }

    try {
      return state.products.firstWhere(
        (product) =>
            product.isSet == false &&
            product.kasur == currentProduct.kasur &&
            product.ukuran == currentProduct.ukuran &&
            product.brand == currentProduct.brand &&
            product.channel == currentProduct.channel &&
            product.area == currentProduct.area &&
            isNoItem(product.divan) &&
            isNoItem(product.headboard) &&
            isNoItem(product.sorong),
      );
    } catch (e) {
      return null;
    }
  }
}
