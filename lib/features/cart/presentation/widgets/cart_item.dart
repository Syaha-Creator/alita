// File: lib/features/cart/presentation/widgets/cart_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/controller_disposal_mixin.dart';
import '../../../../core/utils/format_helper.dart';
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

class _CartItemWidgetState extends State<CartItemWidget>
    with ControllerDisposalMixin {
  bool isExpanded = true;
  late final TextEditingController _noteController;

  static const double _padding = 10.0;
  static const double _avatarSize = 40.0;
  static const radius = Radius.circular(12);

  @override
  void initState() {
    super.initState();

    // Register controller for auto-disposal
    _noteController = registerController(context
            .read<ProductBloc>()
            .state
            .productNotes[widget.item.product.id] ??
        '');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        final netPrice = widget.item.netPrice;
        final totalDiscount = widget.item.product.pricelist - netPrice;
        final discounts = _formatDiscounts(widget.item);
        final hasInstallment = (widget.item.installmentMonths ?? 0) > 0;

        return InkWell(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Card(
            margin: const EdgeInsets.symmetric(
                horizontal: _padding, vertical: _padding / 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(_padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  if (isExpanded) ...[
                    const SizedBox(height: _padding),
                    _buildProductDetails(context),
                    const SizedBox(height: _padding),
                    _buildBonusAndNotes(context, productState),
                    const SizedBox(height: _padding),
                    _buildPriceInfo(context, netPrice, totalDiscount, discounts,
                        hasInstallment),
                  ],
                  const SizedBox(height: _padding),
                  _buildTotalPrice(context, netPrice),
                ],
              ),
            ),
          ),
        );
      },
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
        const SizedBox(width: _padding),
        Expanded(
          child: Text(
            '${widget.item.product.kasur} - ${widget.item.product.ukuran}',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ),
        _QuantityControl(item: widget.item)
      ],
    );
  }

  static List<String> _formatDiscounts(CartEntity item) {
    final list = <double>[...item.discountPercentages];
    if (item.editPopupDiscount > 0) list.add(item.editPopupDiscount);
    return list
        .where((d) => d > 0)
        .map((d) => d % 1 == 0 ? '${d.toInt()}%' : '${d.toStringAsFixed(2)}%')
        .toList();
  }

  Widget _buildProductDetails(BuildContext context) {
    final p = widget.item.product;
    final styleLabel =
        GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600);
    final styleValue =
        GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.all(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detail Produk', style: styleLabel.copyWith(fontSize: 15)),
          const SizedBox(height: _padding / 2),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text('$label ', style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  Widget _buildBonusAndNotes(BuildContext context, ProductState state) {
    final bonusList = widget.item.product.bonus;
    final hasBonus = bonusList.isNotEmpty;
    final note = state.productNotes[widget.item.product.id] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hasBonus
            ? _bonusBox(context, Icons.card_giftcard, 'Bonus',
                bonusList.map((b) => '• ${b.quantity}x ${b.name}').join('\n'))
            : Text('Bonus: Tidak ada bonus',
                style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        _infoBox(context, Icons.note, 'Catatan', note),
      ],
    );
  }

  Widget _bonusBox(
      BuildContext context, IconData icon, String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.all(radius),
      ),
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
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.all(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  content,
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
              ),
              IconButton(
                onPressed: () => _showEditNoteDialog(context),
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(
    BuildContext context,
    double netPrice,
    double totalDiscount,
    List<String> discounts,
    bool hasInstallment,
  ) {
    final styleLabel =
        GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600);
    final styleValue = GoogleFonts.montserrat(fontSize: 14);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.all(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi Harga', style: styleLabel.copyWith(fontSize: 16)),
          const SizedBox(height: _padding / 2),
          _priceRow(
              'Pricelist',
              FormatHelper.formatCurrency(widget.item.product.pricelist),
              styleLabel.copyWith(
                  decoration: TextDecoration.lineThrough, color: Colors.red)),
          _priceRow(
              'Total Diskon',
              '-${FormatHelper.formatCurrency(totalDiscount)}',
              styleValue.copyWith(color: Colors.orange.shade700)),
          if (discounts.isNotEmpty)
            _priceRow('Plus Diskon', discounts.join(' + '),
                styleValue.copyWith(color: Theme.of(context).primaryColor)),
          if (hasInstallment)
            _priceRow(
                'Cicilan',
                '${widget.item.installmentMonths} bulan x ${FormatHelper.formatCurrency(widget.item.installmentPerMonth ?? 0)}',
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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

  Widget _buildTotalPrice(BuildContext context, double netPrice) {
    final total = netPrice * widget.item.quantity;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: _padding / 2, horizontal: _padding),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.all(radius),
      ),
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
          decoration: InputDecoration(
            hintText: 'Masukkan catatan',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductBloc>().add(UpdateProductNote(
                    productId: widget.item.product.id,
                    note: _noteController.text,
                  ));
              Navigator.pop(ctx);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final CartEntity item;
  const _QuantityControl({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildIconButton(
            context, Icons.remove, Colors.redAccent, () => _decrement(context)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(item.quantity.toString(),
              style: GoogleFonts.montserrat(fontSize: 15)),
        ),
        _buildIconButton(
            context,
            Icons.add,
            Colors.green,
            () => context.read<CartBloc>().add(
                  UpdateCartQuantity(
                      productId: item.product.id,
                      netPrice: item.netPrice,
                      quantity: item.quantity + 1),
                )),
      ],
    );
  }

  Widget _buildIconButton(
      BuildContext context, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      shape: const CircleBorder(),
      color: color.withOpacity(0.1),
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  void _decrement(BuildContext context) async {
    if (item.quantity > 1) {
      context.read<CartBloc>().add(UpdateCartQuantity(
            productId: item.product.id,
            netPrice: item.netPrice,
            quantity: item.quantity - 1,
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
                      child: Text('Batal')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Hapus'))
                ],
              ));
      if (confirm == true) {
        context.read<CartBloc>().add(RemoveFromCart(
            productId: item.product.id, netPrice: item.netPrice));
      }
    }
  }
}
