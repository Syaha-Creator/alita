import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/quantity_control.dart';
import '../../../../theme/app_colors.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';
import '../../domain/entities/cart_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import 'edit_bonus_dialog.dart';

class CartItemWidget extends StatefulWidget {
  final CartEntity item;
  const CartItemWidget({super.key, required this.item});

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  bool isExpanded = true;
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
            style: GoogleFonts.montserrat(
              fontSize: 20,
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
                  style: GoogleFonts.montserrat(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                content: Text(
                  'Yakin ingin menghapus item ini?',
                  style: GoogleFonts.montserrat(
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
    final styleLabel =
        GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600);
    final styleValue =
        GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500);

    return Container(
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
        borderRadius: const BorderRadius.all(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Produk',
            style: styleLabel.copyWith(
              fontSize: 15,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppPadding.p10 / 2),
          _detailRow(Icons.table_chart, 'Divan', p.divan, styleLabel,
              styleValue, isDark),
          _detailRow(Icons.view_headline, 'Headboard', p.headboard, styleLabel,
              styleValue, isDark),
          _detailRow(Icons.storage, 'Sorong', p.sorong, styleLabel, styleValue,
              isDark),
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
            style: valueStyle.copyWith(
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
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              // Add bonus button
              IconButton(
                onPressed: () => _showAddBonusDialog(context),
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: isDark ? AppColors.accentDark : AppColors.accentLight,
                ),
                tooltip: 'Tambah Bonus',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
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

              return Row(
                children: [
                  // Compact quantity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.accentDark : AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${bonus.quantity * widget.item.quantity}x',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bonus name
                  Expanded(
                    child: Text(
                      bonus.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  // Edit button
                  IconButton(
                    onPressed: () => _showEditBonusDialog(context, index),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color:
                          isDark ? AppColors.accentDark : AppColors.accentLight,
                    ),
                    tooltip: 'Edit ${bonus.name}',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () => _removeBonus(context, index),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: isDark ? AppColors.error : AppColors.error,
                    ),
                    tooltip: 'Hapus ${bonus.name}',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              );
            }),
          ] else ...[
            // Compact empty state
            Row(
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
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
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
                style: GoogleFonts.montserrat(
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
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight))),
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

    final styleLabel = GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final styleValue = GoogleFonts.montserrat(
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
          Text('Informasi Harga', style: styleLabel.copyWith(fontSize: 16)),
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

  Widget _priceRow(
      String label, String value, TextStyle valueStyle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 14, fontWeight: FontWeight.w600)),
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
          Text(
            'Total Harga:',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          Text(FormatHelper.formatCurrency(total),
              style: GoogleFonts.montserrat(
                  fontSize: 18,
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
        title: Text('Edit Catatan', style: GoogleFonts.montserrat()),
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

  void _showEditBonusDialog(BuildContext context, [int? bonusIndex]) {
    final bonusList = widget.item.product.bonus;
    final index = bonusIndex ?? 0;

    if (index >= bonusList.length) return;

    final bonus = bonusList[index];

    showDialog(
      context: context,
      builder: (ctx) => EditBonusDialog(
        currentBonusName: bonus.name,
        currentBonusQuantity: bonus.quantity,
        bonusIndex: index,
        productId: widget.item.product.id,
        netPrice: widget.item.netPrice,
      ),
    );
  }

  void _showAddBonusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => EditBonusDialog(
        currentBonusName: '',
        currentBonusQuantity: 1,
        bonusIndex: -1,
        productId: widget.item.product.id,
        netPrice: widget.item.netPrice,
      ),
    );
  }

  void _removeBonus(BuildContext context, int bonusIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus Bonus',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus bonus ini?',
          style: GoogleFonts.montserrat(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.montserrat(
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
            child: Text(
              'Hapus',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
