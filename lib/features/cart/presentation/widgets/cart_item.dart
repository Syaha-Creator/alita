import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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
import '../../../../features/approval/data/models/approval_model.dart';
import '../../domain/entities/cart_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

class CartItemWidget extends StatefulWidget {
  final CartEntity item;
  const CartItemWidget({super.key, required this.item});

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  bool isExpanded = false;
  late final TextEditingController _noteController;

  // === KEMBALIKAN KONSTANTA KE SINI AGAR BISA DIAKSES SEMUA METHOD ===
  static const double _avatarSize = 40.0;
  static const Radius radius = Radius.circular(12);
  // =================================================================

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan note dari BLoC secara aman
    final initialNote = context
            .read<ProductBloc>()
            .state
            .productNotes[widget.item.product.id] ??
        '';
    _noteController = TextEditingController(text: initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Kita gunakan BlocListener untuk update controller secara aman saat state berubah
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        final newNote = state.productNotes[widget.item.product.id] ?? '';
        // Hanya update controller jika teksnya berbeda untuk menghindari loop tak terbatas
        if (_noteController.text != newNote) {
          _noteController.text = newNote;
        }

        // Check if price has changed and update cart
        final newPrice = state.roundedPrices[widget.item.product.id];
        if (newPrice != null && newPrice != widget.item.netPrice) {
          // Update cart item with new price
          context.read<CartBloc>().add(UpdateCartPrice(
                productId: widget.item.product.id,
                oldNetPrice: widget.item.netPrice,
                newNetPrice: newPrice,
              ));
        }

        // Check if discounts have changed and update cart
        final newDiscountPercentages =
            state.productDiscountsPercentage[widget.item.product.id];
        if (newDiscountPercentages != null &&
            !_listEquals(
                newDiscountPercentages, widget.item.discountPercentages)) {
          // Calculate new net price from discounts
          double calculatedPrice = widget.item.product.endUserPrice;
          for (final percentage in newDiscountPercentages) {
            if (percentage > 0) {
              calculatedPrice = calculatedPrice * (1 - (percentage / 100));
            }
          }

          // Update cart item with new discounts and calculated price
          context.read<CartBloc>().add(UpdateCartDiscounts(
                productId: widget.item.product.id,
                oldNetPrice: widget.item.netPrice,
                discountPercentages: newDiscountPercentages,
                newNetPrice: calculatedPrice,
              ));
        }
      },
      child: InkWell(
        onTap: () => setState(() => isExpanded = !isExpanded),
        child: Card(
          margin: const EdgeInsets.symmetric(
              horizontal: AppPadding.p10, vertical: AppPadding.p10 / 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.p10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isDark),
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
      ),
    );
  }

  // --- SEMUA METHOD HELPER DIKEMBALIKAN KE DALAM STATE ---

  Widget _buildDetailsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppPadding.p10),
        _buildProductDetails(context, isDark),
        const SizedBox(height: AppPadding.p10),
        _buildBonusAndNotes(context, isDark),
        const SizedBox(height: AppPadding.p10),
        _buildPriceInfo(context, isDark),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Checkbox(
          value: widget.item.isSelected,
          onChanged: (value) {
            context.read<CartBloc>().add(ToggleCartItemSelection(
                  productId: widget.item.product.id,
                  netPrice: widget.item.netPrice,
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
        QuantityControl(
          quantity: widget.item.quantity,
          onIncrement: () {
            context.read<CartBloc>().add(UpdateCartQuantity(
                  productId: widget.item.product.id,
                  netPrice: widget.item.netPrice,
                  quantity: widget.item.quantity + 1,
                ));
          },
          onDecrement: () => _decrement(context),
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
        context.read<CartBloc>().add(RemoveFromCart(
            productId: widget.item.product.id, netPrice: widget.item.netPrice));
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
                        ? AppColors.accentDark.withOpacity(0.3)
                        : AppColors.accentLight.withOpacity(0.3),
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

  Widget _buildBonusAndNotes(BuildContext context, bool isDark) {
    final bonusList = widget.item.product.bonus;
    final hasBonus = bonusList.any((b) => b.name.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hasBonus
            ? _bonusBox(
                context,
                Icons.card_giftcard,
                'Bonus',
                '', // Content will be handled inside _bonusBox
                isDark)
            : Text(
                'Bonus: Tidak ada bonus',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade600,
                ),
              ),
        const SizedBox(height: 8),

        BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (prev, current) =>
              prev.productNotes[widget.item.product.id] !=
              current.productNotes[widget.item.product.id],
          builder: (context, state) {
            final note = state.productNotes[widget.item.product.id] ?? '';
            return _infoBox(context, Icons.note, 'Catatan', note, isDark);
          },
        ),
        // ===================================
      ],
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
            : AppColors.accentLight.withOpacity(0.05),
        borderRadius: const BorderRadius.all(radius),
        border: Border.all(
          color: isDark
              ? AppColors.accentDark.withOpacity(0.2)
              : AppColors.accentLight.withOpacity(0.2),
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
                  style: GoogleFonts.inter(
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
                                  ? AppColors.accentDark.withOpacity(0.3)
                                  : AppColors.accentLight.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bonus.name,
                                  style: GoogleFonts.inter(
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
                                  ? AppColors.accentDark.withOpacity(0.3)
                                  : AppColors.accentLight.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${bonus.quantity}x (Max: ${bonus.maxQuantity})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        // Plus button
                        IconButton(
                          onPressed: bonus.quantity < bonus.maxQuantity
                              ? () {
                                  context.read<CartBloc>().add(UpdateCartBonus(
                                        productId: widget.item.product.id,
                                        netPrice: widget.item.netPrice,
                                        bonusIndex: index,
                                        bonusName: bonus.name,
                                        bonusQuantity: bonus.quantity + 1,
                                      ));
                                }
                              : null,
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 20,
                            color: bonus.quantity < bonus.maxQuantity
                                ? (isDark
                                    ? AppColors.accentDark
                                    : AppColors.accentLight)
                                : Colors.grey,
                          ),
                          tooltip: bonus.quantity < bonus.maxQuantity
                              ? 'Tambah jumlah (Max: ${bonus.maxQuantity})'
                              : 'Maksimum tercapai (${bonus.maxQuantity})',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
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
                    style: GoogleFonts.inter(
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

  Widget _infoBox(BuildContext context, IconData icon, String title,
      String content, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.all(radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon,
                size: 20,
                color:
                    isDark ? AppColors.accentDark : AppColors.textPrimaryLight),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight))
          ]),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  content.isNotEmpty ? content : 'Tidak ada catatan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
              ),
              IconButton(
                  onPressed: () => _showEditNoteDialog(context),
                  icon: Icon(Icons.edit,
                      color: isDark
                          ? AppColors.accentDark
                          : AppColors.textSecondaryLight)),
            ],
          ),
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

    final styleLabel = GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final styleValue = GoogleFonts.inter(
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditPriceDialog(product: product),
    );
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
              : AppColors.success.withOpacity(0.1),
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

  void _showEditNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Catatan',
            style: Theme.of(context).textTheme.titleMedium),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
              hintText: 'Masukkan catatan', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              context.read<ProductBloc>().add(UpdateProductNote(
                  productId: widget.item.product.id,
                  note: _noteController.text));
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
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
      showDialog(
        context: context,
        builder: (ctx) => _BonusSelectorDialog(
          accessories: accessories,
          bonusIndex: bonusIndex,
          productId: widget.item.product.id,
          netPrice: widget.item.netPrice,
          currentQuantity: bonus.quantity,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accessories: $e')),
        );
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada opsi $type yang tersedia')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Pilih $type',
            style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading $type options: $e')),
        );
      }
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
    // Use cart's netPrice as base price
    basePrice = widget.netPrice;

    // Initialize with cart's discount percentages
    _initialPercentages = List.from(widget.discountPercentages);
    _initialNominals =
        List.filled(5, 0.0); // Will be calculated from percentages

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
          levelText = "Diskon 1";
          break;
        case 2:
          if (_leaderData!.directLeader != null) {
            levelText = "Diskon 2";
          }
          break;
        case 3:
          if (_leaderData!.indirectLeader != null) {
            levelText = "Diskon 3";
          }
          break;
        case 4:
          if (_leaderData!.controller != null) {
            levelText = "Diskon 4";
          }
          break;
        case 5:
          if (_leaderData!.analyst != null) {
            levelText = "Diskon 5";
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
              style:
                  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
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
class _BonusSelectorDialog extends StatefulWidget {
  final List<AccessoryEntity> accessories;
  final int bonusIndex;
  final int productId;
  final double netPrice;
  final int currentQuantity;

  const _BonusSelectorDialog({
    required this.accessories,
    required this.bonusIndex,
    required this.productId,
    required this.netPrice,
    required this.currentQuantity,
  });

  @override
  State<_BonusSelectorDialog> createState() => _BonusSelectorDialogState();
}

class _BonusSelectorDialogState extends State<_BonusSelectorDialog> {
  List<AccessoryEntity> filteredAccessories = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredAccessories = widget.accessories;
    _searchController.addListener(_filterAccessories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAccessories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredAccessories = widget.accessories;
      } else {
        filteredAccessories = widget.accessories.where((accessory) {
          final itemName = accessory.item.toLowerCase();
          final brand = accessory.brand.toLowerCase();
          final ukuran = accessory.ukuran.toLowerCase();
          return itemName.contains(query) ||
              brand.contains(query) ||
              ukuran.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        'Pilih Item Bonus',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari item bonus...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items list
            Expanded(
              child: filteredAccessories.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada item yang ditemukan',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredAccessories.length,
                      itemBuilder: (context, index) {
                        final accessory = filteredAccessories[index];
                        final displayText = accessory.ukuran.isNotEmpty
                            ? '${accessory.item} (${accessory.ukuran})'
                            : accessory.item;

                        return ListTile(
                          title: Text(
                            displayText,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Brand: ${accessory.brand}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          onTap: () {
                            context.read<CartBloc>().add(UpdateCartBonus(
                                  productId: widget.productId,
                                  netPrice: widget.netPrice,
                                  bonusIndex: widget.bonusIndex,
                                  bonusName: displayText,
                                  bonusQuantity: widget.currentQuantity,
                                ));
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: GoogleFonts.inter(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
