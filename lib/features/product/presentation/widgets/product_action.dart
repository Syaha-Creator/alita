import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/format_helper.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/event/product_event.dart';
import '../bloc/product_bloc.dart';
import 'product_card.dart';

class ProductActions {
  static void showCreditPopup(BuildContext context, ProductEntity product) {
    final theme = Theme.of(context);
    final state = context.read<ProductBloc>().state;

    TextEditingController monthController = TextEditingController();

    // Ambil harga net terbaru yang sudah diperbarui
    double latestNetPrice =
        state.roundedPrices[product.id] ?? product.endUserPrice;

    int savedMonths = state.installmentMonths[product.id] ?? 0;
    double savedInstallment =
        state.installmentPerMonth[product.id] ?? latestNetPrice;

    monthController.text = savedMonths > 0 ? savedMonths.toString() : "";

    ValueNotifier<double> monthlyInstallment = ValueNotifier(savedInstallment);

    void calculateInstallment() {
      int months = int.tryParse(monthController.text) ?? 0;
      if (months > 0) {
        monthlyInstallment.value = latestNetPrice / months;
      } else {
        monthlyInstallment.value = latestNetPrice;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            "Hitung Cicilan",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Jumlah Bulan", style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 5),
                        TextField(
                          controller: monthController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Masukkan bulan...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) => calculateInstallment(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cicilan per Bulan",
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 5),
                        ValueListenableBuilder<double>(
                          valueListenable: monthlyInstallment,
                          builder: (context, value, _) {
                            return TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: FormatHelper.formatCurrency(value),
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Batal",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                int months = int.tryParse(monthController.text) ?? 0;
                double perMonth = monthlyInstallment.value;

                if (months > 0) {
                  context.read<ProductBloc>().add(SaveInstallment(
                        product.id,
                        months,
                        perMonth,
                      ));
                } else {
                  context
                      .read<ProductBloc>()
                      .add(RemoveInstallment(product.id));
                }

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  static void showEditPopup(BuildContext context, ProductEntity product) {
    final theme = Theme.of(context);
    final state = context.read<ProductBloc>().state;
    double originalNetPrice = product.endUserPrice;
    double latestNetPrice =
        state.roundedPrices[product.id] ?? product.endUserPrice;
    TextEditingController priceController = TextEditingController(
      text: FormatHelper.formatCurrency(latestNetPrice),
    );
    ValueNotifier<double> percentageChange = ValueNotifier(
      state.priceChangePercentages[product.id] ?? 0.0,
    );

    void calculatePercentage() {
      String rawText = priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      double newPrice = double.tryParse(rawText) ?? product.endUserPrice;
      double originalPrice = product.endUserPrice;
      double diff = ((originalPrice - newPrice) / originalPrice) * 100;
      percentageChange.value = diff;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            "Edit Harga Net",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Masukkan harga net baru:",
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  priceController.value = TextEditingValue(
                    text: FormatHelper.formatTextFieldCurrency(value),
                    selection: TextSelection.collapsed(
                        offset:
                            FormatHelper.formatTextFieldCurrency(value).length),
                  );
                  calculatePercentage();
                },
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<double>(
                valueListenable: percentageChange,
                builder: (context, value, _) {
                  return Text(
                    "Perubahan: ${value.toStringAsFixed(2)}%",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: value < 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                priceController.text =
                    FormatHelper.formatCurrency(originalNetPrice);
                percentageChange.value = 0.0;
                context.read<ProductBloc>().add(UpdateRoundedPrice(
                      product.id,
                      originalNetPrice,
                      0.0,
                    ));
                Navigator.pop(context);
              },
              child: Text(
                "Reset",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Pastikan input angka tidak ada pemisah ribuan sebelum di-convert ke double
                String rawText =
                    priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
                double newPrice =
                    double.tryParse(rawText) ?? product.endUserPrice;
                double percentage =
                    ((product.endUserPrice - newPrice) / product.endUserPrice) *
                        100;

                // Simpan harga baru ke dalam state
                context.read<ProductBloc>().add(UpdateRoundedPrice(
                      product.id,
                      newPrice,
                      percentage,
                    ));

                // Setelah simpan, pastikan cicilan juga diperbarui
                int savedMonths = state.installmentMonths[product.id] ?? 0;
                if (savedMonths > 0) {
                  double newInstallment = newPrice / savedMonths;
                  context.read<ProductBloc>().add(SaveInstallment(
                        product.id,
                        savedMonths,
                        newInstallment,
                      ));
                }

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  static void showInfoPopup(BuildContext context, ProductEntity product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Informasi Produk"),
          content: Text("Detail produk: ${product.kasur}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  static void showSharePopup(BuildContext context, ProductEntity product) {
    ScreenshotController screenshotController = ScreenshotController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Bagikan Produk"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Bagikan produk ini ke teman atau media sosial."),
              const SizedBox(height: 10),
              Screenshot(
                controller: screenshotController,
                child: ProductCard(product: product, hideButtons: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final directory = await getTemporaryDirectory();
                  String filePath = '${directory.path}/product.png';

                  await screenshotController.captureAndSave(
                    directory.path,
                    fileName: "product.png",
                  );

                  File file = File(filePath);
                  if (kIsWeb) {
                    await Share.share('Lihat produk ini!');
                  } else {
                    await Share.shareXFiles([XFile(file.path)],
                        text: 'Lihat produk ini!');
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal membagikan produk: $e")),
                  );
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
