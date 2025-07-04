import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/format_helper.dart';
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
  late TextEditingController priceController;
  late TextEditingController noteController;
  late ValueNotifier<double> percentageChange;
  late double priceBeforeEdit;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductBloc>().state;
    final hasProgrammaticDiscount =
        (state.productDiscountsPercentage[widget.product.id]?.isNotEmpty ??
            false);
    priceBeforeEdit =
        state.roundedPrices[widget.product.id] ?? widget.product.endUserPrice;

    if (hasProgrammaticDiscount &&
        state.roundedPrices[widget.product.id] == null) {
      double currentPrice = widget.product.pricelist;
      for (var disc in state.productDiscountsPercentage[widget.product.id]!) {
        currentPrice -= currentPrice * (disc / 100);
      }
      priceBeforeEdit = currentPrice;
    }
    priceController = TextEditingController(
        text: FormatHelper.formatCurrency(priceBeforeEdit));
    noteController = TextEditingController(
        text: state.productNotes[widget.product.id] ?? "");
    percentageChange =
        ValueNotifier(state.priceChangePercentages[widget.product.id] ?? 0.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatePercentage();
    });
  }

  void _calculatePercentage() {
    String rawText = priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    double newPrice = double.tryParse(rawText) ?? priceBeforeEdit;
    if (priceBeforeEdit > 0 && newPrice > 0) {
      double diff = ((priceBeforeEdit - newPrice) / priceBeforeEdit) * 100;
      percentageChange.value = diff;
    } else {
      percentageChange.value = 0.0;
    }
  }

  @override
  void dispose() {
    priceController.dispose();
    noteController.dispose();
    percentageChange.dispose();
    super.dispose();
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
          Text("Edit Harga & Catatan",
              style: GoogleFonts.montserrat(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: "Harga Net Baru", border: OutlineInputBorder()),
            onChanged: (value) {
              priceController.value = TextEditingValue(
                text: FormatHelper.formatTextFieldCurrency(value),
                selection: TextSelection.collapsed(
                    offset: FormatHelper.formatTextFieldCurrency(value).length),
              );
              _calculatePercentage();
            },
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: percentageChange,
            builder: (context, value, _) {
              return Text(
                "Perubahan: ${value.toStringAsFixed(2)}%",
                style: TextStyle(color: value < 0 ? Colors.green : Colors.red),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
                labelText: "Catatan", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal")),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final newPrice =
                      FormatHelper.parseCurrencyToDouble(priceController.text);
                  context.read<ProductBloc>().add(UpdateRoundedPrice(
                      widget.product.id, newPrice, percentageChange.value));
                  context.read<ProductBloc>().add(
                      SaveProductNote(widget.product.id, noteController.text));
                  Navigator.pop(context);
                },
                child: const Text("Simpan"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
