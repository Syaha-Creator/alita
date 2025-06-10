import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../core/widgets/custom_toast.dart';
import '../../../domain/entities/product_entity.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart';

class EditPriceDialog extends StatefulWidget {
  final ProductEntity product;
  const EditPriceDialog({super.key, required this.product});

  @override
  State<EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<EditPriceDialog> {
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  late final ValueNotifier<double> _percentageChange;
  late final double _priceBeforeEdit;
  late double _basePrice;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductBloc>().state;
    _priceBeforeEdit =
        state.roundedPrices[widget.product.id] ?? widget.product.endUserPrice;
    _basePrice = widget.product.endUserPrice;

    _priceController = TextEditingController(
        text: FormatHelper.formatCurrency(_priceBeforeEdit));
    _noteController = TextEditingController(
        text: state.productNotes[widget.product.id] ?? "");
    _percentageChange =
        ValueNotifier(state.priceChangePercentages[widget.product.id] ?? 0.0);
  }

  void _calculatePercentage() {
    final newPrice = FormatHelper.parseCurrencyToDouble(_priceController.text);
    if (_priceBeforeEdit > 0) {
      final diff = ((_priceBeforeEdit - newPrice) / _priceBeforeEdit) * 100;
      _percentageChange.value = diff;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    _percentageChange.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.read<ProductBloc>().state;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text("Edit Harga Net", style: theme.textTheme.headlineSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Masukkan harga net baru:", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final formatted = FormatHelper.formatTextFieldCurrency(value);
                _priceController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
                _calculatePercentage();
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<double>(
              valueListenable: _percentageChange,
              builder: (context, value, child) => Text(
                "Perubahan: ${value.toStringAsFixed(2)}%",
                style: TextStyle(color: value > 0 ? Colors.red : Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Text("Catatan:", style: theme.textTheme.bodyMedium),
            TextField(
              controller: _noteController,
              decoration:
                  const InputDecoration(hintText: "Masukkan catatan..."),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            double recalculatedPrice = _basePrice;
            final discounts =
                state.productDiscountsNominal[widget.product.id] ?? [];
            for (var discount in discounts) {
              recalculatedPrice -= discount;
            }
            context.read<ProductBloc>().add(
                UpdateRoundedPrice(widget.product.id, recalculatedPrice, 0.0));
            CustomToast.showToast("Harga edit direset", ToastType.info);
            Navigator.pop(context);
          },
          child: const Text("Reset Harga"),
        ),
        ElevatedButton(
          onPressed: () {
            final newPrice =
                FormatHelper.parseCurrencyToDouble(_priceController.text);
            context.read<ProductBloc>().add(UpdateRoundedPrice(
                widget.product.id, newPrice, _percentageChange.value));
            context
                .read<ProductBloc>()
                .add(SaveProductNote(widget.product.id, _noteController.text));
            Navigator.pop(context);
          },
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}
