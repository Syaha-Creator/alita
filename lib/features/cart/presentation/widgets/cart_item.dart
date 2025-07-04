import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/quantity_control.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';
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
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.p10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                // Animasi buka-tutup detail
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildDetailsSection(context),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
                const SizedBox(height: AppPadding.p10),
                _buildTotalPrice(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SEMUA METHOD HELPER DIKEMBALIKAN KE DALAM STATE ---

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppPadding.p10),
        _buildProductDetails(context),
        const SizedBox(height: AppPadding.p10),
        _buildBonusAndNotes(context),
        const SizedBox(height: AppPadding.p10),
        _buildPriceInfo(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          backgroundColor: Theme.of(context).primaryColorLight,
          child: Icon(Icons.bed,
              color: Theme.of(context).primaryColor, size: _avatarSize * 0.5),
        ),
        const SizedBox(width: AppPadding.p10),
        Expanded(
          child: Text(
            '${widget.item.product.kasur} - ${widget.item.product.ukuran}',
            style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColorDark),
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
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text('Konfirmasi', style: GoogleFonts.montserrat()),
                content: Text('Yakin ingin menghapus item ini?',
                    style: GoogleFonts.montserrat()),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'))
                ],
              ));
      if (confirm == true) {
        context.read<CartBloc>().add(RemoveFromCart(
            productId: widget.item.product.id, netPrice: widget.item.netPrice));
      }
    }
  }

  Widget _buildProductDetails(BuildContext context) {
    final p = widget.item.product;
    final styleLabel =
        GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600);
    final styleValue =
        GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500);

    return Container(
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.all(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detail Produk', style: styleLabel.copyWith(fontSize: 15)),
          const SizedBox(height: AppPadding.p10 / 2),
          _detailRow(
              Icons.table_chart, 'Divan', p.divan, styleLabel, styleValue),
          _detailRow(Icons.view_headline, 'Headboard', p.headboard, styleLabel,
              styleValue),
          _detailRow(Icons.storage, 'Sorong', p.sorong, styleLabel, styleValue),
          _detailRow(
              Icons.local_offer,
              'Program',
              p.program.isNotEmpty ? p.program : 'Tidak ada promo',
              styleLabel,
              styleValue),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      TextStyle labelStyle, TextStyle valueStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text('$label ', style: labelStyle)),
          Text(value.isNotEmpty ? value : '-', style: valueStyle),
        ],
      ),
    );
  }

  Widget _buildBonusAndNotes(BuildContext context) {
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
                bonusList
                    .where((b) => b.name.isNotEmpty)
                    .map((b) => '• ${b.quantity}x ${b.name}')
                    .join('\n'))
            : Text('Bonus: Tidak ada bonus',
                style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),

        BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (prev, current) =>
              prev.productNotes[widget.item.product.id] !=
              current.productNotes[widget.item.product.id],
          builder: (context, state) {
            final note = state.productNotes[widget.item.product.id] ?? '';
            return _infoBox(context, Icons.note, 'Catatan', note);
          },
        ),
        // ===================================
      ],
    );
  }

  Widget _bonusBox(
      BuildContext context, IconData icon, String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: const BorderRadius.all(radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.montserrat(
                    fontSize: 15, fontWeight: FontWeight.w600))
          ]),
          const SizedBox(height: 4),
          Text(content, style: GoogleFonts.montserrat(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _infoBox(
      BuildContext context, IconData icon, String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.all(radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: Colors.black),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.montserrat(
                    fontSize: 15, fontWeight: FontWeight.w600))
          ]),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(
                      content.isNotEmpty ? content : 'Tidak ada catatan',
                      style: GoogleFonts.montserrat(fontSize: 14))),
              IconButton(
                  onPressed: () => _showEditNoteDialog(context),
                  icon: const Icon(Icons.edit)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(BuildContext context) {
    final item = widget.item;
    final netPrice = item.netPrice;
    final totalDiscount = item.product.pricelist - netPrice;

    final discounts = <double>[...item.discountPercentages];
    if (item.editPopupDiscount > 0) discounts.add(item.editPopupDiscount);
    final formattedDiscounts = discounts
        .where((d) => d > 0)
        .map((d) => d % 1 == 0 ? '${d.toInt()}%' : '${d.toStringAsFixed(2)}%')
        .toList();
    final hasInstallment = (item.installmentMonths ?? 0) > 0;

    final styleLabel =
        GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600);
    final styleValue = GoogleFonts.montserrat(fontSize: 14);

    return Container(
      padding: const EdgeInsets.all(AppPadding.p10),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
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
                  decoration: TextDecoration.lineThrough, color: Colors.red)),
          _priceRow(
              'Total Diskon',
              '-${FormatHelper.formatCurrency(totalDiscount)}',
              styleValue.copyWith(color: Colors.orange.shade700)),
          if (formattedDiscounts.isNotEmpty)
            _priceRow('Plus Diskon', formattedDiscounts.join(' + '),
                styleValue.copyWith(color: Theme.of(context).primaryColor)),
          if (hasInstallment)
            _priceRow(
                'Cicilan',
                '${item.installmentMonths} bulan x ${FormatHelper.formatCurrency(item.installmentPerMonth ?? 0)}',
                styleValue.copyWith(color: Colors.teal.shade700)),
          _priceRow(
              'Harga Net',
              FormatHelper.formatCurrency(netPrice),
              styleValue.copyWith(
                  fontWeight: FontWeight.w700, color: Colors.green.shade700)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, TextStyle valueStyle) {
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

  Widget _buildTotalPrice(BuildContext context) {
    final total = widget.item.netPrice * widget.item.quantity;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppPadding.p10 / 2, horizontal: AppPadding.p10),
      decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: const BorderRadius.all(radius)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Harga:',
              style: GoogleFonts.montserrat(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          Text(FormatHelper.formatCurrency(total),
              style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800)),
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
}
