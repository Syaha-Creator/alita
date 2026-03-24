import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/app_analytics_service.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/price_block.dart';
import '../../data/models/item_lookup.dart';
import '../../data/models/product.dart';
import '../../logic/cart_item_builder.dart';
import '../../logic/item_lookup_provider.dart';
import '../../logic/product_cart_validator.dart';
import '../../logic/product_detail_utils.dart';
import '../../logic/product_provider.dart';
import '../../logic/product_share_helper.dart';
import '../../logic/product_variant_resolver.dart';
import '../../logic/selection_sync_result.dart';
import '../../../cart/data/cart_item.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../../favorites/logic/favorites_provider.dart';
import '../../../product/logic/brand_spec_provider.dart';
import '../widgets/discount_modal.dart';
import '../widgets/installment_simulation_section.dart';
import '../widgets/product_anchor_type.dart';
import '../widgets/product_bonus_builder.dart';
import '../widgets/product_configurator_section.dart';
import '../widgets/product_detail_app_bar.dart';
import '../widgets/product_detail_bottom_bar.dart';
import '../widgets/product_image_carousel.dart';
import '../widgets/product_info_header.dart';
import '../widgets/product_price_section.dart';
import '../widgets/product_specifications_section.dart';

/// Tracks the share-in-progress state via Riverpod instead of setState.
final _sharingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Stable empty collections for provider select fallbacks (avoids rebuilds during loading).
final _emptyGroupedLookups = <String, List<ItemLookup>>{};
final _emptyProducts = <Product>[];

/// Product detail page with Hero animation, SliverAppBar and Product Configurator
class ProductDetailPage extends ConsumerStatefulWidget {
  final Product product;
  final CartItem? editItem;
  final int? cartIndex;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.editItem,
    this.cartIndex,
  });

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final PageController _imagePageController = PageController();
  bool _isScrolled = false;
  int _currentImageIndex = 0;

  String? selectedSize;
  String? selectedDivan;
  String? selectedHeadboard;
  String? selectedSorong;

  ItemLookup? selectedKasurLookup;
  ItemLookup? selectedDivanLookup;
  ItemLookup? selectedHeadboardLookup;
  ItemLookup? selectedSorongLookup;
  bool isKasurOnly = true;
  List<double> appliedDiscounts = [];

  bool isBonusCustomized = false;
  List<Map<String, dynamic>> customBonuses = [];

  double? targetTotalEup;

  int selectedInstallmentTenor = 12;
  final List<int> installmentOptions = [3, 6, 12, 24];
  final TextEditingController _targetTotalController = TextEditingController();
  final FocusNode _totalFocusNode = FocusNode();

  bool _isKasurCustom = false;
  bool _isDivanCustom = false;
  bool _isHeadboardCustom = false;
  bool _isSorongCustom = false;

  final TextEditingController _customKasurCtrl = TextEditingController();
  final TextEditingController _customDivanCtrl = TextEditingController();
  final TextEditingController _customHbCtrl = TextEditingController();
  final TextEditingController _customSorongCtrl = TextEditingController();

  double _lastBottomPriceAnalyst = 0;
  double _lastBaseTotalEup = 0;
  List<double> _lastMaxLimits = const [];

  static final _totalCurrencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  bool get _isEditMode => widget.editItem != null && widget.cartIndex != null;

  // ── ANCHOR ITEM DETECTION ──

  AnchorType get _anchor {
    final p = widget.product;
    if (ProductDetailUtils.isComponentPresent(p.kasur)) return AnchorType.kasur;
    if (ProductDetailUtils.isComponentPresent(p.divan)) return AnchorType.divan;
    if (ProductDetailUtils.isComponentPresent(p.headboard)) {
      return AnchorType.headboard;
    }
    return AnchorType.sorong;
  }

  bool get _isHeadboardProduct => _anchor == AnchorType.headboard;
  bool get _isSorongProduct => _anchor == AnchorType.sorong;
  bool get _divanHasSet => widget.product.eupHeadboard > 0;

  @override
  void initState() {
    super.initState();
    AppAnalyticsService.logViewItem(
      widget.product.id.toString(),
      widget.product.name,
    );
    _totalFocusNode.addListener(_onTotalFocusChange);
    _scrollController.addListener(() {
      if (!mounted) return;
      if (_scrollController.offset > 150 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 150 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    final editItem = widget.editItem;
    if (editItem != null) {
      final p = editItem.product;
      selectedSize = p.ukuran.isNotEmpty ? p.ukuran : null;
      isKasurOnly = (_isHeadboardProduct || _isSorongProduct) ? true : !p.isSet;
      if (isKasurOnly) {
        selectedDivan = 'Tanpa Divan';
        selectedHeadboard = 'Tanpa Headboard';
        selectedSorong = 'Tanpa Sorong';
      } else {
        selectedDivan = p.divan.isNotEmpty ? p.divan : null;
        selectedHeadboard = p.headboard.isNotEmpty ? p.headboard : null;
        selectedSorong = p.sorong.isNotEmpty ? p.sorong : null;
      }
      targetTotalEup = p.price;
      _targetTotalController.text = _totalCurrencyFormat.format(p.price).trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final base = _lastBaseTotalEup;
        final limits = _lastMaxLimits;
        final target = targetTotalEup;
        if (base > 0 && limits.isNotEmpty && target != null && target < base) {
          setState(() {
            appliedDiscounts = _computeDiscountsFromTargetTotal(
              target,
              base,
              limits,
            );
          });
        }
      });
    }
  }

  void _onTotalFocusChange() {
    if (!_totalFocusNode.hasFocus) {
      final s = ThousandsSeparatorInputFormatter.digitsOnly(
        _targetTotalController.text,
      );
      final v = s.isEmpty ? null : double.tryParse(s);
      if (v != null && v > 0) {
        final formatted = _totalCurrencyFormat.format(v).trim();
        if (_targetTotalController.text != formatted) {
          _targetTotalController.text = formatted;
        }
        if (_lastBottomPriceAnalyst > 0 && v < _lastBottomPriceAnalyst) {
          if (mounted) {
            setState(() {
              targetTotalEup = _lastBottomPriceAnalyst;
              _targetTotalController.text =
                  _totalCurrencyFormat.format(_lastBottomPriceAnalyst).trim();
              appliedDiscounts = _computeDiscountsFromTargetTotal(
                _lastBottomPriceAnalyst,
                _lastBaseTotalEup,
                _lastMaxLimits,
              );
            });
            AppFeedback.show(
              context,
              message: 'Harga disesuaikan ke nilai minimum',
              type: AppFeedbackType.warning,
              floating: true,
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _imagePageController.dispose();
    _totalFocusNode.removeListener(_onTotalFocusChange);
    _targetTotalController.dispose();
    _totalFocusNode.dispose();
    _customKasurCtrl.dispose();
    _customDivanCtrl.dispose();
    _customHbCtrl.dispose();
    _customSorongCtrl.dispose();
    super.dispose();
  }

  Future<void> _shareProduct() async {
    ref.read(_sharingProvider.notifier).state = true;
    try {
      await ProductShareHelper.share(context, product: widget.product);
    } finally {
      if (mounted) ref.read(_sharingProvider.notifier).state = false;
    }
  }

  List<double> _computeDiscountsFromTargetTotal(
    double targetTotal,
    double baseTotalEup,
    List<double> maxLimits,
  ) =>
      ProductDetailUtils.computeDiscountsFromTargetTotal(
          targetTotal, baseTotalEup, maxLimits);

  void _syncDerivedSelectionState({
    required String effectiveDivan,
    required String effectiveHeadboard,
    required String effectiveSorong,
    required ItemLookup? effectiveKasurLookup,
    required ItemLookup? effectiveDivanLookup,
    required ItemLookup? effectiveHeadboardLookup,
    required ItemLookup? effectiveSorongLookup,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final result = SelectionSyncResult.compute(
        isKasurOnly: isKasurOnly,
        currentDivan: selectedDivan,
        currentHeadboard: selectedHeadboard,
        currentSorong: selectedSorong,
        currentKasurLookup: selectedKasurLookup,
        currentDivanLookup: selectedDivanLookup,
        currentHeadboardLookup: selectedHeadboardLookup,
        currentSorongLookup: selectedSorongLookup,
        effectiveDivan: effectiveDivan,
        effectiveHeadboard: effectiveHeadboard,
        effectiveSorong: effectiveSorong,
        effectiveKasurLookup: effectiveKasurLookup,
        effectiveDivanLookup: effectiveDivanLookup,
        effectiveHeadboardLookup: effectiveHeadboardLookup,
        effectiveSorongLookup: effectiveSorongLookup,
        isKasurCustom: _isKasurCustom,
        isDivanCustom: _isDivanCustom,
        isHeadboardCustom: _isHeadboardCustom,
        isSorongCustom: _isSorongCustom,
      );

      if (!result.hasChanges) return;

      setState(() {
        selectedDivan = result.divan;
        selectedHeadboard = result.headboard;
        selectedSorong = result.sorong;
        selectedKasurLookup = result.kasurLookup;
        selectedDivanLookup = result.divanLookup;
        selectedHeadboardLookup = result.headboardLookup;
        selectedSorongLookup = result.sorongLookup;
      });
    });
  }

  double _calculateCascadingPrice(double basePrice, List<double> discounts) =>
      ProductDetailUtils.calculateCascadingPrice(basePrice, discounts);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rawProducts = ref.watch(
      productListProvider.select((v) => v.valueOrNull?.products ?? _emptyProducts),
    );

    final AnchorType initialAnchor = _anchor;
    final AnchorType buildAnchor = initialAnchor;

    final groupedLookups = ref.watch(
      itemLookupProvider.select((v) => v.valueOrNull ?? _emptyGroupedLookups),
    );

    final v = ProductVariantResolver.resolve(
      masterProduct: widget.product,
      rawProducts: rawProducts,
      anchor: initialAnchor,
      isKasurOnly: isKasurOnly,
      selectedSize: selectedSize,
      selectedDivan: selectedDivan,
      selectedHeadboard: selectedHeadboard,
      selectedSorong: selectedSorong,
      selectedKasurLookup: selectedKasurLookup,
      selectedDivanLookup: selectedDivanLookup,
      selectedHeadboardLookup: selectedHeadboardLookup,
      selectedSorongLookup: selectedSorongLookup,
      isKasurCustom: _isKasurCustom,
      isDivanCustom: _isDivanCustom,
      isHeadboardCustom: _isHeadboardCustom,
      isSorongCustom: _isSorongCustom,
      groupedLookups: groupedLookups,
    );

    final activeProduct = v.activeProduct;
    final effectiveSize = v.effectiveSize;
    final effectiveDivan = v.effectiveDivan;
    final effectiveHeadboard = v.effectiveHeadboard;
    final effectiveSorong = v.effectiveSorong;

    _syncDerivedSelectionState(
      effectiveDivan: effectiveDivan,
      effectiveHeadboard: effectiveHeadboard,
      effectiveSorong: effectiveSorong,
      effectiveKasurLookup: v.effectiveKasurLookup,
      effectiveDivanLookup: v.effectiveDivanLookup,
      effectiveHeadboardLookup: v.effectiveHeadboardLookup,
      effectiveSorongLookup: v.effectiveSorongLookup,
    );

    // Cascading discount prices (EUP masked by anchor)
    final double anchoredKasurEup =
        buildAnchor == AnchorType.kasur ? activeProduct.eupKasur : 0.0;
    final double anchoredDivanEup =
        (buildAnchor == AnchorType.kasur || buildAnchor == AnchorType.divan)
            ? activeProduct.eupDivan
            : 0.0;
    final finalKasurPrice = _calculateCascadingPrice(
      anchoredKasurEup,
      appliedDiscounts,
    );
    final finalDivanPrice = _calculateCascadingPrice(
      anchoredDivanEup,
      appliedDiscounts,
    );
    final finalHeadboardPrice = _calculateCascadingPrice(
      activeProduct.eupHeadboard,
      appliedDiscounts,
    );
    final finalSorongPrice = _calculateCascadingPrice(
      activeProduct.eupSorong,
      appliedDiscounts,
    );
    final totalFinalPrice = finalKasurPrice +
        finalDivanPrice +
        finalHeadboardPrice +
        finalSorongPrice;

    final effectiveTotal = targetTotalEup ?? totalFinalPrice;
    _lastBottomPriceAnalyst = activeProduct.bottomPriceAnalyst;
    _lastBaseTotalEup = v.baseTotalEup;
    _lastMaxLimits = v.maxLimits;

    final brandSpecs = ref.watch(
      brandSpecProvider.select((v) => v.valueOrNull),
    );
    Map<String, dynamic>? matchedSpec;
    if (brandSpecs != null && brandSpecs.isNotEmpty) {
      final erpName = widget.product.name.toLowerCase();
      for (final spec in brandSpecs) {
        final brandName = (spec['name'] as String? ?? '').toLowerCase();
        if (brandName.isNotEmpty && erpName.contains(brandName)) {
          matchedSpec = spec as Map<String, dynamic>;
          break;
        }
      }
    }

    final defaultBonuses =
        ProductBonusBuilder.buildDefaultBonuses(activeProduct);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ProductDetailAppBar(
          productName: widget.product.name,
          effectiveSize: effectiveSize,
          isKasurOnly: isKasurOnly,
          isScrolled: _isScrolled,
          buildAnchor: buildAnchor,
          divanHasSet: _divanHasSet,
          isSharing: ref.watch(_sharingProvider),
          sharingProvider: _sharingProvider,
          onShareTap: _shareProduct,
          onBackTap: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                ProductImageCarousel(
                  screenWidth: screenWidth,
                  baseImageUrl: widget.product.imageUrl,
                  productId: widget.product.id,
                  matchedSpec: matchedSpec,
                  controller: _imagePageController,
                  currentIndex: _currentImageIndex,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                ),
                _buildProductDetails(
                  context: context,
                  activeProduct: activeProduct,
                  buildAnchor: buildAnchor,
                  hasSetOptions: v.hasSetOptions,
                  availableSizes: v.availableSizes,
                  divansForConfigurator: v.divansForConfigurator,
                  headboardsForConfigurator: v.headboardsForConfigurator,
                  availableSorongs: v.availableSorongs,
                  effectiveSize: effectiveSize,
                  effectiveDivan: effectiveDivan,
                  effectiveHeadboard: effectiveHeadboard,
                  effectiveSorong: effectiveSorong,
                  effectiveTotal: effectiveTotal,
                  totalFinalPrice: totalFinalPrice,
                  finalKasurPrice: finalKasurPrice,
                  finalDivanPrice: finalDivanPrice,
                  finalHeadboardPrice: finalHeadboardPrice,
                  finalSorongPrice: finalSorongPrice,
                  kasurLookups: v.kasurLookups,
                  effectiveKasurLookup: v.effectiveKasurLookup,
                  divanLookups: v.divanLookups,
                  effectiveDivanLookup: v.effectiveDivanLookup,
                  headboardLookups: v.headboardLookups,
                  effectiveHeadboardLookup: v.effectiveHeadboardLookup,
                  sorongLookups: v.sorongLookups,
                  effectiveSorongLookup: v.effectiveSorongLookup,
                  matchedSpec: matchedSpec,
                  defaultBonuses: defaultBonuses,
                ),
              ],
            ),
            _buildBottomBar(
              activeProduct,
              buildAnchor,
              effectiveSize,
              effectiveDivan,
              effectiveHeadboard,
              effectiveSorong,
              effectiveTotal,
              finalKasurPrice,
              finalDivanPrice,
              finalHeadboardPrice,
              finalSorongPrice,
              groupedLookups,
              v.effectiveKasurLookup,
              v.effectiveDivanLookup,
              v.effectiveHeadboardLookup,
              v.effectiveSorongLookup,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Product Details (Orchestrator) ─────────────────────────

  Widget _buildProductDetails({
    required BuildContext context,
    required Product activeProduct,
    required AnchorType buildAnchor,
    required bool hasSetOptions,
    required List<String> availableSizes,
    required List<String> divansForConfigurator,
    required List<String> headboardsForConfigurator,
    required List<String> availableSorongs,
    required String effectiveSize,
    required String effectiveDivan,
    required String effectiveHeadboard,
    required String effectiveSorong,
    required double effectiveTotal,
    required double totalFinalPrice,
    required double finalKasurPrice,
    required double finalDivanPrice,
    required double finalHeadboardPrice,
    required double finalSorongPrice,
    required List<ItemLookup> kasurLookups,
    required ItemLookup? effectiveKasurLookup,
    required List<ItemLookup> divanLookups,
    required ItemLookup? effectiveDivanLookup,
    required List<ItemLookup> headboardLookups,
    required ItemLookup? effectiveHeadboardLookup,
    required List<ItemLookup> sorongLookups,
    required ItemLookup? effectiveSorongLookup,
    required Map<String, dynamic>? matchedSpec,
    required List<Map<String, dynamic>> defaultBonuses,
  }) {
    final baseTotal = activeProduct.eupKasur +
        activeProduct.eupDivan +
        activeProduct.eupHeadboard +
        activeProduct.eupSorong;

    const sectionGap = SizedBox(height: 10);
    const sectionPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 20);
    const sectionRadius = BorderRadius.all(Radius.circular(20));
    const sectionDecoration = BoxDecoration(
      color: AppColors.surface,
      borderRadius: sectionRadius,
    );

    return SliverList(
      delegate: SliverChildListDelegate([
        // -- Section 1: Product Info + Price --
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              ProductInfoHeader(
                category: widget.product.category,
                productName: widget.product.name,
              ),
                const SizedBox(height: 16),
              PriceBlock(
                price: effectiveTotal,
                originalPrice: activeProduct.pricelist > baseTotal
                    ? activeProduct.pricelist
                    : null,
      spacing: 4,
      formatPrice: AppFormatters.currencyIdr,
      priceStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
                originalPriceStyle: const TextStyle(
        fontSize: 14,
                  color: AppColors.textTertiary,
        decoration: TextDecoration.lineThrough,
        fontWeight: FontWeight.w500,
      ),
              ),
            ],
          ),
        ),

        sectionGap,

        // -- Section 2: Configurator --
        Container(
          decoration: sectionDecoration,
          padding: sectionPadding,
          child: ProductConfiguratorSection(
            anchorType: buildAnchor,
            availableSizes: availableSizes,
            availableDivans: divansForConfigurator,
            availableHeadboards: headboardsForConfigurator,
            availableSorongs: availableSorongs,
            effectiveSize: effectiveSize,
            effectiveDivan: effectiveDivan,
            effectiveHeadboard: effectiveHeadboard,
            effectiveSorong: effectiveSorong,
            isKasurOnly: isKasurOnly,
            hasSetOptions: hasSetOptions,
            kasurLookups: kasurLookups,
            effectiveKasurLookup: effectiveKasurLookup,
            onKasurLookupSelected: (lookup) => setState(() {
              selectedKasurLookup = lookup;
              _isKasurCustom = false;
            }),
            divanLookups: divanLookups,
            effectiveDivanLookup: effectiveDivanLookup,
            onDivanLookupSelected: (lookup) => setState(() {
              selectedDivanLookup = lookup;
              _isDivanCustom = false;
            }),
            headboardLookups: headboardLookups,
            effectiveHeadboardLookup: effectiveHeadboardLookup,
            onHeadboardLookupSelected: (lookup) => setState(() {
              selectedHeadboardLookup = lookup;
              _isHeadboardCustom = false;
            }),
            sorongLookups: sorongLookups,
            effectiveSorongLookup: effectiveSorongLookup,
            onSorongLookupSelected: (lookup) => setState(() {
              selectedSorongLookup = lookup;
              _isSorongCustom = false;
            }),
            isKasurCustom: _isKasurCustom,
            isDivanCustom: _isDivanCustom,
            isHeadboardCustom: _isHeadboardCustom,
            isSorongCustom: _isSorongCustom,
            customKasurCtrl: _customKasurCtrl,
            customDivanCtrl: _customDivanCtrl,
            customHbCtrl: _customHbCtrl,
            customSorongCtrl: _customSorongCtrl,
            onKasurCustomTap: () => setState(() {
              _isKasurCustom = true;
              selectedKasurLookup = null;
            }),
            onDivanCustomTap: () => setState(() {
              _isDivanCustom = true;
              selectedDivanLookup = null;
            }),
            onHeadboardCustomTap: () => setState(() {
              _isHeadboardCustom = true;
              selectedHeadboardLookup = null;
            }),
            onSorongCustomTap: () => setState(() {
              _isSorongCustom = true;
              selectedSorongLookup = null;
            }),
            onSizeSelected: (v) => setState(() {
            selectedSize = v;
            isBonusCustomized = false;
            customBonuses.clear();
            _isKasurCustom = false;
            _isDivanCustom = false;
            _isHeadboardCustom = false;
            _isSorongCustom = false;
            _customKasurCtrl.clear();
            _customDivanCtrl.clear();
            _customHbCtrl.clear();
            _customSorongCtrl.clear();
            selectedKasurLookup = null;
            selectedDivanLookup = null;
            selectedHeadboardLookup = null;
            selectedSorongLookup = null;
            targetTotalEup = null;
            _targetTotalController.clear();
          }),
            onDivanSelected: (v) => setState(() {
                selectedDivan = v;
                isKasurOnly = false;
                targetTotalEup = null;
                _targetTotalController.clear();
              }),
            onHeadboardSelected: (v) => setState(() {
              selectedHeadboard = v;
              isKasurOnly = false;
              targetTotalEup = null;
              _targetTotalController.clear();
            }),
            onSorongSelected: (v) => setState(() {
              selectedSorong = v;
              targetTotalEup = null;
              _targetTotalController.clear();
            }),
            onKasurOnlyTap: () => setState(() {
                  isKasurOnly = true;
                  selectedDivan = null;
                  selectedHeadboard = null;
                  selectedSorong = null;
                  isBonusCustomized = false;
                  customBonuses.clear();
                  targetTotalEup = null;
                  _targetTotalController.clear();
            }),
            onSetTap: () => setState(() {
                  isKasurOnly = false;
                  selectedDivan = null;
                  selectedHeadboard = null;
                  selectedSorong = null;
                  isBonusCustomized = false;
                  customBonuses.clear();
                  targetTotalEup = null;
                  _targetTotalController.clear();
            }),
            onCustomTextChanged: () => setState(() {}),
          ),
        ),

        sectionGap,

        // -- Section 3: Price Breakdown + Discount + Bonus --
        Container(
          decoration: sectionDecoration,
          padding: sectionPadding,
          child: ProductPriceSection(
            activeProduct: activeProduct,
            finalKasurPrice: finalKasurPrice,
            finalDivanPrice: finalDivanPrice,
            finalHeadboardPrice: finalHeadboardPrice,
            finalSorongPrice: finalSorongPrice,
            appliedDiscounts: appliedDiscounts,
            totalFinalPrice: totalFinalPrice,
            effectiveTotal: effectiveTotal,
            targetTotalEup: targetTotalEup,
            baseTotalEup: _lastBaseTotalEup,
            selectedInstallmentTenor: selectedInstallmentTenor,
            installmentOptions: installmentOptions,
            onInstallmentTenorChanged: (tenor) =>
                setState(() => selectedInstallmentTenor = tenor),
            targetTotalController: _targetTotalController,
            totalFocusNode: _totalFocusNode,
            totalCurrencyFormat: _totalCurrencyFormat,
            onTargetTotalChanged: (newTarget, newDiscounts) {
              setState(() {
                if (newTarget != null) {
                  targetTotalEup = newTarget;
                  appliedDiscounts = newDiscounts;
                } else {
                  targetTotalEup = null;
                }
              });
            },
            onResetDiscounts: () {
              setState(() {
                targetTotalEup = null;
                appliedDiscounts = [];
                _targetTotalController.text =
                    _totalCurrencyFormat.format(_lastBaseTotalEup).trim();
              });
            },
            onDiscountTap: () {
              showDiscountModalGlobal(
                context,
                activeProduct,
                appliedDiscounts,
                (newDiscs) {
                  setState(() {
                    appliedDiscounts = newDiscs;
                  });
                },
              );
            },
            isBonusCustomized: isBonusCustomized,
            customBonuses: customBonuses,
            defaultBonuses: defaultBonuses,
            onBonusesSaved: (newBonuses) {
                    setState(() {
                customBonuses = newBonuses;
                isBonusCustomized = true;
                    });
                  },
                ),
              ),

        sectionGap,

        // -- Section 4: Installment Simulation --
        Container(
          decoration: sectionDecoration,
          padding: sectionPadding,
          child: InstallmentSimulationSection(
            effectiveTotal: effectiveTotal,
            selectedTenor: selectedInstallmentTenor,
            tenorOptions: installmentOptions,
            onTenorChanged: (tenor) =>
                setState(() => selectedInstallmentTenor = tenor),
          ),
        ),

        sectionGap,

        // -- Section 5: Specifications --
        Container(
          decoration: sectionDecoration,
          padding: sectionPadding,
          child: ProductSpecificationsSection(
            product: activeProduct,
            matchedSpec: matchedSpec,
          ),
        ),

        const SizedBox(height: 100),
      ]),
    );
  }

  // ───────────────────────── Bottom Bar ─────────────────────────

  Widget _buildBottomBar(
    Product activeProduct,
    AnchorType anchorType,
    String effectiveSize,
    String effectiveDivan,
    String effectiveHeadboard,
    String effectiveSorong,
    double totalFinalPrice,
    double finalKasurPrice,
    double finalDivanPrice,
    double finalHeadboardPrice,
    double finalSorongPrice,
    Map<String, List<ItemLookup>> groupedLookups,
    ItemLookup? effectiveKasurLookup,
    ItemLookup? effectiveDivanLookup,
    ItemLookup? effectiveHeadboardLookup,
    ItemLookup? effectiveSorongLookup,
  ) {
    final isFavorite = ref.watch(isFavoriteProvider(widget.product.id));

    return ProductDetailBottomBar(
      isFavorite: isFavorite,
      onFavoriteTap: () {
        ref.read(favoritesProvider.notifier).toggleFavorite(widget.product.id);
        AppFeedback.show(
          context,
          message:
              isFavorite ? 'Dihapus dari favorit' : 'Ditambahkan ke favorit',
          type: AppFeedbackType.info,
          floating: true,
        );
      },
      onAddToCartTap: () => _onAddToCartTap(
        activeProduct: activeProduct,
        effectiveSize: effectiveSize,
        effectiveDivan: effectiveDivan,
        effectiveHeadboard: effectiveHeadboard,
        effectiveSorong: effectiveSorong,
        totalFinalPrice: totalFinalPrice,
        finalKasurPrice: finalKasurPrice,
        finalDivanPrice: finalDivanPrice,
        finalHeadboardPrice: finalHeadboardPrice,
        finalSorongPrice: finalSorongPrice,
        groupedLookups: groupedLookups,
        effectiveKasurLookup: effectiveKasurLookup,
        effectiveDivanLookup: effectiveDivanLookup,
        effectiveHeadboardLookup: effectiveHeadboardLookup,
        effectiveSorongLookup: effectiveSorongLookup,
      ),
      isEditMode: _isEditMode,
      priceLabel: AppFormatters.currencyIdr(totalFinalPrice),
    );
  }

  // ───────────────────────── Add to Cart Handler ─────────────────────────

  void _onAddToCartTap({
    required Product activeProduct,
    required String effectiveSize,
    required String effectiveDivan,
    required String effectiveHeadboard,
    required String effectiveSorong,
    required double totalFinalPrice,
    required double finalKasurPrice,
    required double finalDivanPrice,
    required double finalHeadboardPrice,
    required double finalSorongPrice,
    required Map<String, List<ItemLookup>> groupedLookups,
    required ItemLookup? effectiveKasurLookup,
    required ItemLookup? effectiveDivanLookup,
    required ItemLookup? effectiveHeadboardLookup,
    required ItemLookup? effectiveSorongLookup,
  }) {
    // ── Validation ──

    final validation = ProductCartValidator.validate(
      activeProduct: activeProduct,
      effectiveSize: effectiveSize,
      groupedLookups: groupedLookups,
      selectedKasurLookup: selectedKasurLookup,
      isKasurCustom: _isKasurCustom,
      isKasurOnly: isKasurOnly,
      selectedHeadboard: selectedHeadboard,
      selectedDivanLookup: selectedDivanLookup,
      isDivanCustom: _isDivanCustom,
      selectedHeadboardLookup: selectedHeadboardLookup,
      isHeadboardCustom: _isHeadboardCustom,
    );
    if (!validation.isValid) {
      AppFeedback.show(context,
          message: validation.errorMessage!,
                                  type: AppFeedbackType.error,
          floating: true);
                                return;
    }

    // ── Build cart item via extracted builder ──

    final snapshotItem = CartItemBuilder.build(
      activeProduct: activeProduct,
      masterProduct: widget.product,
      effectiveSize: effectiveSize,
      effectiveDivan: effectiveDivan,
      effectiveHeadboard: effectiveHeadboard,
      effectiveSorong: effectiveSorong,
      totalFinalPrice: totalFinalPrice,
      finalKasurPrice: finalKasurPrice,
      finalDivanPrice: finalDivanPrice,
      finalHeadboardPrice: finalHeadboardPrice,
      finalSorongPrice: finalSorongPrice,
      isKasurOnly: isKasurOnly,
      appliedDiscounts: appliedDiscounts,
      groupedLookups: groupedLookups,
      isKasurCustom: _isKasurCustom,
      effectiveKasurLookup: effectiveKasurLookup,
      customKasurNote: _customKasurCtrl.text.trim(),
      isDivanCustom: _isDivanCustom,
      effectiveDivanLookup: effectiveDivanLookup,
      customDivanNote: _customDivanCtrl.text.trim(),
      isHeadboardCustom: _isHeadboardCustom,
      effectiveHeadboardLookup: effectiveHeadboardLookup,
      customHbNote: _customHbCtrl.text.trim(),
      isSorongCustom: _isSorongCustom,
      effectiveSorongLookup: effectiveSorongLookup,
      customSorongNote: _customSorongCtrl.text.trim(),
      customBonuses: isBonusCustomized ? customBonuses : null,
    );

    final summaryForToast = CartItemBuilder.buildSummaryForToast(
      effectiveSize: effectiveSize,
      effectiveDivan: effectiveDivan,
      effectiveHeadboard: effectiveHeadboard,
      effectiveSorong: effectiveSorong,
    );

    final cartIndex = widget.cartIndex;
    if (_isEditMode && cartIndex != null) {
                              ref.read(cartProvider.notifier).updateCartItem(
            cartIndex,
                                    snapshotItem,
                                  );
                              Navigator.of(context).pop();
      AppFeedback.show(context,
                                message: 'Keranjang diperbarui',
                                type: AppFeedbackType.success,
          floating: true);
                            } else {
      ref.read(cartProvider.notifier).addItem(snapshotItem);
      AppAnalyticsService.logAddToCart(
        widget.product.id.toString(),
        widget.product.name,
      );
      AppFeedback.show(context,
          message:
              '${widget.product.name} ($summaryForToast) ditambahkan ke keranjang',
          type: AppFeedbackType.success,
          floating: true);
    }
  }
}
