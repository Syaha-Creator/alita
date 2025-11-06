import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/quantity_control.dart';
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
import '../../../../features/approval/data/models/approval_model.dart';
import '../../../../services/lookup_item_service.dart' as lookup;
import '../../domain/entities/cart_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

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
  static const Radius radius = Radius.circular(12);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _isNoneComponent(String value) => _controller.isNoneComponent(value);

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
    if (widget.item.quantity != oldWidget.item.quantity) {
      if (mounted) {
        setState(() {});
      }
      if (widget.item.quantity > oldWidget.item.quantity) {
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
        if (newDiscountPercentages != null &&
            hasPositiveDiscount &&
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

  Widget _buildDetailsSection(BuildContext context, bool isDark) {
    final hasBonus = widget.item.product.bonus.any((b) => b.name.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppPadding.p10),
        _buildProductDetails(context, isDark),
        // Fabric selectors per component if available
        if (!_isNoneComponent(widget.item.product.kasur))
          _buildFabricSelector(context, isDark, 'kasur'),
        if (!_isNoneComponent(widget.item.product.divan))
          _buildFabricSelector(context, isDark, 'divan'),
        if (!_isNoneComponent(widget.item.product.headboard))
          _buildFabricSelector(context, isDark, 'headboard'),
        if (!_isNoneComponent(widget.item.product.sorong))
          _buildFabricSelector(context, isDark, 'sorong'),
        if (hasBonus) const SizedBox(height: AppPadding.p10),
        _buildBonus(context, isDark),
        const SizedBox(height: AppPadding.p10),
        _buildPriceInfo(context, isDark),
      ],
    );
  }

  Widget _buildFabricSelector(
      BuildContext context, bool isDark, String itemType) {
    String buildLabel(Map<String, String>? sel) {
      if (sel == null) return 'Pilih kain';
      final jk = (sel['jenis_kain'] ?? '').trim();
      final wk = (sel['warna_kain'] ?? '').trim();
      final combined = [jk, wk].where((e) => e.isNotEmpty).join(' - ');
      return combined.isEmpty ? (sel['item_number'] ?? 'Pilih kain') : combined;
    }

    final qty = widget.item.quantity;
    final perUnit = widget.item.selectedItemNumbersPerUnit?[itemType];
    final selLegacy = widget.item.selectedItemNumbers?[itemType];

    final children = <Widget>[];
    // Header line
    children.add(Row(
      children: [
        Expanded(
          child: Text(
            'Kain ${itemType[0].toUpperCase()}${itemType.substring(1)}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
        // For qty==1, keep single selector; for qty>1, show Unit #1 here
        TextButton(
          onPressed: () => _openFabricSelector(context, itemType, 0),
          child: Text(
            buildLabel((perUnit != null && perUnit.isNotEmpty)
                ? perUnit[0]
                : selLegacy),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDark ? AppColors.accentDark : AppColors.accentLight,
            ),
          ),
        )
      ],
    ));

    // If more than 1 quantity, show selectors per additional unit
    if (qty > 1) {
      for (int i = 1; i < qty; i++) {
        final label = buildLabel(
            (perUnit != null && i < perUnit.length) ? perUnit[i] : null);
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Unit #${i + 1}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openFabricSelector(context, itemType, i),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color:
                        isDark ? AppColors.accentDark : AppColors.accentLight,
                  ),
                ),
              )
            ],
          ),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

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
      final list = await lookup.LookupItemService().fetchLookupItems(
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
          itemNumber: it.itemNumber,
          jenisKain: it.fabricType,
          warnaKain: it.fabricColor,
          unitIndex: unitIndex,
          cartLineId: widget.item.cartLineId,
        ));
        if (!mounted) return;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kain default diterapkan')),
        );
        return;
      }

      if (list.isEmpty) {
        if (!mounted) return;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilihan kain tidak tersedia')),
        );
        return;
      }

      if (!mounted) return;
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title:
                const Text('Pilih Kain', style: TextStyle(fontFamily: 'Inter')),
            content: SizedBox(
              width: double.maxFinite,
              height: 340,
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (c, i) {
                  final it = list[i];
                  final main = [it.fabricType, it.fabricColor]
                      .where((e) => (e ?? '').isNotEmpty)
                      .join(' - ');
                  final sub = it.itemDesc ?? '';
                  return ListTile(
                    title: Text(
                      main.isEmpty ? (sub.isEmpty ? it.itemNumber : sub) : main,
                      style: const TextStyle(fontFamily: 'Inter'),
                    ),
                    subtitle: sub.isNotEmpty
                        ? Text(sub,
                            style: const TextStyle(
                                fontFamily: 'Inter', fontSize: 12))
                        : null,
                    onTap: () {
                      context.read<CartBloc>().add(UpdateCartSelectedItemNumber(
                            productId: widget.item.product.id,
                            netPrice: widget.item.netPrice,
                            itemType: itemType,
                            itemNumber: it.itemNumber,
                            jenisKain: it.fabricType,
                            warnaKain: it.fabricColor,
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
                child:
                    const Text('Tutup', style: TextStyle(fontFamily: 'Inter')),
              )
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kain: $e')),
      );
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
            '${widget.item.product.kasur} - ${widget.item.product.ukuran}',
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
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                backgroundColor:
                    isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                title: Text(
                  'Konfirmasi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                ),
                content: Text(
                  'Yakin ingin menghapus item ini?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      )),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('Hapus'))
                ],
              ));
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

  Widget _buildProductDetails(BuildContext context, bool isDark) {
    final p = widget.item.product;
    final baseTextStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final TextStyle styleLabel =
        baseTextStyle.copyWith(fontWeight: FontWeight.w600);
    final TextStyle styleValue =
        baseTextStyle.copyWith(fontWeight: FontWeight.w500);

    return Container(
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
        borderRadius: const BorderRadius.all(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detail Produk',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: AppPadding.p10 / 2),
          _buildDropdownRow(
            context,
            Icons.table_chart,
            'Divan',
            p.divan,
            styleLabel,
            styleValue,
            isDark,
            'divan',
          ),
          _buildDropdownRow(
            context,
            Icons.view_headline,
            'Headboard',
            p.headboard,
            styleLabel,
            styleValue,
            isDark,
            'headboard',
          ),
          _buildConditionalSorongDropdown(
            context,
            p,
            styleLabel,
            styleValue,
            isDark,
          ),
          _buildDropdownRow(
            context,
            Icons.straighten,
            'Ukuran',
            p.ukuran,
            styleLabel,
            styleValue,
            isDark,
            'ukuran',
          ),
          _detailRow(
              Icons.local_offer,
              'Program',
              p.program.isNotEmpty ? p.program : 'Tidak ada promo',
              styleLabel,
              styleValue,
              isDark),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(
    BuildContext context,
    IconData icon,
    String label,
    String currentValue,
    TextStyle labelStyle,
    TextStyle valueStyle,
    bool isDark,
    String type,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label ',
              style: labelStyle.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () =>
                  _showOptionsDialog(context, type, currentValue, isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.accentDark.withValues(alpha: 0.3)
                        : AppColors.accentLight.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentValue.isNotEmpty ? currentValue : '-',
                        style: valueStyle.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionalSorongDropdown(
    BuildContext context,
    ProductEntity product,
    TextStyle labelStyle,
    TextStyle valueStyle,
    bool isDark,
  ) {
    return FutureBuilder<List<String>>(
      future: _getSorongOptions(product),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Loading state - show nothing while loading
          return const SizedBox.shrink();
        }

        final sorongOptions = snapshot.data!;

        // Only show sorong dropdown if there are more than 1 option
        if (sorongOptions.length > 1) {
          return _buildDropdownRow(
            context,
            Icons.storage,
            'Sorong',
            product.sorong,
            labelStyle,
            valueStyle,
            isDark,
            'sorong',
          );
        } else {
          // Don't show sorong dropdown if only 1 option
          return const SizedBox.shrink();
        }
      },
    );
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

  Widget _detailRow(IconData icon, String label, String value,
      TextStyle labelStyle, TextStyle valueStyle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label ',
              style: labelStyle.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Text(
            value.isNotEmpty ? value : '-',
            style: (valueStyle).copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonus(BuildContext context, bool isDark) {
    final bonusList = widget.item.product.bonus;
    final hasBonus = bonusList.any((b) => b.name.isNotEmpty);

    // Hide bonus section if there's no bonus
    if (!hasBonus) {
      return const SizedBox.shrink();
    }

    return _bonusBox(
      context,
      Icons.card_giftcard,
      'Bonus',
      '',
      isDark,
    );
  }

  Widget _bonusBox(BuildContext context, IconData icon, String title,
      String content, bool isDark) {
    final bonusList = widget.item.product.bonus;
    final hasBonus = bonusList.any((b) => b.name.isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.p8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.accentLight.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.all(radius),
        border: Border.all(
          color: isDark
              ? AppColors.accentDark.withValues(alpha: 0.2)
              : AppColors.accentLight.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.accentDark : AppColors.accentLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),

          // Compact bonus items or empty state
          if (hasBonus) ...[
            ...bonusList.asMap().entries.map((entry) {
              final index = entry.key;
              final bonus = entry.value;
              if (bonus.name.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    // Bonus name
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            _showBonusItemSelector(context, index, bonus),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.accentDark.withValues(alpha: 0.3)
                                  : AppColors.accentLight
                                      .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bonus.name,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quantity controls
                    Row(
                      children: [
                        // Minus button or delete button
                        IconButton(
                          onPressed: () {
                            if (bonus.quantity > 1) {
                              // Decrease quantity
                              context.read<CartBloc>().add(UpdateCartBonus(
                                    productId: widget.item.product.id,
                                    netPrice: widget.item.netPrice,
                                    bonusIndex: index,
                                    bonusName: bonus.name,
                                    bonusQuantity: bonus.quantity - 1,
                                    cartLineId: widget.item.cartLineId,
                                  ));
                            } else {
                              // Delete bonus when quantity is 1
                              _removeBonus(context, index);
                            }
                          },
                          icon: Icon(
                            bonus.quantity > 1
                                ? Icons.remove_circle_outline
                                : Icons.delete_outline,
                            size: 20,
                            color: bonus.quantity > 1
                                ? (isDark
                                    ? AppColors.accentDark
                                    : AppColors.accentLight)
                                : AppColors.error,
                          ),
                          tooltip: bonus.quantity > 1
                              ? 'Kurangi jumlah'
                              : 'Hapus bonus',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        // Quantity display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.accentDark.withValues(alpha: 0.3)
                                  : AppColors.accentLight
                                      .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Builder(
                            builder: (context) {
                              final perUnit = bonus.originalQuantity > 0
                                  ? bonus.originalQuantity
                                  : bonus.quantity;
                              final maxQty = perUnit * 2 * widget.item.quantity;
                              return Text(
                                '${bonus.quantity}x (Max: $maxQty)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              );
                            },
                          ),
                        ),
                        // Plus button
                        Builder(
                          builder: (context) {
                            final perUnit = bonus.originalQuantity > 0
                                ? bonus.originalQuantity
                                : bonus.quantity;
                            final maxQty = perUnit * 2 * widget.item.quantity;
                            return IconButton(
                              onPressed: bonus.quantity < maxQty
                                  ? () {
                                      context
                                          .read<CartBloc>()
                                          .add(UpdateCartBonus(
                                            productId: widget.item.product.id,
                                            netPrice: widget.item.netPrice,
                                            bonusIndex: index,
                                            bonusName: bonus.name,
                                            bonusQuantity: bonus.quantity + 1,
                                            cartLineId: widget.item.cartLineId,
                                          ));
                                    }
                                  : null,
                              icon: Icon(
                                Icons.add_circle_outline,
                                size: 20,
                                color: bonus.quantity < maxQty
                                    ? (isDark
                                        ? AppColors.accentDark
                                        : AppColors.accentLight)
                                    : Colors.grey,
                              ),
                              tooltip: bonus.quantity < maxQty
                                  ? 'Tambah jumlah (Max: $maxQty)'
                                  : 'Maksimum tercapai ($maxQty)',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            // Compact empty state
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Belum ada bonus item',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceInfo(BuildContext context, bool isDark) {
    final item = widget.item;
    final netPrice = item.netPrice;
    final totalDiscount = item.product.pricelist - netPrice;

    final discounts = <double>[...item.discountPercentages];
    final formattedDiscounts = discounts
        .where((d) => d > 0)
        .map((d) => d % 1 == 0 ? '${d.toInt()}%' : '${d.toStringAsFixed(2)}%')
        .join(' + ');
    final hasInstallment = (item.installmentMonths ?? 0) > 0;

    final styleLabel = TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final styleValue = TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight);

    return Container(
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.all(radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Informasi Harga',
                  style: (Theme.of(context).textTheme.titleSmall ??
                          const TextStyle())
                      .copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                icon: Icon(Icons.edit,
                    size: 20,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                onPressed: () => _showPriceActions(context),
                tooltip: 'Edit/Info Harga',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p10 / 2),
          _priceRow(
              'Pricelist',
              FormatHelper.formatCurrency(item.product.pricelist),
              styleLabel.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.error),
              isDark),
          _priceRow(
              'Total Diskon',
              '-${FormatHelper.formatCurrency(totalDiscount)}',
              styleValue.copyWith(color: AppColors.warning),
              isDark),
          if (formattedDiscounts.isNotEmpty)
            _priceRow(
                'Plus Diskon',
                formattedDiscounts,
                styleValue.copyWith(
                    color: isDark ? AppColors.accentDark : AppColors.info),
                isDark),
          if (hasInstallment)
            _priceRow(
                'Cicilan',
                '${item.installmentMonths} bulan x ${FormatHelper.formatCurrency(item.installmentPerMonth ?? 0)}',
                styleValue.copyWith(
                    color: isDark ? AppColors.accentDark : AppColors.info),
                isDark),
          _priceRow(
              'Harga Net',
              FormatHelper.formatCurrency(netPrice),
              styleValue.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.success),
              isDark),
        ],
      ),
    );
  }

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
              const SizedBox(height: 8),
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
    if (newDiscounts != null &&
        hasPositiveDiscount &&
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

  Widget _priceRow(
      String label, String value, TextStyle valueStyle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
                      .copyWith(fontWeight: FontWeight.w600)),
          Text(value, style: valueStyle)
        ],
      ),
    );
  }

  Widget _buildTotalPrice(BuildContext context, bool isDark) {
    final total = widget.item.netPrice * widget.item.quantity;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppPadding.p10 / 2, horizontal: AppPadding.p10),
      decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark
              : AppColors.success.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.all(radius)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Harga:',
              style:
                  (Theme.of(context).textTheme.titleSmall ?? const TextStyle())
                      .copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight)),
          Text(FormatHelper.formatCurrency(total),
              style:
                  (Theme.of(context).textTheme.titleSmall ?? const TextStyle())
                      .copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success)),
        ],
      ),
    );
  }

  void _removeBonus(BuildContext context, int bonusIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus Bonus',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus bonus ini?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartBloc>().add(RemoveCartBonus(
                    productId: widget.item.product.id,
                    netPrice: widget.item.netPrice,
                    bonusIndex: bonusIndex,
                  ));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus',
                style: (Theme.of(context).textTheme.bodyMedium ??
                        const TextStyle())
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading accessories: $e')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada opsi $type yang tersedia')),
        );
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
              child: Text(
                'Batal',
                style: const TextStyle(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading $type options: $e')),
      );
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
      final leaderService = locator<LeaderService>();
      final leaderData = await leaderService.getLeaderByUser();

      setState(() {
        _leaderData = leaderData;
      });
    } catch (e) {
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
          levelText = "Diskon SPG";
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
          if (_leaderData!.analyst1 != null) {
            levelText = "Diskon Analyst";
          }
          break;
        case 5:
          if (_leaderData!.analyst2 != null) {
            levelText = "Diskon Analyst";
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
          Text("Input Diskon",
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Konten di dalam SingleChildScrollView agar tidak overflow
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
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
                                  border: OutlineInputBorder()),
                              onChanged: (val) {
                                updateNominal(i);
                                _checkHasChanged();
                              })),
                      const SizedBox(width: 8),
                      Expanded(
                          child: TextField(
                              controller: nominalControllers[i],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: _getDiscountLabel(i + 1, false),
                                  border: OutlineInputBorder()),
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
          const SizedBox(height: 24),
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
              const SizedBox(width: 8),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Batal")),
              const SizedBox(width: 8),
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

// Bonus Selector Dialog Widget
// moved to its own file: bonus_selector_dialog.dart
