import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../core/widgets/custom_toast.dart';
import '../../../domain/entities/product_entity.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart';

class InfoDialog extends StatefulWidget {
  final ProductEntity product;
  const InfoDialog({super.key, required this.product});

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  late final List<TextEditingController> _percentageControllers;
  late final List<TextEditingController> _nominalControllers;
  late final double _basePrice;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductBloc>().state;
    _basePrice = widget.product.endUserPrice;

    final savedPercentages =
        state.productDiscountsPercentage[widget.product.id] ?? [];
    final savedNominals =
        state.productDiscountsNominal[widget.product.id] ?? [];

    _percentageControllers = List.generate(
        5,
        (i) => TextEditingController(
            text: i < savedPercentages.length && savedPercentages[i] > 0
                ? savedPercentages[i].toStringAsFixed(2)
                : ""));
    _nominalControllers = List.generate(
        5,
        (i) => TextEditingController(
            text: i < savedNominals.length && savedNominals[i] > 0
                ? FormatHelper.formatCurrency(savedNominals[i])
                : ""));
  }

  @override
  void dispose() {
    for (var c in _percentageControllers) {
      c.dispose();
    }
    for (var c in _nominalControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateNominal(int index) {
    setState(() {
      double remainingPrice = _basePrice;
      for (int i = 0; i < index; i++) {
        remainingPrice -=
            FormatHelper.parseCurrencyToDouble(_nominalControllers[i].text);
      }
      double percentage =
          double.tryParse(_percentageControllers[index].text) ?? 0.0;
      double nominal = (remainingPrice * percentage / 100).roundToDouble();
      _nominalControllers[index].text = FormatHelper.formatCurrency(nominal);
    });
  }

  void _updatePercentage(int index) {
    setState(() {
      double remainingPrice = _basePrice;
      for (int i = 0; i < index; i++) {
        remainingPrice -=
            FormatHelper.parseCurrencyToDouble(_nominalControllers[i].text);
      }
      double nominal =
          FormatHelper.parseCurrencyToDouble(_nominalControllers[index].text);
      if (remainingPrice > 0) {
        double percentage = (nominal / remainingPrice) * 100;
        _percentageControllers[index].text =
            percentage > 0 ? percentage.toStringAsFixed(2) : "";
      }
    });
  }

  void _resetValues() {
    setState(() {
      for (int i = 0; i < 5; i++) {
        _percentageControllers[i].clear();
        _nominalControllers[i].clear();
      }
    });
    CustomToast.showToast("Diskon berhasil direset", ToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Input Diskon"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _percentageControllers[i],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: "Diskon ${i + 1} (%)"),
                      onChanged: (val) => _updateNominal(i),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _nominalControllers[i],
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: "Diskon ${i + 1} (Rp)"),
                      onChanged: (val) {
                        final formatted =
                            FormatHelper.formatTextFieldCurrency(val);
                        _nominalControllers[i].value = TextEditingValue(
                          text: formatted,
                          selection:
                              TextSelection.collapsed(offset: formatted.length),
                        );
                        _updatePercentage(i);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _resetValues,
            child: const Text("Reset", style: TextStyle(color: Colors.orange))),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            final percentages = _percentageControllers
                .map((c) => double.tryParse(c.text) ?? 0.0)
                .toList();
            final nominals = _nominalControllers
                .map((c) => FormatHelper.parseCurrencyToDouble(c.text))
                .toList();

            context.read<ProductBloc>().add(
                  UpdateProductDiscounts(
                    productId: widget.product.id,
                    discountPercentages: percentages,
                    discountNominals: nominals,
                    originalPrice: _basePrice,
                  ),
                );
            Navigator.pop(context);
          },
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}
