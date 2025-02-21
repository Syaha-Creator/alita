import 'dart:io';

import 'package:alita_pricelist/core/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
                CustomToast.showToast("Reset Berhasil", ToastType.success);
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
    final theme = Theme.of(context);
    final state = context.read<ProductBloc>().state;
    double originalPrice =
        state.roundedPrices[product.id] ?? product.endUserPrice;

    List<double> savedPercentages = List.from(
        state.productDiscountsPercentage[product.id] ?? List.filled(5, 0.0));
    List<double> savedNominals = List.from(
        state.productDiscountsNominal[product.id] ?? List.filled(5, 0.0));

    List<TextEditingController> percentageControllers = List.generate(
      5,
      (i) => TextEditingController(
        text: savedPercentages[i] > 0
            ? savedPercentages[i].toStringAsFixed(2)
            : "",
      ),
    );

    List<TextEditingController> nominalControllers = List.generate(
      5,
      (i) => TextEditingController(
        text: savedNominals[i] > 0
            ? FormatHelper.formatCurrency(savedNominals[i])
            : "",
      ),
    );

    void updateNominal(int index) {
      double remainingPrice = originalPrice;
      for (int i = 0; i < index; i++) {
        double prevDiscount = double.tryParse(
                nominalControllers[i].text.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0.0;
        remainingPrice -= prevDiscount;
      }
      double percentage =
          double.tryParse(percentageControllers[index].text) ?? 0.0;
      double nominal = (remainingPrice * (percentage / 100)).roundToDouble();
      nominalControllers[index].text = FormatHelper.formatCurrency(nominal);
    }

    void updatePercentage(int index) {
      double remainingPrice = originalPrice;
      for (int i = 0; i < index; i++) {
        double prevDiscount = double.tryParse(
                nominalControllers[i].text.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0.0;
        remainingPrice -= prevDiscount;
      }
      String rawText =
          nominalControllers[index].text.replaceAll(RegExp(r'[^0-9]'), '');
      double nominal = double.tryParse(rawText) ?? 0.0;
      double percentage = (nominal / remainingPrice) * 100;
      percentageControllers[index].text =
          percentage > 0 ? percentage.toStringAsFixed(2) : "";
    }

    void resetValues() {
      for (int i = 0; i < 5; i++) {
        percentageControllers[i].text = "";
        nominalControllers[i].text = "";
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            "Input Diskon",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Diskon ${i + 1} (%)",
                                  style: theme.textTheme.bodyMedium),
                              TextField(
                                controller: percentageControllers[i],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  hintText: "Persentase",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (val) {
                                  updateNominal(i);
                                },
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
                              Text("Diskon ${i + 1} (Rp)",
                                  style: theme.textTheme.bodyMedium),
                              TextField(
                                controller: nominalControllers[i],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Nominal",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (val) {
                                  String formattedValue =
                                      FormatHelper.formatTextFieldCurrency(val);
                                  nominalControllers[i].value =
                                      TextEditingValue(
                                    text: formattedValue,
                                    selection: TextSelection.collapsed(
                                        offset: formattedValue.length),
                                  );
                                  updatePercentage(i);
                                },
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                resetValues();
                CustomToast.showToast(
                  "Diskon berhasil direset",
                  ToastType.success,
                );
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
                List<double> updatedPercentages = percentageControllers
                    .map((e) => double.tryParse(e.text) ?? 0.0)
                    .toList();
                List<double> updatedNominals = nominalControllers.map((e) {
                  String rawText = e.text.replaceAll(RegExp(r'[^0-9]'), '');
                  return double.tryParse(rawText) ?? 0.0;
                }).toList();

                context.read<ProductBloc>().add(
                      UpdateProductDiscounts(
                        productId: product.id,
                        discountPercentages: updatedPercentages,
                        discountNominals: updatedNominals,
                        originalPrice: product.endUserPrice,
                      ),
                    );

                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  static void showSharePopup(BuildContext context, ProductEntity product) {
    final theme = Theme.of(context);
    final state = context.read<ProductBloc>().state;
    ScreenshotController screenshotController = ScreenshotController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Bagikan Produk",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
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
              child: Text(
                "Tutup",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        Center(child: CircularProgressIndicator()),
                  );

                  if (Platform.isAndroid) {
                    var status = await Permission.storage.request();
                    if (!status.isGranted) {
                      Navigator.pop(context);
                      CustomToast.showToast(
                        "Izin penyimpanan diperlukan",
                        ToastType.error,
                      );
                      return;
                    }
                  }
                  Directory? directory;
                  if (Platform.isAndroid) {
                    directory = Directory('/storage/emulated/0/Download');
                  } else if (Platform.isIOS) {
                    directory = await getApplicationDocumentsDirectory();
                  }

                  if (!await directory!.exists()) {
                    await directory.create(recursive: true);
                  }

                  String formattedKasur = product.kasur.replaceAll(' ', '_');
                  String timestamp = DateTime.now()
                      .toLocal()
                      .toString()
                      .replaceAll(':', '-')
                      .split('.')[0]
                      .replaceAll(' ', '_');
                  String fileName = "${formattedKasur}_$timestamp.png";
                  String filePath = '${directory.path}/$fileName';

                  await screenshotController.captureAndSave(
                    directory.path,
                    fileName: fileName,
                  );

                  File file = File(filePath);
                  if (!await file.exists()) {
                    throw Exception("Gagal menangkap layar");
                  }

                  await ImageGallerySaver.saveFile(filePath);

                  DateTime now = DateTime.now();
                  String formattedPricelist =
                      FormatHelper.formatCurrency(product.pricelist);
                  double netPrice =
                      state.roundedPrices[product.id] ?? product.endUserPrice;
                  String formattedNetPrice =
                      FormatHelper.formatCurrency(netPrice);

                  String monthName = FormatHelper.getMonthName(now.month);
                  String year = now.year.toString();

                  String shareText =
                      "Matras ${product.brand} ${product.kasur} (${product.ukuran})\n"
                      "Harga Pricelist : $formattedPricelist\n"
                      "Harga After Disc : $formattedNetPrice\n"
                      "Hanya berlaku di bulan $monthName $year";

                  if (context.mounted) {
                    Navigator.pop(context);
                    await Share.shareXFiles([XFile(file.path)],
                        text: shareText);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    CustomToast.showToast(
                        "Gagal menangkap layar", ToastType.error);
                  }
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
