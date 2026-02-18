import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/quantity_control.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/price_row.dart';
import '../../../../services/accessories_service.dart';
import '../../../../services/product_options_service.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../theme/app_colors.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/presentation/widgets/dialogs/edit_price_dialog.dart';
import 'package:collection/collection.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/leader_service.dart';
import '../controllers/cart_item_controller.dart';
import 'bonus_selector_dialog.dart';
import 'add_bonus_dialog.dart';
import '../../../../features/approval/data/models/approval_model.dart';
import '../../../product/domain/usecases/fetch_lookup_items_usecase.dart';
import '../../../product/presentation/widgets/product_detail/item_pricing_modal.dart';
import '../../domain/entities/cart_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import 'cart_item/cart_item_widgets.dart';

class CartItemWidget extends StatefulWidget {
  final CartEntity item;
  const CartItemWidget({super.key, required this.item});

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget>
    with AutomaticKeepAliveClientMixin {
  bool isExpanded = false;
  bool _autoFabricChecked = false;
  final CartItemController _controller = CartItemController();
  bool _isEditingPrice = false;

  @override
  bool get wantKeepAlive => true;
  static const double _avatarSize = 40.0;
  // radius dipindahkan ke widget-widget yang diekstrak

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _isNoneComponent(String value) => _controller.isNoneComponent(value);

  /// Check if value is valid for display (not empty, "-", "0", or starts with "tanpa")
  bool _isValidItemValue(String value) {
    if (value.isEmpty) return false;
    final trimmed = value.trim();
    if (trimmed == '-') return false;
    if (trimmed == '0') return false;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('tanpa')) return false;
    if (lower == 'tidak ada kasur') return false;
    if (lower == 'tidak ada divan') return false;
    if (lower == 'tidak ada headboard') return false;
    if (lower == 'tidak ada sorong') return false;
    return true;
  }

  /// Get primary display name based on priority: Kasur → Divan → Headboard → Sorong
  String _getPrimaryDisplayName() {
    final p = widget.item.product;
    if (_isValidItemValue(p.kasur)) return p.kasur;
    if (_isValidItemValue(p.divan)) return p.divan;
    if (_isValidItemValue(p.headboard)) return p.headboard;
    if (_isValidItemValue(p.sorong)) return p.sorong;
    return p.brand; // Fallback to brand
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectFabricDefaults();
    });
  }

  @override
  void didUpdateWidget(covariant CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if quantity changed
    final quantityChanged = widget.item.quantity != oldWidget.item.quantity;

    // Check if bonus changed
    final bonusChanged = !_listEquals(
      widget.item.product.bonus,
      oldWidget.item.product.bonus,
    );

    // Check if product changed (which includes bonus)
    final productChanged = widget.item.product != oldWidget.item.product;

    if (quantityChanged || bonusChanged || productChanged) {
      if (mounted) {
        setState(() {});
      }
      if (quantityChanged && widget.item.quantity > oldWidget.item.quantity) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoFillNewUnitsIfSingleOption();
        });
      }
    }
  }

  Future<void> _autoSelectFabricDefaults() async {
    if (_autoFabricChecked) return;
    _autoFabricChecked = true;
    await _controller.autoSelectFabricDefaults(context, widget.item,
        mounted: () => mounted);
    if (mounted) setState(() {});
  }

  Future<void> _autoFillNewUnitsIfSingleOption() async {
    final product = widget.item.product;
    await Future.wait([
      _controller.autoFillNewUnitsIfSingleOption(context, widget.item,
          itemType: 'kasur',
          tipeForLookup: product.kasur,
          mounted: () => mounted),
      _controller.autoFillNewUnitsIfSingleOption(context, widget.item,
          itemType: 'divan',
          tipeForLookup: product.divan,
          mounted: () => mounted),
      _controller.autoFillNewUnitsIfSingleOption(context, widget.item,
          itemType: 'headboard',
          tipeForLookup: product.headboard,
          mounted: () => mounted),
      _controller.autoFillNewUnitsIfSingleOption(context, widget.item,
          itemType: 'sorong',
          tipeForLookup: product.sorong,
          mounted: () => mounted),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (_isEditingPrice) return;
        final newDiscountPercentages =
            state.productDiscountsPercentage[widget.item.product.id];
        final hasPositiveDiscount =
            (newDiscountPercentages ?? const <double>[]).any((d) => d > 0);
        final currentHasPositiveDiscount =
            widget.item.discountPercentages.any((d) => d > 0);

        final isDiscountReset = currentHasPositiveDiscount &&
            !hasPositiveDiscount &&
            newDiscountPercentages != null;

        if (newDiscountPercentages != null &&
            (hasPositiveDiscount || isDiscountReset) &&
            !_listEquals(
                newDiscountPercentages, widget.item.discountPercentages)) {
          double calculatedPrice = widget.item.product.endUserPrice;
          for (final percentage in newDiscountPercentages) {
            if (percentage > 0) {
              calculatedPrice = calculatedPrice * (1 - (percentage / 100));
            }
          }
          context.read<CartBloc>().add(UpdateCartDiscounts(
                productId: widget.item.product.id,
                oldNetPrice: widget.item.netPrice,
                discountPercentages: newDiscountPercentages,
                newNetPrice: calculatedPrice,
                cartLineId: widget.item.cartLineId,
              ));
          return;
        }

        final newPrice = state.roundedPrices[widget.item.product.id];
        if (newPrice != null && newPrice != widget.item.netPrice) {
          context.read<CartBloc>().add(UpdateCartPrice(
                productId: widget.item.product.id,
                oldNetPrice: widget.item.netPrice,
                newNetPrice: newPrice,
                cartLineId: widget.item.cartLineId,
              ));
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
            horizontal: AppPadding.p10, vertical: AppPadding.p10 / 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.p10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: () => setState(() => isExpanded = !isExpanded),
                      child: _buildHeaderWithoutQuantity(context, isDark),
                    ),
                  ),
                  Builder(
                    builder: (builderContext) => QuantityControl(
                      quantity: widget.item.quantity,
                      onIncrement: () {
                        builderContext.read<CartBloc>().add(UpdateCartQuantity(
                              productId: widget.item.product.id,
                              netPrice: widget.item.netPrice,
                              quantity: widget.item.quantity + 1,
                              cartLineId: widget.item.cartLineId,
                            ));
                      },
                      onDecrement: () => _decrement(builderContext),
                    ),
                  ),
                ],
              ),
              // Animasi buka-tutup detail
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: const SizedBox.shrink(),
                secondChild: _buildDetailsSection(context, isDark),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
              const SizedBox(height: AppPadding.p10),
              _buildTotalPrice(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // --- SEMUA METHOD HELPER DIKEMBALIKAN KE DALAM STATE ---

  /// Check if bonus is valid for display
  bool _isValidBonus(BonusItem b) {
    if (b.name.isEmpty) return false;
    if (b.name.trim() == '0') return false;
    if (b.name.trim() == '-') return false;
    if (b.quantity <= 0) return false;
    return true;
  }

  Widget _buildDetailsSection(BuildContext context, bool isDark) {
    final hasBonus = widget.item.product.bonus.any(_isValidBonus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppPadding.p10),
        // Menggunakan ProductDetailsSection widget yang sudah diekstrak
        ProductDetailsSection(
          product: widget.item.product,
          isDark: isDark,
          onShowOptions: (type, currentValue) =>
              _showOptionsDialog(context, type, currentValue, isDark),
          getSorongOptions: _getSorongOptions,
        ),
        // Fabric selectors per component if available
        if (!_isNoneComponent(widget.item.product.kasur))
          FabricSelector(
            item: widget.item,
            isDark: isDark,
            itemType: 'kasur',
            onOpenFabricSelector: (itemType, unitIndex) =>
                _openFabricSelector(context, itemType, unitIndex),
          ),
        if (!_isNoneComponent(widget.item.product.divan))
          FabricSelector(
            item: widget.item,
            isDark: isDark,
            itemType: 'divan',
            onOpenFabricSelector: (itemType, unitIndex) =>
                _openFabricSelector(context, itemType, unitIndex),
          ),
        if (!_isNoneComponent(widget.item.product.headboard))
          FabricSelector(
            item: widget.item,
            isDark: isDark,
            itemType: 'headboard',
            onOpenFabricSelector: (itemType, unitIndex) =>
                _openFabricSelector(context, itemType, unitIndex),
          ),
        if (!_isNoneComponent(widget.item.product.sorong))
          FabricSelector(
            item: widget.item,
            isDark: isDark,
            itemType: 'sorong',
            onOpenFabricSelector: (itemType, unitIndex) =>
                _openFabricSelector(context, itemType, unitIndex),
          ),
        if (hasBonus) const SizedBox(height: AppPadding.p10),
        // Menggunakan BonusSection widget yang sudah diekstrak
        // Wrap dengan BlocBuilder untuk rebuild ketika cart state berubah
        BlocBuilder<CartBloc, CartState>(
          buildWhen: (previous, current) {
            if (current is CartLoaded) {
              // Rebuild jika item ini berubah di cart state
              final currentItem = current.cartItems.firstWhere(
                (item) => item.cartLineId == widget.item.cartLineId,
                orElse: () => widget.item,
              );
              return currentItem.product.bonus != widget.item.product.bonus ||
                  currentItem.product != widget.item.product;
            }
            return false;
          },
          builder: (context, state) {
            // Get latest item from cart state
            CartEntity currentItem = widget.item;
            if (state is CartLoaded) {
              final foundItem = state.cartItems.firstWhere(
                (item) => item.cartLineId == widget.item.cartLineId,
                orElse: () => widget.item,
              );
              currentItem = foundItem;
            }

            return BonusSection(
              item: currentItem,
              isDark: isDark,
              onSelectBonus: (index, bonus) =>
                  _showBonusItemSelector(context, index, bonus),
              onRemoveBonus: (index) => _removeBonus(context, index),
              onAddBonus: () => _showAddBonusDialog(context, currentItem),
            );
          },
        ),
        const SizedBox(height: AppPadding.p10),
        // Menggunakan PriceInfoSection widget yang sudah diekstrak
        PriceInfoSection(
          item: widget.item,
          isDark: isDark,
          onShowPriceActions: () => _showPriceActions(context),
        ),
      ],
    );
  }

  // _buildFabricSelector dipindahkan ke FabricSelector widget

  Future<void> _openFabricSelector(
      BuildContext context, String itemType, int unitIndex) async {
    try {
      // Tentukan tipe yang akan dicocokkan berdasarkan komponen
      final p = widget.item.product;
      String tipeForLookup;
      switch (itemType) {
        case 'divan':
          tipeForLookup = p.divan;
          break;
        case 'headboard':
          tipeForLookup = p.headboard;
          break;
        case 'sorong':
          tipeForLookup = p.sorong;
          break;
        case 'kasur':
        default:
          tipeForLookup = p.kasur;
      }
      final cartBloc = context.read<CartBloc>();
      final fetchLookupItemsUseCase = locator<FetchLookupItemsUseCase>();
      final list = await fetchLookupItemsUseCase(
        brand: p.brand,
        kasur: tipeForLookup,
        divan: p.divan.isNotEmpty ? p.divan : null,
        headboard: p.headboard.isNotEmpty ? p.headboard : null,
        sorong: p.sorong.isNotEmpty ? p.sorong : null,
        ukuran: p.ukuran,
        contextItemType: itemType,
      );

      if (!mounted) return;
      // Auto-apply when only one option available
      if (list.length == 1) {
        if (!mounted) return;
        final it = list.first;
        cartBloc.add(UpdateCartSelectedItemNumber(
          productId: widget.item.product.id,
          netPrice: widget.item.netPrice,
          itemType: itemType,
          itemNumber: it.itemNum,
          itemDescription: it.itemDesc,
          jenisKain: it.jenisKain,
          warnaKain: it.warnaKain,
          unitIndex: unitIndex,
          cartLineId: widget.item.cartLineId,
        ));
        if (!mounted) return;
        if (!context.mounted) return;
        CustomToast.showToast('Kain default diterapkan', ToastType.info);
        return;
      }

      if (list.isEmpty) {
        if (!mounted) return;
        if (!context.mounted) return;
        CustomToast.showToast('Pilihan kain tidak tersedia', ToastType.warning);
        return;
      }

      if (!mounted) return;
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) {
          final TextEditingController customController =
              TextEditingController();
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Pilih Kain',
                    style: TextStyle(fontFamily: 'Inter')),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 340,
                  child: ListView.builder(
                    itemCount: list.length + 1, // +1 for Custom option
                    itemBuilder: (c, i) {
                      // Custom option as first item
                      if (i == 0) {
                        return ListTile(
                          title: const Text(
                            'Custom',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Masukkan kain custom',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                            ),
                          ),
                          leading: const Icon(Icons.edit),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) {
                                return AlertDialog(
                                  title: const Text(
                                    'Kain Custom',
                                    style: TextStyle(fontFamily: 'Inter'),
                                  ),
                                  content: TextField(
                                    controller: customController,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Masukkan nama kain...',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text('Batal',
                                          style:
                                              TextStyle(fontFamily: 'Inter')),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (customController.text.isNotEmpty) {
                                          context
                                              .read<CartBloc>()
                                              .add(UpdateCartSelectedItemNumber(
                                                productId:
                                                    widget.item.product.id,
                                                netPrice: widget.item.netPrice,
                                                itemType: itemType,
                                                itemNumber: 'CUSTOM',
                                                itemDescription:
                                                    customController.text,
                                                jenisKain:
                                                    customController.text,
                                                warnaKain: '',
                                                unitIndex: unitIndex,
                                                cartLineId:
                                                    widget.item.cartLineId,
                                              ));
                                          Navigator.pop(dialogCtx);
                                          Navigator.pop(ctx);
                                        }
                                      },
                                      child: const Text('Simpan',
                                          style:
                                              TextStyle(fontFamily: 'Inter')),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      }

                      // Regular fabric items
                      final it = list[i - 1]; // -1 because Custom is first
                      final main = [it.jenisKain, it.warnaKain]
                          .where((e) => (e ?? '').isNotEmpty)
                          .join(' - ');
                      final sub = it.itemDesc;
                      return ListTile(
                        title: Text(
                          main.isEmpty
                              ? (sub.isEmpty ? it.itemNum : sub)
                              : main,
                          style: const TextStyle(fontFamily: 'Inter'),
                        ),
                        subtitle: sub.isNotEmpty
                            ? Text(sub,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 12))
                            : null,
                        onTap: () {
                          context
                              .read<CartBloc>()
                              .add(UpdateCartSelectedItemNumber(
                                productId: widget.item.product.id,
                                netPrice: widget.item.netPrice,
                                itemType: itemType,
                                itemNumber: it.itemNum,
                                itemDescription: it.itemDesc,
                                jenisKain: it.jenisKain,
                                warnaKain: it.warnaKain,
                                unitIndex: unitIndex,
                                cartLineId: widget.item.cartLineId,
                              ));
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup',
                        style: TextStyle(fontFamily: 'Inter')),
                  )
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      CustomToast.showToast('Gagal memuat kain: $e', ToastType.error);
    }
  }

  Widget _buildHeaderWithoutQuantity(BuildContext context, bool isDark) {
    return Row(
      children: [
        Checkbox(
          value: widget.item.isSelected,
          onChanged: (value) {
            context.read<CartBloc>().add(ToggleCartItemSelection(
                  productId: widget.item.product.id,
                  netPrice: widget.item.netPrice,
                  cartLineId: widget.item.cartLineId,
                ));
          },
        ),
        CircleAvatar(
          radius: _avatarSize / 2,
          backgroundColor: isDark
              ? AppColors.accentDark
              : Theme.of(context).primaryColorLight,
          child: Icon(
            Icons.bed,
            color: isDark
                ? AppColors.textPrimaryDark
                : Theme.of(context).primaryColor,
            size: _avatarSize * 0.5,
          ),
        ),
        const SizedBox(width: AppPadding.p10),
        Expanded(
          child: Text(
            '${_getPrimaryDisplayName()} - ${widget.item.product.ukuran}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
          ),
        ),
      ],
    );
  }

  void _decrement(BuildContext context) async {
    if (widget.item.quantity > 1) {
      context.read<CartBloc>().add(UpdateCartQuantity(
            productId: widget.item.product.id,
            netPrice: widget.item.netPrice,
            quantity: widget.item.quantity - 1,
            cartLineId: widget.item.cartLineId,
          ));
    } else {
      // Menggunakan ConfirmationDialog widget yang reusable
      final confirm = await ConfirmationDialog.showDelete(
        context: context,
        title: 'Konfirmasi',
        message: 'Yakin ingin menghapus item ini?',
      );

      if (confirm == true) {
        if (!mounted) return;
        if (!context.mounted) return;
        final cartBloc = context.read<CartBloc>();
        cartBloc.add(RemoveFromCart(
            productId: widget.item.product.id,
            netPrice: widget.item.netPrice,
            cartLineId: widget.item.cartLineId));
      }
    }
  }

  Future<List<String>> _getSorongOptions(ProductEntity product) async {
    try {
      final productOptionsService = locator<ProductOptionsService>();
      return await productOptionsService.getSorongOptions(
        area: product.area,
        channel: product.channel,
        brand: product.brand,
        kasur: product.kasur,
        divan: product.divan,
        headboard: product.headboard,
      );
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  // _buildBonus, _bonusBox dipindahkan ke BonusSection widget
  // _buildPriceInfo dipindahkan ke PriceInfoSection widget

  void _showPriceActions(BuildContext context) {
    final product = widget.item.product;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Harga'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _openEditPrice(context, product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Diskon Produk'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _openInfo(context, product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.price_change_rounded),
                title: const Text('Rincian Harga per Item'),
                subtitle: widget.item.discountPercentages.any((d) => d > 0)
                    ? Text(
                        'Dengan diskon ${widget.item.discountPercentages.where((d) => d > 0).map((d) => d % 1 == 0 ? '${d.toInt()}%' : '${d.toStringAsFixed(1)}%').join(' + ')}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ItemPricingModal.show(
                    context,
                    product,
                    discountPercentages: widget.item.discountPercentages,
                    quantity: widget.item.quantity,
                  );
                },
              ),
              const SizedBox(height: AppPadding.p8),
            ],
          ),
        );
      },
    );
  }

  void _openEditPrice(BuildContext context, ProductEntity product) {
    // Ensure product is available in ProductBloc state for editing
    context.read<ProductBloc>().add(SelectProduct(product));
    _isEditingPrice = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditPriceDialog(
        product: product,
        initialNetPrice: widget.item.netPrice,
      ),
    ).whenComplete(() {
      // Re-enable sync and apply committed changes from ProductBloc
      _isEditingPrice = false;
      _syncFromProductState();
    });
  }

  void _syncFromProductState() {
    final state = context.read<ProductBloc>().state;
    final pid = widget.item.product.id;
    final newPrice = state.roundedPrices[pid];
    final newDiscounts = state.productDiscountsPercentage[pid];
    final hasPositiveDiscount =
        (newDiscounts ?? const <double>[]).any((d) => d > 0);
    final currentHasPositiveDiscount =
        widget.item.discountPercentages.any((d) => d > 0);

    final isDiscountReset = currentHasPositiveDiscount &&
        !hasPositiveDiscount &&
        newDiscounts != null;

    if (newDiscounts != null &&
        (hasPositiveDiscount || isDiscountReset) &&
        !_listEquals(newDiscounts, widget.item.discountPercentages)) {
      double calculatedPrice = widget.item.product.endUserPrice;
      for (final percentage in newDiscounts) {
        if (percentage > 0) {
          calculatedPrice = calculatedPrice * (1 - (percentage / 100));
        }
      }
      context.read<CartBloc>().add(UpdateCartDiscounts(
            productId: pid,
            oldNetPrice: widget.item.netPrice,
            discountPercentages: newDiscounts,
            newNetPrice: calculatedPrice,
            cartLineId: widget.item.cartLineId,
          ));
      return;
    }
    if (newPrice != null && newPrice != widget.item.netPrice) {
      context.read<CartBloc>().add(UpdateCartPrice(
            productId: pid,
            oldNetPrice: widget.item.netPrice,
            newNetPrice: newPrice,
            cartLineId: widget.item.cartLineId,
          ));
    }
  }

  void _openInfo(BuildContext context, ProductEntity product) {
    // Ensure product is available in ProductBloc state for editing
    context.read<ProductBloc>().add(SelectProduct(product));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CartInfoDialog(
        product: product,
        discountPercentages: widget.item.discountPercentages,
        netPrice: widget.item.netPrice,
      ),
    );
  }

  // _priceRow dipindahkan ke PriceInfoSection widget

  Widget _buildTotalPrice(BuildContext context, bool isDark) {
    final total = widget.item.netPrice * widget.item.quantity;
    // Menggunakan TotalPriceContainer widget yang reusable
    return TotalPriceContainer(
      value: total,
      padding: const EdgeInsets.symmetric(
          vertical: AppPadding.p10 / 2, horizontal: AppPadding.p10),
      borderRadius: 12,
    );
  }

  void _removeBonus(BuildContext context, int bonusIndex) async {
    // Menggunakan ConfirmationDialog widget yang reusable
    final confirm = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Hapus Bonus',
      message: 'Apakah Anda yakin ingin menghapus bonus ini?',
    );

    if (confirm == true) {
      if (!mounted) return;
      if (!context.mounted) return;
      context.read<CartBloc>().add(RemoveCartBonus(
            productId: widget.item.product.id,
            netPrice: widget.item.netPrice,
            bonusIndex: bonusIndex,
          ));
    }
  }

  void _showBonusItemSelector(
      BuildContext context, int bonusIndex, BonusItem bonus) async {
    try {
      // Load accessories from service
      final accessories = await AccessoriesService.getAccessoriesFromNewAPI();

      if (!mounted) return;

      // Create a stateful dialog with search functionality
      if (!mounted) return;
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => BonusSelectorDialog(
          accessories: accessories,
          bonusIndex: bonusIndex,
          productId: widget.item.product.id,
          netPrice: widget.item.netPrice,
          currentQuantity: bonus.quantity,
          cartLineId: widget.item.cartLineId,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      CustomToast.showToast('Error loading accessories: $e', ToastType.error);
    }
  }

  /// Show dialog to add a new bonus to cart item
  void _showAddBonusDialog(BuildContext context, CartEntity currentItem) async {
    try {
      // Load accessories from service
      final accessories = await AccessoriesService.getAccessoriesFromNewAPI();

      if (!mounted) return;
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AddBonusDialog(
          accessories: accessories,
          productId: currentItem.product.id,
          netPrice: currentItem.netPrice,
          cartLineId: currentItem.cartLineId,
          productQuantity: currentItem.quantity,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      CustomToast.showToast('Error loading accessories: $e', ToastType.error);
    }
  }

  void _showOptionsDialog(BuildContext context, String type,
      String currentValue, bool isDark) async {
    try {
      final productOptionsService = locator<ProductOptionsService>();
      List<String> options = [];

      if (type == 'divan') {
        options = await productOptionsService.getDivanOptions(
          area: widget.item.product.area,
          channel: widget.item.product.channel,
          brand: widget.item.product.brand,
          kasur: widget.item.product.kasur,
        );
      } else if (type == 'headboard') {
        options = await productOptionsService.getHeadboardOptions(
          area: widget.item.product.area,
          channel: widget.item.product.channel,
          brand: widget.item.product.brand,
          kasur: widget.item.product.kasur,
        );
      } else if (type == 'sorong') {
        options = await productOptionsService.getSorongOptions(
          area: widget.item.product.area,
          channel: widget.item.product.channel,
          brand: widget.item.product.brand,
          kasur: widget.item.product.kasur,
          divan: widget.item.product.divan,
          headboard: widget.item.product.headboard,
        );
      } else if (type == 'ukuran') {
        options = await productOptionsService.getUkuranOptions(
          area: widget.item.product.area,
          channel: widget.item.product.channel,
          brand: widget.item.product.brand,
          kasur: widget.item.product.kasur,
          divan: widget.item.product.divan,
          headboard: widget.item.product.headboard,
          sorong: widget.item.product.sorong,
        );
      }

      if (!mounted) return;

      if (options.isEmpty) {
        if (!mounted) return;
        if (!context.mounted) return;
        CustomToast.showToast(
            'Tidak ada opsi $type yang tersedia', ToastType.warning);
        return;
      }

      if (!mounted) return;
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Pilih $type',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Builder(builder: (context) {
            double dialogHeight = options.length * 52.0;
            if (dialogHeight > 360.0) dialogHeight = 360.0;

            return SizedBox(
              width: double.maxFinite,
              height: dialogHeight,
              child: ListView.builder(
                itemExtent: 48.0,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      context.read<CartBloc>().add(UpdateCartProductDetail(
                            productId: widget.item.product.id,
                            netPrice: widget.item.netPrice,
                            detailType: type,
                            detailValue: option,
                            cartLineId: widget.item.cartLineId,
                          ));
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            );
          }),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      CustomToast.showToast('Error loading $type options: $e', ToastType.error);
    }
  }
}

// Cart Info Dialog Widget
class CartInfoDialog extends StatefulWidget {
  final ProductEntity product;
  final List<double> discountPercentages;
  final double netPrice;

  const CartInfoDialog({
    super.key,
    required this.product,
    required this.discountPercentages,
    required this.netPrice,
  });

  @override
  State<CartInfoDialog> createState() => _CartInfoDialogState();
}

class _CartInfoDialogState extends State<CartInfoDialog> {
  late List<TextEditingController> percentageControllers;
  late List<TextEditingController> nominalControllers;
  late double basePrice;
  late List<double> _initialPercentages;
  late List<double> _initialNominals;
  bool hasChanged = false;
  LeaderByUserModel? _leaderData;

  void _checkHasChanged() {
    final currentPercentages = percentageControllers
        .map((c) => double.tryParse(c.text) ?? 0.0)
        .toList();
    final currentNominals = nominalControllers
        .map((c) => FormatHelper.parseCurrencyToDouble(c.text))
        .toList();
    setState(() {
      hasChanged = !const ListEquality()
              .equals(currentPercentages, _initialPercentages) ||
          !const ListEquality().equals(currentNominals, _initialNominals);
    });
  }

  @override
  void initState() {
    super.initState();
    // Use product's original endUserPrice as base price for discount calculations
    basePrice = widget.product.endUserPrice;

    // Initialize with cart's discount percentages
    _initialPercentages = List.from(widget.discountPercentages);
    _initialNominals = List.filled(5, 0.0);

    percentageControllers = List.generate(
      5,
      (i) => TextEditingController(
          text: (i < _initialPercentages.length && _initialPercentages[i] > 0)
              ? _initialPercentages[i].toStringAsFixed(2)
              : ""),
    );

    // Calculate initial nominals from percentages
    nominalControllers = List.generate(5, (i) {
      if (i < _initialPercentages.length && _initialPercentages[i] > 0) {
        double remainingPrice = basePrice;
        for (int j = 0; j < i; j++) {
          remainingPrice -= _initialNominals[j];
        }
        double nominal =
            (remainingPrice * (_initialPercentages[i] / 100)).roundToDouble();
        _initialNominals[i] = nominal;
        return TextEditingController(
            text: FormatHelper.formatCurrency(nominal));
      } else {
        return TextEditingController(text: "");
      }
    });

    hasChanged = false;
    _loadLeaderData();
  }

  Future<void> _loadLeaderData() async {
    try {
      if (kDebugMode) {
        print(
            '[DEBUG] CartInfoDialog._loadLeaderData: Loading leader data for product ${widget.product.id} (${widget.product.kasur})');
        print('  - Current Discounts: ${widget.discountPercentages}');
        print('  - Net Price: ${widget.netPrice}');
      }
      final leaderService = locator<LeaderService>();
      final leaderData = await leaderService.getLeaderByUser();

      setState(() {
        _leaderData = leaderData;
      });
      if (kDebugMode) {
        print(
            '[DEBUG] CartInfoDialog._loadLeaderData: Leader data loaded: ${leaderData != null ? "Success" : "Failed"}');
        if (leaderData != null) {
          print(
              '  - Product: ${widget.product.kasur} (ID: ${widget.product.id})');
          print('  - Base Price: ${widget.product.endUserPrice}');
          print('  - Cart Discounts: ${widget.discountPercentages}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            '[DEBUG] CartInfoDialog._loadLeaderData: Error loading leader data: $e');
      }
      // No-op, leader data will be null if loading fails
    }
  }

  @override
  void dispose() {
    for (var controller in percentageControllers) {
      controller.removeListener(_checkHasChanged);
      controller.dispose();
    }
    for (var controller in nominalControllers) {
      controller.removeListener(_checkHasChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void updateNominal(int index) {
    setState(() {
      double remainingPrice = basePrice;
      for (int i = 0; i < index; i++) {
        remainingPrice -=
            FormatHelper.parseCurrencyToDouble(nominalControllers[i].text);
      }
      double percentage =
          double.tryParse(percentageControllers[index].text) ?? 0.0;
      // --- VALIDASI DISKON MAKSIMUM ---
      final maxDisc = _getMaxDisc(index);
      if (percentage > maxDisc * 100) {
        percentage = maxDisc * 100;
        percentageControllers[index].text = (maxDisc * 100).toStringAsFixed(2);
        CustomToast.showToast(
          "Diskon ${index + 1} tidak boleh melebihi ${(maxDisc * 100).toStringAsFixed(0)}%",
          ToastType.error,
        );
      }
      double nominal = (remainingPrice * (percentage / 100)).roundToDouble();
      nominalControllers[index].text = FormatHelper.formatCurrency(nominal);
    });
  }

  void updatePercentage(int index) {
    setState(() {
      double remainingPrice = basePrice;
      for (int i = 0; i < index; i++) {
        remainingPrice -=
            FormatHelper.parseCurrencyToDouble(nominalControllers[i].text);
      }
      double nominal =
          FormatHelper.parseCurrencyToDouble(nominalControllers[index].text);
      if (remainingPrice > 0) {
        double percentage = (nominal / remainingPrice) * 100;
        // --- VALIDASI DISKON MAKSIMUM ---
        final maxDisc = _getMaxDisc(index);
        if (percentage > maxDisc * 100) {
          percentage = maxDisc * 100;
          double maxNominal = (remainingPrice * maxDisc).roundToDouble();
          nominalControllers[index].text =
              FormatHelper.formatCurrency(maxNominal);
          CustomToast.showToast(
            "Diskon ${index + 1} tidak boleh melebihi ${(maxDisc * 100).toStringAsFixed(0)}%",
            ToastType.error,
          );
        }
        percentageControllers[index].text =
            percentage > 0 ? percentage.toStringAsFixed(2) : "";
      }
    });
  }

  double _getMaxDisc(int index) {
    switch (index) {
      case 0:
        return widget.product.disc1;
      case 1:
        return widget.product.disc2;
      case 2:
        return widget.product.disc3;
      case 3:
        return widget.product.disc4;
      case 4:
        return widget.product.disc5;
      default:
        return 1.0;
    }
  }

  String _getDiscountLabel(int discountLevel, bool isPercentage) {
    String levelText = "Diskon $discountLevel";

    if (_leaderData != null) {
      switch (discountLevel) {
        case 1:
          levelText = "Diskon SC";
          break;
        case 2:
          if (_leaderData!.directLeader != null) {
            levelText = "Diskon SPV";
          }
          break;
        case 3:
          if (_leaderData!.indirectLeader != null) {
            levelText = "Diskon RSM";
          }
          break;
        case 4:
          if (_leaderData!.analyst != null) {
            levelText = "Diskon Analyst";
          }
          break;
        case 5:
          if (_leaderData!.controller != null) {
            levelText = "Diskon Controller";
          }
          break;
      }
    }

    return isPercentage ? "$levelText (%)" : "$levelText (Rp)";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Input Diskon",
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: AppPadding.p16),

          // Konten di dalam SingleChildScrollView agar tidak overflow
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                // Sembunyikan disc5 (index 4) walaupun ada persentase batasan
                if (i == 4) return const SizedBox.shrink();

                // Hanya tampilkan discount field jika disc value > 0
                final discValue = _getMaxDisc(i);
                if (discValue <= 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: percentageControllers[i],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                  labelText: _getDiscountLabel(i + 1, true),
                                  border: const OutlineInputBorder()),
                              onChanged: (val) {
                                updateNominal(i);
                                _checkHasChanged();
                              })),
                      const SizedBox(width: AppPadding.p8),
                      Expanded(
                          child: TextField(
                              controller: nominalControllers[i],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: _getDiscountLabel(i + 1, false),
                                  border: const OutlineInputBorder()),
                              onChanged: (val) {
                                final formatted =
                                    FormatHelper.formatTextFieldCurrency(val);
                                nominalControllers[i].value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                      offset: formatted.length),
                                );
                                updatePercentage(i);
                                _checkHasChanged();
                              })),
                    ],
                  ),
                );
              }).where((widget) => widget != const SizedBox.shrink()).toList(),
            ),
          ),
          const SizedBox(height: AppPadding.p24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () {
                    // Clear all controllers
                    setState(() {
                      for (int i = 0; i < 5; i++) {
                        percentageControllers[i].clear();
                        nominalControllers[i].clear();
                      }
                    });

                    // Update ProductBloc to reset discounts to zero
                    context.read<ProductBloc>().add(UpdateProductDiscounts(
                          productId: widget.product.id,
                          discountPercentages: List.filled(5, 0.0),
                          discountNominals: List.filled(5, 0.0),
                          originalPrice:
                              widget.product.endUserPrice, // Use original price
                          leaderIds: List.filled(5, null),
                        ));

                    CustomToast.showToast("Diskon direset", ToastType.info);
                    Navigator.pop(context); // Close dialog after reset
                  },
                  child: Text("Reset",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
              const SizedBox(width: AppPadding.p8),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal")),
              const SizedBox(width: AppPadding.p8),
              ElevatedButton(
                onPressed: hasChanged
                    ? () {
                        try {
                          // Get current values
                          final currentPercentages = percentageControllers
                              .map((c) => double.tryParse(c.text) ?? 0.0)
                              .toList();
                          final currentNominals = nominalControllers
                              .map((c) =>
                                  FormatHelper.parseCurrencyToDouble(c.text))
                              .toList();

                          // Update ProductBloc with new discounts
                          context
                              .read<ProductBloc>()
                              .add(UpdateProductDiscounts(
                                productId: widget.product.id,
                                discountPercentages: currentPercentages,
                                discountNominals: currentNominals,
                                originalPrice: basePrice,
                                leaderIds:
                                    List.filled(5, null), // Simplified for cart
                              ));

                          Navigator.pop(context);
                        } catch (e) {
                          CustomToast.showToast(
                            "Gagal menyimpan diskon: ${e.toString()}",
                            ToastType.error,
                          );
                        }
                      }
                    : null,
                child: const Text("Simpan"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
