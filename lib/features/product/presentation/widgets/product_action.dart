import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import 'product_card.dart';

class ProductActions {
  static void showCreditPopup(BuildContext context, ProductEntity product) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CreditPopupDialog(product: product),
    );
  }

  static void showEditPopup(BuildContext context, ProductEntity product) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditPopupDialog(product: product),
    );
  }

  static void showInfoPopup(BuildContext context, ProductEntity product) {
    showDialog(
      context: context,
      builder: (dialogContext) => _InfoPopupDialog(product: product),
    );
  }

  static void showSharePopup(BuildContext context, ProductEntity product) {
    final state = context.read<ProductBloc>().state;
    ScreenshotController screenshotController = ScreenshotController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Bagikan Produk"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Bagikan produk ini ke teman atau media sosial."),
              const SizedBox(height: 10),
              Screenshot(
                controller: screenshotController,
                child: ProductCard(product: product, hideButtons: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Tutup"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final imageBytes = await screenshotController.capture();
                  Navigator.pop(dialogContext);

                  if (imageBytes == null) {
                    CustomToast.showToast(
                        "Gagal mengambil gambar produk", ToastType.error);
                    return;
                  }

                  double netPrice =
                      state.roundedPrices[product.id] ?? product.endUserPrice;
                  String shareText =
                      "Produk: ${product.kasur} (${product.ukuran})\n"
                      "Harga Pricelist: ${FormatHelper.formatCurrency(product.pricelist)}\n"
                      "Harga Net: ${FormatHelper.formatCurrency(netPrice)}";

                  final imageFile = XFile.fromData(imageBytes,
                      mimeType: 'image/png', name: 'product.png');

                  await Share.shareXFiles([imageFile], text: shareText);
                  Navigator.pop(dialogContext);
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                  CustomToast.showToast(
                      "Gagal membagikan: $e", ToastType.error);
                }
              },
              child: const Text("Bagikan"),
            ),
          ],
        );
      },
    );
  }
}

class _CreditPopupDialog extends StatefulWidget {
  final ProductEntity product;
  const _CreditPopupDialog({required this.product});

  @override
  _CreditPopupDialogState createState() => _CreditPopupDialogState();
}

class _CreditPopupDialogState extends State<_CreditPopupDialog> {
  late final TextEditingController _monthController;
  late final TextEditingController _installmentController;
  late double _latestNetPrice;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductBloc>().state;
    _latestNetPrice =
        state.roundedPrices[widget.product.id] ?? widget.product.endUserPrice;

    int savedMonths = state.installmentMonths[widget.product.id] ?? 0;

    _monthController = TextEditingController(
        text: savedMonths > 0 ? savedMonths.toString() : "");

    _installmentController =
        TextEditingController(text: FormatHelper.formatCurrency(0.0));

    _monthController.addListener(_calculateAndDisplayInstallment);

    if (savedMonths > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateAndDisplayInstallment();
      });
    }
  }

  void _calculateAndDisplayInstallment() {
    final months = int.tryParse(_monthController.text) ?? 0;
    double installmentValue = 0.0;
    if (months > 0) {
      installmentValue = _latestNetPrice / months;
    }

    _installmentController.text = FormatHelper.formatCurrency(installmentValue);
  }

  @override
  void dispose() {
    _monthController.removeListener(_calculateAndDisplayInstallment);
    _monthController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Hitung Cicilan"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _monthController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Jumlah Bulan",
              hintText: "Contoh: 12",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            controller: _installmentController,
            decoration: const InputDecoration(
              labelText: "Cicilan per Bulan",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            final months = int.tryParse(_monthController.text) ?? 0;
            final installment =
                FormatHelper.parseCurrencyToDouble(_installmentController.text);

            if (months > 0) {
              context
                  .read<ProductBloc>()
                  .add(SaveInstallment(widget.product.id, months, installment));
            } else {
              context
                  .read<ProductBloc>()
                  .add(RemoveInstallment(widget.product.id));
            }
            Navigator.pop(context);
          },
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}

class _EditPopupDialog extends StatefulWidget {
  final ProductEntity product;
  const _EditPopupDialog({required this.product});

  @override
  _EditPopupDialogState createState() => _EditPopupDialogState();
}

class _EditPopupDialogState extends State<_EditPopupDialog> {
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  late final ValueNotifier<double> _percentageChange;
  late final double _priceBeforeEdit;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductBloc>().state;
    _priceBeforeEdit =
        state.roundedPrices[widget.product.id] ?? widget.product.endUserPrice;

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
    return AlertDialog(
      title: const Text("Edit Harga & Catatan"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Harga Net Baru"),
            onChanged: (value) {
              final formatted = FormatHelper.formatTextFieldCurrency(value);
              _priceController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
              _calculatePercentage();
            },
          ),
          ValueListenableBuilder<double>(
            valueListenable: _percentageChange,
            builder: (context, value, _) =>
                Text("Perubahan: ${value.toStringAsFixed(2)}%"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: "Catatan"),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal")),
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

class _InfoPopupDialog extends StatefulWidget {
  final ProductEntity product;
  const _InfoPopupDialog({required this.product});

  @override
  _InfoPopupDialogState createState() => _InfoPopupDialogState();
}

class _InfoPopupDialogState extends State<_InfoPopupDialog> {
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

            double finalNetPrice = _basePrice;
            for (var nominal in nominals) {
              finalNetPrice -= nominal;
            }

            context.read<ProductBloc>().add(
                  UpdateProductDiscounts(
                    productId: widget.product.id,
                    discountPercentages: percentages,
                    discountNominals: nominals,
                    originalPrice: _basePrice,
                  ),
                );

            context
                .read<ProductBloc>()
                .add(UpdateRoundedPrice(widget.product.id, finalNetPrice, 0.0));

            Navigator.pop(context);
          },
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}
