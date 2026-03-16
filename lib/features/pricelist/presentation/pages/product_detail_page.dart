import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/floating_badge.dart';
import '../../../../core/widgets/price_block.dart';
import '../../data/models/item_lookup.dart';
import '../../data/models/product.dart';
import '../../logic/item_lookup_provider.dart';
import '../../logic/product_provider.dart';
import '../../../cart/data/cart_item.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../../cart/presentation/widgets/cart_bottom_sheet.dart';
import '../../../favorites/logic/favorites_provider.dart';
import '../../../product/logic/brand_spec_provider.dart';
import '../widgets/discount_modal.dart';
import '../widgets/product_anchor_type.dart';
import '../widgets/product_configurator_section.dart';
import '../widgets/product_detail_bottom_bar.dart';
import '../widgets/product_image_carousel.dart';
import '../widgets/product_info_header.dart';
import '../widgets/product_price_section.dart';
import '../widgets/product_specifications_section.dart';

/// Tracks the share-in-progress state via Riverpod instead of setState.
final _sharingProvider = StateProvider.autoDispose<bool>((ref) => false);

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

  static const _kCustomItemNum = 'CUSTOM';

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

  static bool _isPresent(String field) {
    final v = field.trim().toLowerCase();
    return v.isNotEmpty && !v.startsWith('tanpa');
  }

  AnchorType get _anchor {
    final p = widget.product;
    if (_isPresent(p.kasur)) return AnchorType.kasur;
    if (_isPresent(p.divan)) return AnchorType.divan;
    if (_isPresent(p.headboard)) return AnchorType.headboard;
    return AnchorType.sorong;
  }

  bool get _isHeadboardProduct => _anchor == AnchorType.headboard;
  bool get _isSorongProduct => _anchor == AnchorType.sorong;
  bool get _divanHasSet => widget.product.eupHeadboard > 0;

  @override
  void initState() {
    super.initState();
    _totalFocusNode.addListener(_onTotalFocusChange);
    _scrollController.addListener(() {
      if (_scrollController.offset > 150 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 150 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    if (widget.editItem != null) {
      final p = widget.editItem!.product;
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
        if (base > 0 &&
            limits.isNotEmpty &&
            targetTotalEup != null &&
            targetTotalEup! < base) {
          setState(() {
            appliedDiscounts = _computeDiscountsFromTargetTotal(
              targetTotalEup!,
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
    final product = widget.product;

    final box = context.findRenderObject() as RenderBox?;
    final Rect origin;
    if (box != null && box.hasSize && box.size.width > 0) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    } else {
      final screen = MediaQuery.of(context).size;
      origin = Rect.fromLTWH(0, 0, screen.width, screen.height / 2);
    }

    ref.read(_sharingProvider.notifier).state = true;
    try {
      final formattedPrice = AppFormatters.currencyIdr(product.price);
      final text = 'Cek produk keren ini!\n'
          '*${product.brand}* — ${product.name}\n'
          '*Harga:* $formattedPrice\n'
          '\nLihat detail selengkapnya di Alita Pricelist.';

      final files = <XFile>[];
      if (product.imageUrl.isNotEmpty) {
        final bytes = await ApiClient.instance.downloadBytes(product.imageUrl);
        if (bytes != null) {
            final dir = await getTemporaryDirectory();
            final ext = product.imageUrl.contains('.png') ? 'png' : 'jpg';
            final file = File('${dir.path}/share_product.$ext');
          await file.writeAsBytes(bytes);
            files.add(XFile(file.path, mimeType: 'image/$ext'));
        }
      }

      await Share.shareXFiles(
        files,
        text: text,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          message: 'Gagal membagikan produk: $e',
          type: AppFeedbackType.error,
          floating: true,
        );
      }
    } finally {
      if (mounted) ref.read(_sharingProvider.notifier).state = false;
    }
  }

  List<double> _computeDiscountsFromTargetTotal(
    double targetTotal,
    double baseTotalEup,
    List<double> maxLimits,
  ) {
    if (targetTotal >= baseTotalEup || targetTotal <= 0 || maxLimits.isEmpty) {
      return [];
    }
    final result = <double>[];
    double base = baseTotalEup;
    for (final limit in maxLimits) {
      final d = (1 - targetTotal / base).clamp(0.0, limit);
      result.add(d);
      base = base * (1 - d);
    }
    return result;
  }

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

      var shouldUpdate = false;

      String? nextSelectedDivan = selectedDivan;
      String? nextSelectedHeadboard = selectedHeadboard;
      String? nextSelectedSorong = selectedSorong;

      ItemLookup? nextKasurLookup = selectedKasurLookup;
      ItemLookup? nextDivanLookup = selectedDivanLookup;
      ItemLookup? nextHeadboardLookup = selectedHeadboardLookup;
      ItemLookup? nextSorongLookup = selectedSorongLookup;

      if (!isKasurOnly) {
        if (nextSelectedDivan != effectiveDivan) {
          nextSelectedDivan = effectiveDivan;
          shouldUpdate = true;
        }
        if (nextSelectedHeadboard != effectiveHeadboard) {
          nextSelectedHeadboard = effectiveHeadboard;
          shouldUpdate = true;
        }
        if (nextSelectedSorong != effectiveSorong) {
          nextSelectedSorong = effectiveSorong;
          shouldUpdate = true;
        }
      }

      if (!_isKasurCustom &&
          effectiveKasurLookup != null &&
          nextKasurLookup?.itemNum != effectiveKasurLookup.itemNum) {
        nextKasurLookup = effectiveKasurLookup;
        shouldUpdate = true;
      }
      if (!_isDivanCustom &&
          effectiveDivanLookup != null &&
          nextDivanLookup?.itemNum != effectiveDivanLookup.itemNum) {
        nextDivanLookup = effectiveDivanLookup;
        shouldUpdate = true;
      }
      if (!_isHeadboardCustom &&
          effectiveHeadboardLookup != null &&
          nextHeadboardLookup?.itemNum != effectiveHeadboardLookup.itemNum) {
        nextHeadboardLookup = effectiveHeadboardLookup;
        shouldUpdate = true;
      }
      if (!_isSorongCustom &&
          effectiveSorongLookup != null &&
          nextSorongLookup?.itemNum != effectiveSorongLookup.itemNum) {
        nextSorongLookup = effectiveSorongLookup;
        shouldUpdate = true;
      }

      if (!shouldUpdate) return;

      setState(() {
        selectedDivan = nextSelectedDivan;
        selectedHeadboard = nextSelectedHeadboard;
        selectedSorong = nextSelectedSorong;
        selectedKasurLookup = nextKasurLookup;
        selectedDivanLookup = nextDivanLookup;
        selectedHeadboardLookup = nextHeadboardLookup;
        selectedSorongLookup = nextSorongLookup;
      });
    });
  }

  double _calculateCascadingPrice(double basePrice, List<double> discounts) {
    double finalPrice = basePrice;
    for (final disc in discounts) {
      finalPrice -= (finalPrice * disc);
    }
    return finalPrice;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final asyncProducts = ref.watch(productListProvider);
    final rawProducts = asyncProducts.valueOrNull ?? [];

    final AnchorType initialAnchor = _anchor;
    final siblings = rawProducts.where((p) {
      switch (initialAnchor) {
        case AnchorType.kasur:
          return p.kasur.trim() == widget.product.kasur.trim();
        case AnchorType.divan:
          return p.divan.trim() == widget.product.divan.trim() &&
              !_isPresent(p.kasur);
        case AnchorType.headboard:
          return p.headboard.trim() == widget.product.headboard.trim() &&
              !_isPresent(p.kasur) &&
              !_isPresent(p.divan);
        case AnchorType.sorong:
          return p.sorong.trim() == widget.product.sorong.trim() &&
              !_isPresent(p.kasur) &&
              !_isPresent(p.divan) &&
              !_isPresent(p.headboard);
      }
    }).toList();
    final siblingsList = siblings.isEmpty ? [widget.product] : siblings;

    // 1. Size filter
    final availableSizes = siblingsList
        .map((p) => p.ukuran)
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final effectiveSize =
        (selectedSize != null && availableSizes.contains(selectedSize))
            ? selectedSize!
            : (availableSizes.isNotEmpty
                ? availableSizes.first
                : widget.product.ukuran);
    final siblingsBySize =
        siblingsList.where((p) => p.ukuran == effectiveSize).toList();

    final availableDivans = siblingsBySize
        .map((p) => p.divan)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // 2. Auto-select default "Beli Set"
    String effectiveDivan;
    String effectiveHeadboard;
    String effectiveSorong;
    if (isKasurOnly) {
      effectiveDivan = initialAnchor == AnchorType.divan
          ? widget.product.divan
          : 'Tanpa Divan';
      effectiveHeadboard = initialAnchor == AnchorType.headboard
          ? widget.product.headboard
          : 'Tanpa Headboard';
      effectiveSorong = initialAnchor == AnchorType.sorong
          ? widget.product.sorong
          : 'Tanpa Sorong';
    } else {
      final bool needsAutoSelect = initialAnchor == AnchorType.divan
          ? (selectedHeadboard == null ||
              selectedHeadboard!.trim().toLowerCase().contains('tanpa'))
          : (selectedDivan == null ||
              selectedDivan!.trim().toLowerCase().contains('tanpa'));

      if (needsAutoSelect) {
        final officialSet = siblingsBySize.firstWhere(
          (p) =>
              p.isSet == true &&
              (initialAnchor == AnchorType.kasur
                  ? !p.divan.toLowerCase().contains('tanpa')
                  : !p.headboard.toLowerCase().contains('tanpa')),
          orElse: () => siblingsBySize.firstWhere(
            (p) => initialAnchor == AnchorType.kasur
                ? !p.divan.toLowerCase().contains('tanpa')
                : !p.headboard.toLowerCase().contains('tanpa'),
            orElse: () => siblingsBySize.first,
          ),
        );
        effectiveDivan = initialAnchor == AnchorType.divan
            ? widget.product.divan
            : officialSet.divan;
        effectiveHeadboard = officialSet.headboard;
        effectiveSorong = officialSet.sorong;
      } else {
        effectiveDivan = initialAnchor == AnchorType.divan
            ? widget.product.divan
            : selectedDivan!;
        effectiveHeadboard = selectedHeadboard ?? 'Tanpa Headboard';
        effectiveSorong = selectedSorong ?? 'Tanpa Sorong';
      }
    }

    // 3. Filter Divan
    if (!availableDivans.contains(effectiveDivan)) {
      if (!isKasurOnly) {
        effectiveDivan = availableDivans.firstWhere(
          (d) => !d.trim().toLowerCase().contains('tanpa'),
          orElse: () => availableDivans.isNotEmpty
              ? availableDivans.first
              : 'Tanpa Divan',
        );
      } else {
        effectiveDivan = 'Tanpa Divan';
      }
    }
    final siblingsByDivan =
        siblingsBySize.where((p) => p.divan == effectiveDivan).toList();

    // 4. Filter Headboard
    final availableHeadboards = siblingsByDivan
        .map((p) => p.headboard)
        .where((h) => h.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (!availableHeadboards.contains(effectiveHeadboard)) {
      if (!isKasurOnly) {
        effectiveHeadboard = availableHeadboards.firstWhere(
          (h) => !h.trim().toLowerCase().contains('tanpa'),
          orElse: () => availableHeadboards.isNotEmpty
              ? availableHeadboards.first
              : 'Tanpa Headboard',
        );
      } else {
        effectiveHeadboard = 'Tanpa Headboard';
      }
    }
    final siblingsByHeadboard = siblingsByDivan
        .where((p) => p.headboard == effectiveHeadboard)
        .toList();

    // 5. Filter Sorong
    final availableSorongs = siblingsByHeadboard
        .map((p) => p.sorong)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (!availableSorongs.contains(effectiveSorong)) {
      effectiveSorong =
          availableSorongs.isNotEmpty ? availableSorongs.first : 'Tanpa Sorong';
    }

    // 6. Active product (final SKU)
    final Product activeProduct = siblingsByHeadboard.firstWhere(
      (p) => p.sorong == effectiveSorong,
      orElse: () => siblingsByHeadboard.isNotEmpty
          ? siblingsByHeadboard.first
          : widget.product,
    );

    final AnchorType buildAnchor = initialAnchor;

    // Lookup item_num (color/fabric)
    final lookupAsync = ref.watch(itemLookupProvider);
    final groupedLookups = lookupAsync.value ?? {};
    final kasurKey = activeProduct.kasur.trim().toLowerCase();
    final kasurLookups = (groupedLookups[kasurKey] ?? [])
        .where((l) => l.ukuran == effectiveSize)
        .toList();
    final effectiveKasurLookup = kasurLookups.isEmpty
        ? null
        : (selectedKasurLookup != null &&
                kasurLookups.any(
                  (l) => l.itemNum == selectedKasurLookup!.itemNum,
                ))
            ? selectedKasurLookup!
            : kasurLookups.first;

    List<ItemLookup> divanLookups = [];
    if ((!isKasurOnly || buildAnchor == AnchorType.divan) &&
        !activeProduct.divan.toLowerCase().contains('tanpa')) {
      final divanKey = activeProduct.divan.trim().toLowerCase();
      divanLookups = (groupedLookups[divanKey] ?? [])
          .where((l) => l.ukuran == effectiveSize)
          .toList();
      if (divanLookups.isEmpty) {
        divanLookups = groupedLookups[divanKey] ?? [];
      }
    }
    final effectiveDivanLookup = divanLookups.isEmpty
        ? null
        : (selectedDivanLookup != null &&
                divanLookups.any(
                  (l) => l.itemNum == selectedDivanLookup!.itemNum,
                ))
            ? selectedDivanLookup!
            : divanLookups.first;

    List<ItemLookup> headboardLookups = [];
    if ((!isKasurOnly || buildAnchor == AnchorType.headboard) &&
        !activeProduct.headboard.toLowerCase().contains('tanpa')) {
      final headboardKey = activeProduct.headboard.trim().toLowerCase();
      headboardLookups = (groupedLookups[headboardKey] ?? [])
          .where((l) => l.ukuran == effectiveSize)
          .toList();
      if (headboardLookups.isEmpty) {
        headboardLookups = groupedLookups[headboardKey] ?? [];
      }
    }
    final effectiveHeadboardLookup = headboardLookups.isEmpty
        ? null
        : (selectedHeadboardLookup != null &&
                headboardLookups.any(
                  (l) => l.itemNum == selectedHeadboardLookup!.itemNum,
                ))
            ? selectedHeadboardLookup!
            : headboardLookups.first;

    List<ItemLookup> sorongLookups = [];
    if (!activeProduct.sorong.toLowerCase().contains('tanpa')) {
      final sorongKey = activeProduct.sorong.trim().toLowerCase();
      sorongLookups = (groupedLookups[sorongKey] ?? [])
          .where((l) => l.ukuran == effectiveSize)
          .toList();
      if (sorongLookups.isEmpty) {
        sorongLookups = groupedLookups[sorongKey] ?? [];
      }
    }
    final effectiveSorongLookup = sorongLookups.isEmpty
        ? null
        : (selectedSorongLookup != null &&
                sorongLookups.any(
                  (l) => l.itemNum == selectedSorongLookup!.itemNum,
                ))
            ? selectedSorongLookup!
            : sorongLookups.first;

    _syncDerivedSelectionState(
      effectiveDivan: effectiveDivan,
      effectiveHeadboard: effectiveHeadboard,
      effectiveSorong: effectiveSorong,
      effectiveKasurLookup: effectiveKasurLookup,
      effectiveDivanLookup: effectiveDivanLookup,
      effectiveHeadboardLookup: effectiveHeadboardLookup,
      effectiveSorongLookup: effectiveSorongLookup,
    );

    // 7. Cascading discount prices (EUP masked by anchor)
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
    final bottomPriceAnalyst = activeProduct.bottomPriceAnalyst;
    _lastBottomPriceAnalyst = bottomPriceAnalyst;
    _lastBaseTotalEup = anchoredKasurEup +
        anchoredDivanEup +
        activeProduct.eupHeadboard +
        activeProduct.eupSorong;
    _lastMaxLimits = [
      activeProduct.disc1,
      activeProduct.disc2,
      activeProduct.disc3,
      activeProduct.disc4,
      activeProduct.disc5,
      activeProduct.disc6,
      activeProduct.disc7,
      activeProduct.disc8,
    ].where((d) => d > 0).toList();

    final divansForConfigurator = isKasurOnly
        ? <String>[]
        : availableDivans
            .where((d) => d.trim().toLowerCase() != 'tanpa divan')
            .toList();
    final headboardsForConfigurator =
        isKasurOnly ? <String>[] : availableHeadboards;

    final cartCount = ref.watch(cartTotalItemsProvider);

    final brandSpecsAsync = ref.watch(brandSpecProvider);
    Map<String, dynamic>? matchedSpec;
    if (brandSpecsAsync.hasValue && brandSpecsAsync.value!.isNotEmpty) {
      final erpName = widget.product.name.toLowerCase();
      for (final spec in brandSpecsAsync.value!) {
        final brandName = (spec['name'] as String? ?? '').toLowerCase();
        if (brandName.isNotEmpty && erpName.contains(brandName)) {
          matchedSpec = spec as Map<String, dynamic>;
          break;
        }
      }
    }

    // Build default bonuses list for price section
    final defaultBonuses = _buildDefaultBonusList(activeProduct);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(cartCount, buildAnchor, effectiveSize),
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
                  onPageChanged: (i) =>
                      setState(() => _currentImageIndex = i),
                ),
                _buildProductDetails(
                  context: context,
                  activeProduct: activeProduct,
                  buildAnchor: buildAnchor,
                  availableSizes: availableSizes,
                  divansForConfigurator: divansForConfigurator,
                  headboardsForConfigurator: headboardsForConfigurator,
                  availableSorongs: availableSorongs,
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
                  kasurLookups: kasurLookups,
                  effectiveKasurLookup: effectiveKasurLookup,
                  divanLookups: divanLookups,
                  effectiveDivanLookup: effectiveDivanLookup,
                  headboardLookups: headboardLookups,
                  effectiveHeadboardLookup: effectiveHeadboardLookup,
                  sorongLookups: sorongLookups,
                  effectiveSorongLookup: effectiveSorongLookup,
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
              effectiveKasurLookup,
              effectiveDivanLookup,
              effectiveHeadboardLookup,
              effectiveSorongLookup,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── AppBar ─────────────────────────

  AppBar _buildAppBar(int cartCount, AnchorType buildAnchor, String effectiveSize) {
    return AppBar(
        backgroundColor: _isScrolled ? Colors.white : Colors.transparent,
        elevation: _isScrolled ? 2 : 0,
        scrolledUnderElevation: _isScrolled ? 2 : 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: _isScrolled
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        centerTitle: false,
        title: AnimatedOpacity(
          opacity: _isScrolled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
              (buildAnchor == AnchorType.kasur ||
                      (buildAnchor == AnchorType.divan && _divanHasSet))
                    ? '${selectedSize ?? widget.product.ukuran} • ${isKasurOnly ? 'Satuan' : 'Set Lengkap'}'
                    : (selectedSize ?? widget.product.ukuran),
                style: TextStyle(
                  color: Colors.grey.shade600,
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
              color: _isScrolled
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
          child: ref.watch(_sharingProvider)
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.black87,
                      size: 22,
                    ),
                    onPressed: _shareProduct,
                  ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _isScrolled
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
                    color: Colors.black87,
                    size: 22,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const CartBottomSheet(),
                    );
                  },
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.5),
                        shape: BoxShape.circle,
                      ),
                      child: FloatingBadge(
                        count: cartCount,
                        maxCount: 9,
                        padding: const EdgeInsets.all(4),
                        backgroundColor: Colors.pink,
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        textStyle: const TextStyle(
                          color: Colors.white,
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

  // ───────────────────────── Product Details (Orchestrator) ─────────────────────────

  Widget _buildProductDetails({
    required BuildContext context,
    required Product activeProduct,
    required AnchorType buildAnchor,
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

    return SliverList(
      delegate: SliverChildListDelegate([
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductInfoHeader(
                  category: widget.product.category,
                  productName: widget.product.name,
                ),
                const SizedBox(height: 20),

                // Dynamic price
                PriceBlock(
                  price: effectiveTotal,
                  originalPrice: activeProduct.pricelist > baseTotal
                      ? activeProduct.pricelist
                      : null,
                  spacing: 4,
                  formatPrice: AppFormatters.currencyIdr,
                  priceStyle:
                      Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                  originalPriceStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Configurator
                ProductConfiguratorSection(
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
                const SizedBox(height: 24),

                const Divider(height: 1),
                const SizedBox(height: 24),

                // Price breakdown + discount + bonus
                ProductPriceSection(
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
                      _targetTotalController.text = _totalCurrencyFormat
                          .format(_lastBaseTotalEup)
                          .trim();
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
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Installment simulation
                _buildInstallmentSection(effectiveTotal),
                const SizedBox(height: 32),

                // Specifications
                ProductSpecificationsSection(
                  product: activeProduct,
                  matchedSpec: matchedSpec,
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ───────────────────────── Installment Section ─────────────────────────

  Widget _buildInstallmentSection(double effectiveTotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                const Row(
                  children: [
            Icon(Icons.credit_card_outlined, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Simulasi Cicilan 0%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: installmentOptions.map((tenor) {
                    final isSelected = selectedInstallmentTenor == tenor;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: ChoiceChip(
                                showCheckmark: false,
                                label: Text('$tenor Bulan'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(
                                      () => selectedInstallmentTenor = tenor,
                                    );
                                  }
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Colors.black87,
                                elevation: 0,
                                pressElevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.black87
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Cicilan per bulan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: AppFormatters.currencyIdr(
                                    effectiveTotal / selectedInstallmentTenor,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / bln',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text(
                          '*Estimasi menggunakan kartu kredit cicilan 0%. Hubungi bank terkait untuk detail biaya layanan.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ],
    );
  }

  // ───────────────────────── Default Bonuses Builder ─────────────────────────

  List<Map<String, dynamic>> _buildDefaultBonusList(Product activeProduct) {
    return <Map<String, dynamic>>[
      if (activeProduct.bonus1 != null && activeProduct.bonus1!.isNotEmpty)
                {
                  'name': activeProduct.bonus1!,
                  'qty': activeProduct.qtyBonus1 ?? 1,
                  'max_qty': ((activeProduct.qtyBonus1 ?? 1) * 2),
                  'pl': activeProduct.plBonus1,
                  'is_custom': false,
                },
      if (activeProduct.bonus2 != null && activeProduct.bonus2!.isNotEmpty)
                {
                  'name': activeProduct.bonus2!,
                  'qty': activeProduct.qtyBonus2 ?? 1,
                  'max_qty': ((activeProduct.qtyBonus2 ?? 1) * 2),
                  'pl': activeProduct.plBonus2,
                  'is_custom': false,
                },
      if (activeProduct.bonus3 != null && activeProduct.bonus3!.isNotEmpty)
                {
                  'name': activeProduct.bonus3!,
                  'qty': activeProduct.qtyBonus3 ?? 1,
                  'max_qty': ((activeProduct.qtyBonus3 ?? 1) * 2),
                  'pl': activeProduct.plBonus3,
                  'is_custom': false,
                },
      if (activeProduct.bonus4 != null && activeProduct.bonus4!.isNotEmpty)
                {
                  'name': activeProduct.bonus4!,
                  'qty': activeProduct.qtyBonus4 ?? 1,
                  'max_qty': ((activeProduct.qtyBonus4 ?? 1) * 2),
                  'pl': activeProduct.plBonus4,
                  'is_custom': false,
                },
      if (activeProduct.bonus5 != null && activeProduct.bonus5!.isNotEmpty)
                {
                  'name': activeProduct.bonus5!,
                  'qty': activeProduct.qtyBonus5 ?? 1,
                  'max_qty': ((activeProduct.qtyBonus5 ?? 1) * 2),
                  'pl': activeProduct.plBonus5,
                  'is_custom': false,
                },
      if (activeProduct.bonus6 != null && activeProduct.bonus6!.isNotEmpty)
                {
                  'name': activeProduct.bonus6!,
                  'qty': activeProduct.qtyBonus6 ?? 1,
                  'max_qty': ((activeProduct.qtyBonus6 ?? 1) * 2),
                  'pl': activeProduct.plBonus6,
                  'is_custom': false,
                },
      if (activeProduct.bonus7 != null && activeProduct.bonus7!.isNotEmpty)
                {
                  'name': activeProduct.bonus7!,
                  'qty': activeProduct.qtyBonus7 ?? 1,
                  'max_qty': ((activeProduct.qtyBonus7 ?? 1) * 2),
                  'pl': activeProduct.plBonus7,
                  'is_custom': false,
                },
      if (activeProduct.bonus8 != null && activeProduct.bonus8!.isNotEmpty)
                {
                  'name': activeProduct.bonus8!,
                  'qty': activeProduct.qtyBonus8 ?? 1,
                  'max_qty': ((activeProduct.qtyBonus8 ?? 1) * 2),
                  'pl': activeProduct.plBonus8,
                  'is_custom': false,
                },
            ];
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
    final summary =
        '$effectiveSize · $effectiveDivan · $effectiveHeadboard · $effectiveSorong';

    final chosenParts = [
      effectiveDivan,
      effectiveHeadboard,
      effectiveSorong,
    ].where((s) => !s.startsWith('Tanpa ')).toList();
    final summaryForToast = chosenParts.isEmpty
        ? effectiveSize
        : '$effectiveSize · ${chosenParts.join(' · ')}';

    return ProductDetailBottomBar(
      isFavorite: isFavorite,
      onFavoriteTap: () {
        ref.read(favoritesProvider.notifier).toggleFavorite(widget.product.id);
        AppFeedback.show(
          context,
          message: isFavorite
              ? 'Dihapus dari favorit'
              : 'Ditambahkan ke favorit',
          type: AppFeedbackType.info,
          floating: true,
        );
      },
      onAddToCartTap: () {
        // Fabric/color validation
                            List<ItemLookup> lookupsFor(String name) {
                              final key = name.trim().toLowerCase();
          if (key.isEmpty || key.contains('tanpa')) return [];
                              final all = groupedLookups[key] ?? [];
          final filtered =
              all.where((l) => l.ukuran == effectiveSize).toList();
                              return filtered.isNotEmpty ? filtered : all;
                            }

                            final kLookups = lookupsFor(activeProduct.kasur);
                            if (kLookups.length > 1 &&
                                selectedKasurLookup == null &&
                                !_isKasurCustom) {
                              AppFeedback.show(
                                context,
                                message: 'Pilih Warna / Kain Kasur terlebih dahulu',
                                type: AppFeedbackType.error,
                                floating: true,
                              );
                              return;
                            }

                            final savingAsSet = !isKasurOnly;
                            if (savingAsSet) {
                              final hasHeadboardModel = selectedHeadboard != null &&
                                  selectedHeadboard!.trim().isNotEmpty &&
              !selectedHeadboard!.trim().toLowerCase().contains('tanpa');
                              if (!hasHeadboardModel) {
                                AppFeedback.show(
                                  context,
                                  message: 'Pilih model Sandaran terlebih dahulu.',
                                  type: AppFeedbackType.error,
                                  floating: true,
                                );
                                return;
                              }

                              final dLookups = lookupsFor(activeProduct.divan);
                              if (dLookups.length > 1 &&
                                  selectedDivanLookup == null &&
                                  !_isDivanCustom) {
                                AppFeedback.show(
                                  context,
                                  message: 'Pilih Warna / Kain Divan terlebih dahulu',
                                  type: AppFeedbackType.error,
                                  floating: true,
                                );
                                return;
                              }
          final hbLookups = lookupsFor(activeProduct.headboard);
                              if (hbLookups.isNotEmpty &&
                                  selectedHeadboardLookup == null &&
                                  !_isHeadboardCustom) {
                                AppFeedback.show(
                                  context,
                                  message: 'Pilih Warna / Kain Sandaran terlebih dahulu',
                                  type: AppFeedbackType.error,
                                  floating: true,
                                );
                                return;
                              }
                            }

        // Deterministic snapshot
        String resolveKain(bool isCustom, ItemLookup? lkp, String note) {
                              if (isCustom) return 'Custom';
                              return lkp?.jenisKain ?? '';
                            }

        String resolveWarna(bool isCustom, ItemLookup? lkp, String note) {
          if (isCustom) return note.isNotEmpty ? note : 'Custom';
                              return lkp?.warnaKain ?? '';
                            }

                            String resolveSku(bool isCustom, ItemLookup? lkp) {
                              if (isCustom) return _kCustomItemNum;
                              return lkp?.itemNum ?? '';
                            }

                            String componentDesc(
            String name, String sku, String kain, String warna) {
                              if (sku.isEmpty && kain.isEmpty) return name;
                              final parts = [name];
                              if (sku.isNotEmpty) parts.add(sku);
                              if (kain.isNotEmpty) parts.add(kain);
                              if (warna.isNotEmpty) parts.add(warna);
                              return parts.join(' - ');
                            }

        final kasurSkuFinal =
            resolveSku(_isKasurCustom, effectiveKasurLookup);
                            final kasurKainFinal = resolveKain(
            _isKasurCustom, effectiveKasurLookup, _customKasurCtrl.text.trim());
                            final kasurWarnaFinal = resolveWarna(
            _isKasurCustom, effectiveKasurLookup, _customKasurCtrl.text.trim());

                            final divanSkuFinal = savingAsSet
            ? resolveSku(_isDivanCustom, effectiveDivanLookup)
                                : '';
                            final divanKainFinal = savingAsSet
                                ? resolveKain(
                _isDivanCustom, effectiveDivanLookup, _customDivanCtrl.text.trim())
                                : '';
                            final divanWarnaFinal = savingAsSet
                                ? resolveWarna(
                _isDivanCustom, effectiveDivanLookup, _customDivanCtrl.text.trim())
                                : '';

                            final hbSkuFinal = savingAsSet
            ? resolveSku(_isHeadboardCustom, effectiveHeadboardLookup)
                                : '';
                            final hbKainFinal = savingAsSet
                                ? resolveKain(
                _isHeadboardCustom, effectiveHeadboardLookup, _customHbCtrl.text.trim())
                                : '';
                            final hbWarnaFinal = savingAsSet
                                ? resolveWarna(
                _isHeadboardCustom, effectiveHeadboardLookup, _customHbCtrl.text.trim())
                                : '';

                            final sorongSkuFinal = savingAsSet
            ? resolveSku(_isSorongCustom, effectiveSorongLookup)
                                : '';
                            final sorongKainFinal = savingAsSet
                                ? resolveKain(
                _isSorongCustom, effectiveSorongLookup, _customSorongCtrl.text.trim())
                                : '';
                            final sorongWarnaFinal = savingAsSet
                                ? resolveWarna(
                _isSorongCustom, effectiveSorongLookup, _customSorongCtrl.text.trim())
                                : '';

                            final descLines = <String>[];
                            if (activeProduct.kasur.isNotEmpty) {
          descLines.add(componentDesc(
              activeProduct.kasur, kasurSkuFinal, kasurKainFinal, kasurWarnaFinal));
                            }
                            if (savingAsSet) {
          if (effectiveDivan.toLowerCase() != 'tanpa divan' &&
                                  divanSkuFinal.isNotEmpty) {
            descLines.add(componentDesc(
                effectiveDivan, divanSkuFinal, divanKainFinal, divanWarnaFinal));
          }
          if (effectiveHeadboard.toLowerCase() != 'tanpa headboard' &&
                                  hbSkuFinal.isNotEmpty) {
            descLines.add(componentDesc(
                effectiveHeadboard, hbSkuFinal, hbKainFinal, hbWarnaFinal));
          }
          if (effectiveSorong.toLowerCase() != 'tanpa sorong' &&
                                  sorongSkuFinal.isNotEmpty) {
            descLines.add(componentDesc(
                effectiveSorong, sorongSkuFinal, sorongKainFinal, sorongWarnaFinal));
                              }
                            }
                            final componentDescNote = descLines.join('\n');

                            final componentSum = finalKasurPrice +
                                finalDivanPrice +
                                finalHeadboardPrice +
                                finalSorongPrice;
        final roundingDiff = totalFinalPrice - componentSum;

                            final configuredProduct = activeProduct.copyWith(
                              price: totalFinalPrice,
                              eupKasur: finalKasurPrice + roundingDiff,
                              eupDivan: finalDivanPrice,
                              eupHeadboard: finalHeadboardPrice,
                              eupSorong: finalSorongPrice,
                              description: componentDescNote.isNotEmpty
                                  ? '${activeProduct.description}\n[$summary]\n$componentDescNote'
                                  : '${activeProduct.description}\n[$summary]',
                              isSet: savingAsSet,
          divan: savingAsSet ? effectiveDivan : 'Tanpa Divan',
          headboard: savingAsSet ? effectiveHeadboard : 'Tanpa Headboard',
          sorong: savingAsSet ? effectiveSorong : 'Tanpa Sorong',
        );

                            ItemLookup? lookupFor(String? tipe) {
          if (tipe == null || tipe.trim().isEmpty) return null;
                              final key = tipe.trim().toLowerCase();
                              final candidates = (groupedLookups[key] ?? [])
                                  .where((l) => l.ukuran == effectiveSize)
                                  .toList();
                              return candidates.isNotEmpty
                                  ? candidates.first
                                  : (groupedLookups[key] ?? []).firstOrNull;
                            }

                            final rawBonuses = <(String, int)>[
                              if ((activeProduct.bonus1 ?? '').isNotEmpty)
            (activeProduct.bonus1!, activeProduct.qtyBonus1 ?? 1),
                              if ((activeProduct.bonus2 ?? '').isNotEmpty)
            (activeProduct.bonus2!, activeProduct.qtyBonus2 ?? 1),
                              if ((activeProduct.bonus3 ?? '').isNotEmpty)
            (activeProduct.bonus3!, activeProduct.qtyBonus3 ?? 1),
                              if ((activeProduct.bonus4 ?? '').isNotEmpty)
            (activeProduct.bonus4!, activeProduct.qtyBonus4 ?? 1),
                              if ((activeProduct.bonus5 ?? '').isNotEmpty)
            (activeProduct.bonus5!, activeProduct.qtyBonus5 ?? 1),
                              if ((activeProduct.bonus6 ?? '').isNotEmpty)
            (activeProduct.bonus6!, activeProduct.qtyBonus6 ?? 1),
                              if ((activeProduct.bonus7 ?? '').isNotEmpty)
            (activeProduct.bonus7!, activeProduct.qtyBonus7 ?? 1),
                              if ((activeProduct.bonus8 ?? '').isNotEmpty)
            (activeProduct.bonus8!, activeProduct.qtyBonus8 ?? 1),
                            ];
                            final bonusSnapshots = rawBonuses.map((b) {
                              final (name, qty) = b;
                              final lu = lookupFor(name);
                              return CartBonusSnapshot(
                                name: name,
                                qty: qty,
                                sku: lu?.itemNum ?? '',
                              );
                            }).toList();

                            final discPct1 = appliedDiscounts.isNotEmpty
                                ? appliedDiscounts[0] * 100
                                : 0.0;
                            final discPct2 = appliedDiscounts.length >= 2
                                ? appliedDiscounts[1] * 100
                                : 0.0;
                            final discPct3 = appliedDiscounts.length >= 3
                                ? appliedDiscounts[2] * 100
                                : 0.0;

                            final snapshotItem = CartItem(
                              product: configuredProduct,
                              masterProduct: widget.product,
                              kasurSku: kasurSkuFinal,
                              divanSku: divanSkuFinal,
                              divanKain: divanKainFinal,
                              divanWarna: divanWarnaFinal,
                              sandaranSku: hbSkuFinal,
                              sandaranKain: hbKainFinal,
                              sandaranWarna: hbWarnaFinal,
                              sorongSku: sorongSkuFinal,
                              sorongKain: sorongKainFinal,
                              sorongWarna: sorongWarnaFinal,
          originalEupKasur: activeProduct.eupKasur,
          originalEupDivan: activeProduct.eupDivan,
          originalEupHeadboard: activeProduct.eupHeadboard,
          originalEupSorong: activeProduct.eupSorong,
                              discount1: discPct1,
                              discount2: discPct2,
                              discount3: discPct3,
                              bonusSnapshots: bonusSnapshots,
                            );

                            if (_isEditMode) {
                              ref.read(cartProvider.notifier).updateCartItem(
                                    widget.cartIndex!,
                                    snapshotItem,
                                  );
                              Navigator.of(context).pop();
                              AppFeedback.show(
                                context,
                                message: 'Keranjang diperbarui',
                                type: AppFeedbackType.success,
                                floating: true,
                              );
                            } else {
          ref.read(cartProvider.notifier).addItem(snapshotItem);
                              AppFeedback.show(
                                context,
            message:
                '${widget.product.name} ($summaryForToast) ditambahkan ke keranjang',
                                type: AppFeedbackType.success,
                                floating: true,
                              );
                            }
      },
      isEditMode: _isEditMode,
      priceLabel: AppFormatters.currencyIdr(totalFinalPrice),
    );
  }
}
