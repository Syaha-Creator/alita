// lib/features/product/presentation/widgets/dialogs/credit_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../domain/entities/product_entity.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart';

class CreditDialog extends StatefulWidget {
  final ProductEntity product;
  const CreditDialog({super.key, required this.product});

  @override
  State<CreditDialog> createState() => _CreditDialogState();
}

class _CreditDialogState extends State<CreditDialog> {
  late final TextEditingController _monthController;
  late final TextEditingController _installmentController;
  late double _latestNetPrice;

  @override
  void initState() {
    super.initState();
    final productState = context.read<ProductBloc>().state;
    _latestNetPrice = productState.roundedPrices[widget.product.id] ??
        widget.product.endUserPrice;

    int savedMonths = productState.installmentMonths[widget.product.id] ?? 0;

    _monthController = TextEditingController(
        text: savedMonths > 0 ? savedMonths.toString() : "");

    // Controller untuk hasil, diawali dengan Rp 0
    _installmentController =
        TextEditingController(text: FormatHelper.formatCurrency(0.0));

    // Tambahkan listener untuk input bulan
    _monthController.addListener(_calculateAndDisplayInstallment);

    // Jika sudah ada data tersimpan, langsung hitung saat dialog dibuka
    if (savedMonths > 0) {
      _calculateAndDisplayInstallment();
    }
  }

  void _calculateAndDisplayInstallment() {
    final months = int.tryParse(_monthController.text) ?? 0;
    double installmentValue = 0.0;
    if (months > 0) {
      installmentValue = _latestNetPrice / months;
    }
    // Update teks pada controller hasil
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
            controller:
                _installmentController, // Gunakan controller untuk hasil
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
