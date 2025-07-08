import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';

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
  late List<TextEditingController> percentageControllers;
  late List<TextEditingController> nominalControllers;
  late double basePrice;
  late List<double> _initialPercentages;
  late List<double> _initialNominals;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductBloc>().state;
    basePrice = widget.product.endUserPrice;
    _initialPercentages = List.from(
        state.productDiscountsPercentage[widget.product.id] ??
            List.filled(5, 0.0));
    _initialNominals = List.from(
        state.productDiscountsNominal[widget.product.id] ??
            List.filled(5, 0.0));
    percentageControllers = List.generate(
        5,
        (i) => TextEditingController(
            text: (i < _initialPercentages.length && _initialPercentages[i] > 0)
                ? _initialPercentages[i].toStringAsFixed(2)
                : ""));
    nominalControllers = List.generate(
        5,
        (i) => TextEditingController(
            text: (i < _initialNominals.length && _initialNominals[i] > 0)
                ? FormatHelper.formatCurrency(_initialNominals[i])
                : ""));
  }

  @override
  void dispose() {
    for (var controller in percentageControllers) {
      controller.dispose();
    }
    for (var controller in nominalControllers) {
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
      double nominal = (remainingPrice * percentage / 100).roundToDouble();
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
        percentageControllers[index].text =
            percentage > 0 ? percentage.toStringAsFixed(2) : "";
      }
    });
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
              style: GoogleFonts.montserrat(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Konten di dalam SingleChildScrollView agar tidak overflow
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
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
                                  labelText: "Diskon ${i + 1} (%)",
                                  border: OutlineInputBorder()),
                              onChanged: (val) => updateNominal(i))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: TextField(
                              controller: nominalControllers[i],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: "Diskon ${i + 1} (Rp)",
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
                              })),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < 5; i++) {
                        percentageControllers[i].clear();
                        nominalControllers[i].clear();
                      }
                    });
                    context.read<ProductBloc>().add(UpdateRoundedPrice(
                        widget.product.id, widget.product.endUserPrice, 0.0));
                    CustomToast.showToast("Diskon direset", ToastType.info);
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
                onPressed: () {
                  // 1. Ambil nilai saat ini dari controllers
                  final currentPercentages = percentageControllers
                      .map((c) => double.tryParse(c.text) ?? 0.0)
                      .toList();
                  final currentNominals = nominalControllers
                      .map((c) => FormatHelper.parseCurrencyToDouble(c.text))
                      .toList();

                  // 2. Bandingkan nilai saat ini dengan nilai awal
                  final listEquals = const ListEquality().equals;
                  final bool hasChanged =
                      !listEquals(currentPercentages, _initialPercentages) ||
                          !listEquals(currentNominals, _initialNominals);

                  // 3. Hanya update jika ada perubahan
                  if (hasChanged) {
                    context.read<ProductBloc>().add(UpdateProductDiscounts(
                          productId: widget.product.id,
                          discountPercentages: currentPercentages,
                          discountNominals: currentNominals,
                          originalPrice: basePrice,
                        ));
                  } else {
                    // Opsional: beritahu pengguna tidak ada perubahan
                    print("Tidak ada perubahan diskon yang perlu disimpan.");
                  }

                  // 4. Tutup dialog
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
