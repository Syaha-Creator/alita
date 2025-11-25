import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';

import '../../../../../core/utils/format_helper.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/widgets/custom_toast.dart';
import '../../../../../config/dependency_injection.dart';
import '../../../../../services/leader_service.dart';
import '../../../../../features/approval/data/models/approval_model.dart';
import '../../../domain/entities/product_entity.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart';
import '../../bloc/product_state.dart';

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
  bool hasChanged = false;
  LeaderByUserModel? _leaderData;

  void _checkHasChanged() {
    final currentPercentages = percentageControllers
        .map((c) => double.tryParse(c.text) ?? 0.0)
        .toList();
    final currentNominals = nominalControllers
        .map((c) => FormatHelper.parseCurrencyToDouble(c.text))
        .toList();
    setState(() {
      hasChanged = !const ListEquality()
              .equals(currentPercentages, _initialPercentages) ||
          !const ListEquality().equals(currentNominals, _initialNominals);
    });
  }

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
    hasChanged = false;
    _loadLeaderData();
  }

  Future<void> _loadLeaderData() async {
    try {
      final leaderService = locator<LeaderService>();
      final leaderData = await leaderService.getLeaderByUser();

      setState(() {
        _leaderData = leaderData;
      });
    } catch (e) {
      // No-op, leader data will be null if loading fails
    }
  }

  @override
  void dispose() {
    for (var controller in percentageControllers) {
      controller.removeListener(_checkHasChanged);
      controller.dispose();
    }
    for (var controller in nominalControllers) {
      controller.removeListener(_checkHasChanged);
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
      // --- VALIDASI DISKON MAKSIMUM ---
      final maxDisc = _getMaxDisc(index);
      if (percentage > maxDisc * 100) {
        percentage = maxDisc * 100;
        percentageControllers[index].text = (maxDisc * 100).toStringAsFixed(2);
        CustomToast.showToast(
          "Diskon ${index + 1} tidak boleh melebihi ${(maxDisc * 100).toStringAsFixed(0)}%",
          ToastType.error,
        );
      }
      double nominal = (remainingPrice * (percentage / 100)).roundToDouble();
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
        // --- VALIDASI DISKON MAKSIMUM ---
        final maxDisc = _getMaxDisc(index);
        if (percentage > maxDisc * 100) {
          percentage = maxDisc * 100;
          double maxNominal = (remainingPrice * maxDisc).roundToDouble();
          nominalControllers[index].text =
              FormatHelper.formatCurrency(maxNominal);
          CustomToast.showToast(
            "Diskon ${index + 1} tidak boleh melebihi ${(maxDisc * 100).toStringAsFixed(0)}%",
            ToastType.error,
          );
        }
        percentageControllers[index].text =
            percentage > 0 ? percentage.toStringAsFixed(2) : "";
      }
    });
  }

  double _getMaxDisc(int index) {
    switch (index) {
      case 0:
        return widget.product.disc1;
      case 1:
        return widget.product.disc2;
      case 2:
        return widget.product.disc3;
      case 3:
        return widget.product.disc4;
      case 4:
        return widget.product.disc5;
      default:
        return 1.0;
    }
  }

  String _getDiscountLabel(int discountLevel, bool isPercentage) {
    String levelText = "Diskon $discountLevel";

    if (_leaderData != null) {
      switch (discountLevel) {
        case 1:
          levelText = "Diskon SPG";
          break;
        case 2:
          if (_leaderData!.directLeader != null) {
            levelText = "Diskon SPV";
          }
          break;
        case 3:
          if (_leaderData!.indirectLeader != null) {
            levelText = "Diskon RSM";
          }
          break;
        case 4:
          if (_leaderData!.analyst != null) {
            levelText = "Diskon Analyst";
          }
          break;
        case 5:
          if (_leaderData!.controller != null) {
            levelText = "Diskon Controller";
          }
          break;
      }
    }

    return isPercentage ? "$levelText (%)" : "$levelText (Rp)";
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (prev, curr) {
        // Hanya listen jika nominal diskon berubah untuk produk ini
        final prevNom = prev.productDiscountsNominal[widget.product.id] ?? [];
        final currNom = curr.productDiscountsNominal[widget.product.id] ?? [];
        return !const ListEquality().equals(prevNom, currNom);
      },
      listener: (context, state) {
        final nominals = state.productDiscountsNominal[widget.product.id] ?? [];
        for (int i = 0; i < 5; i++) {
          final val = (i < nominals.length && nominals[i] > 0)
              ? FormatHelper.formatCurrency(nominals[i])
              : "";
          if (nominalControllers[i].text != val) {
            nominalControllers[i].text = val;
          }
        }
      },
      child: Padding(
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
            Text("Input Diskon",
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Konten di dalam SingleChildScrollView agar tidak overflow
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  // Hanya tampilkan discount field jika disc value > 0
                  final discValue = _getMaxDisc(i);
                  if (discValue <= 0) return const SizedBox.shrink();

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
                                    labelText: _getDiscountLabel(i + 1, true),
                                    border: OutlineInputBorder()),
                                onChanged: (val) {
                                  updateNominal(i);
                                  _checkHasChanged();
                                })),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextField(
                                controller: nominalControllers[i],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    labelText: _getDiscountLabel(i + 1, false),
                                    border: OutlineInputBorder()),
                                onChanged: (val) {
                                  final formatted =
                                      FormatHelper.formatTextFieldCurrency(val);
                                  nominalControllers[i].value =
                                      TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                  updatePercentage(i);
                                  _checkHasChanged();
                                })),
                      ],
                    ),
                  );
                })
                    .where((widget) => widget != const SizedBox.shrink())
                    .toList(),
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
                  onPressed: hasChanged
                      ? () {
                          // 1. Ambil nilai saat ini dari controllers
                          final currentPercentages = percentageControllers
                              .map((c) => double.tryParse(c.text) ?? 0.0)
                              .toList();
                          final currentNominals = nominalControllers
                              .map((c) =>
                                  FormatHelper.parseCurrencyToDouble(c.text))
                              .toList();

                          // 2. Ambil nilai dari state (hasil rounded price)
                          final state = context.read<ProductBloc>().state;
                          final statePercentages =
                              state.productDiscountsPercentage[
                                      widget.product.id] ??
                                  [];
                          final stateNominals = state
                                  .productDiscountsNominal[widget.product.id] ??
                              [];

                          // 3. Bandingkan nilai controller dengan state
                          final listEquals = const ListEquality().equals;
                          final bool isManual = !listEquals(
                                  currentPercentages, statePercentages) ||
                              !listEquals(currentNominals, stateNominals);

                          // 4. Simpan sesuai input user atau hasil rounded price
                          final toSavePercentages =
                              isManual ? currentPercentages : statePercentages;
                          final toSaveNominals =
                              isManual ? currentNominals : stateNominals;

                          // 5. Hanya update jika ada perubahan
                          if (isManual) {
                            // Get leader IDs for approval
                            final leaderService = locator<LeaderService>();
                            final leaderIds = <int?>[];

                            for (int i = 0; i < 5; i++) {
                              final leaderId =
                                  leaderService.getLeaderIdByDiscountLevel(
                                      _leaderData, i + 1);
                              leaderIds.add(leaderId);
                            }

                            context
                                .read<ProductBloc>()
                                .add(UpdateProductDiscounts(
                                  productId: widget.product.id,
                                  discountPercentages: toSavePercentages,
                                  discountNominals: toSaveNominals,
                                  originalPrice: basePrice,
                                  leaderIds: leaderIds,
                                ));
                          } else {
                            // Tidak ada perubahan, tidak perlu update apapun
                          }

                          // 6. Tutup dialog
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text("Simpan"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
