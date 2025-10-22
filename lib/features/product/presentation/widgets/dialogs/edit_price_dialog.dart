import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/format_helper.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/widgets/custom_toast.dart';
import '../../../../../theme/app_colors.dart';
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
  late bool isPriceLocked;
  late String lockReason;

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

    // Check if current price is at or below bottom price analyst
    final currentPrice =
        state.roundedPrices[widget.product.id] ?? widget.product.endUserPrice;
    isPriceLocked = currentPrice <= widget.product.bottomPriceAnalyst;
    lockReason = isPriceLocked ? "Discount dan Harga Sudah Maksimal" : "";

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

  bool _validatePrice(double newPrice) {
    if (newPrice < widget.product.bottomPriceAnalyst) {
      CustomToast.showToast(
        "Tidak diperbolehkan",
        ToastType.error,
      );
      return false;
    }
    return true;
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
        left: ResponsiveHelper.getResponsivePadding(context).left,
        right: ResponsiveHelper.getResponsivePadding(context).right,
        top: ResponsiveHelper.getResponsiveSpacing(
          context,
          mobile: 16,
          tablet: 20,
          desktop: 24,
        ),
        bottom: MediaQuery.of(context).viewInsets.bottom +
            ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Edit Harga & Catatan",
              style:
                  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Price Lock Warning
          if (isPriceLocked) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lockReason,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            enabled: !isPriceLocked,
            decoration: InputDecoration(
              labelText: "Harga Net Baru",
              border: const OutlineInputBorder(),
              suffixIcon: isPriceLocked
                  ? Icon(
                      Icons.lock,
                      color: AppColors.error,
                    )
                  : null,
            ),
            onChanged: (value) {
              if (isPriceLocked) return;

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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: value < 0
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error,
                    ),
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
                onPressed: isPriceLocked
                    ? null
                    : () {
                        try {
                          final newPrice = FormatHelper.parseCurrencyToDouble(
                              priceController.text);

                          if (!_validatePrice(newPrice)) {
                            return;
                          }

                          context.read<ProductBloc>().add(UpdateRoundedPrice(
                              widget.product.id,
                              newPrice,
                              percentageChange.value));
                          context.read<ProductBloc>().add(SaveProductNote(
                              widget.product.id, noteController.text));
                          Navigator.pop(context);
                        } catch (e) {
                          CustomToast.showToast(
                            "Gagal menyimpan harga: ${e.toString()}",
                            ToastType.error,
                          );
                        }
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
