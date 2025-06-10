import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/format_helper.dart';
import '../../../domain/entities/product_entity.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart'; // Import Google Fonts

class CreditDialog extends StatefulWidget {
  final ProductEntity product;
  const CreditDialog({super.key, required this.product});

  @override
  State<CreditDialog> createState() => _CreditDialogState();
}

class _CreditDialogState extends State<CreditDialog> {
  late final TextEditingController monthController;
  late final TextEditingController installmentController;
  late double latestNetPrice;

  @override
  void initState() {
    super.initState();
    final productState = context.read<ProductBloc>().state;
    latestNetPrice = productState.roundedPrices[widget.product.id] ??
        widget.product.endUserPrice;
    int savedMonths = productState.installmentMonths[widget.product.id] ?? 0;
    monthController = TextEditingController(
        text: savedMonths > 0 ? savedMonths.toString() : "");
    installmentController =
        TextEditingController(text: FormatHelper.formatCurrency(0.0));
    monthController.addListener(_calculateAndDisplayInstallment);
    if (savedMonths > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateAndDisplayInstallment();
        }
      });
    }
  }

  void _calculateAndDisplayInstallment() {
    final months = int.tryParse(monthController.text) ?? 0;
    double installmentValue = 0.0;
    if (months > 0) {
      installmentValue = latestNetPrice / months;
    }
    installmentController.text = FormatHelper.formatCurrency(installmentValue);
  }

  @override
  void dispose() {
    monthController.removeListener(_calculateAndDisplayInstallment);
    monthController.dispose();
    installmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // === PERUBAHAN UTAMA: Ganti AlertDialog dengan layout biasa ===
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        // Padding bawah untuk mengakomodasi keyboard
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Judul
          Text(
            "Hitung Cicilan",
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Konten (Input Fields)
          TextField(
            controller: monthController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Jumlah Bulan",
              hintText: "Contoh: 12",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            controller: installmentController,
            decoration: const InputDecoration(
              labelText: "Cicilan per Bulan",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Tombol Aksi
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal")),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final months = int.tryParse(monthController.text) ?? 0;
                  final installment = FormatHelper.parseCurrencyToDouble(
                      installmentController.text);

                  if (months > 0) {
                    context.read<ProductBloc>().add(SaveInstallment(
                        widget.product.id, months, installment));
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
          )
        ],
      ),
    );
  }
}
