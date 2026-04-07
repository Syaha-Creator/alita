import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../data/models/product.dart';

/// Shows the cascading discount modal bottom sheet.
///
/// [activeProduct] is used to derive disc1..disc8 limits.
/// [additionalDiscountBaseTotal] when set (e.g. dari halaman detail: total EUP
/// ter-anchor, sudah termasuk diskon toko di mode indirect) dipakai sebagai
/// dasar diskon tambahan; jika null, dipakai jumlah EUP penuh dari produk.
/// [currentDiscounts] holds the current applied discount percentages (decimal 0-1).
/// [onApply] is called with the new list of discount percentages.
void showDiscountModalGlobal(
  BuildContext context,
  Product activeProduct,
  List<double> currentDiscounts,
  void Function(List<double>) onApply, {
  double? additionalDiscountBaseTotal,
}) {
  List<double> maxLimits = [
    activeProduct.disc1,
    activeProduct.disc2,
    activeProduct.disc3,
    activeProduct.disc4,
    activeProduct.disc5,
    activeProduct.disc6,
    activeProduct.disc7,
    activeProduct.disc8,
  ].where((d) => d > 0).toList();

  final baseTotalEup = additionalDiscountBaseTotal ??
      (activeProduct.eupKasur +
          activeProduct.eupDivan +
          activeProduct.eupHeadboard +
          activeProduct.eupSorong);

  if (maxLimits.isEmpty && activeProduct.program.isNotEmpty) {
    final match = RegExp(r'(\d+)\s*%?').firstMatch(activeProduct.program);
    if (match != null) {
      final percent = int.tryParse(match.group(1) ?? '') ?? 0;
      if (percent > 0 && percent <= 100) {
        maxLimits = [percent / 100];
      }
    }
  }

  if (maxLimits.isEmpty) {
    AppFeedback.show(
      context,
      message: 'Tidak ada alokasi diskon',
      type: AppFeedbackType.warning,
      floating: true,
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DiscountModalContent(
      maxLimits: maxLimits,
      baseTotalEup: baseTotalEup,
      currentDiscounts: currentDiscounts,
      onApply: onApply,
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}

/// Modal content for the cascading discount form.
/// Controllers are disposed in [dispose] to avoid "used after disposed" errors.
class DiscountModalContent extends StatefulWidget {
  const DiscountModalContent({
    super.key,
    required this.maxLimits,
    required this.baseTotalEup,
    required this.currentDiscounts,
    required this.onApply,
    required this.onClose,
  });

  final List<double> maxLimits;
  final double baseTotalEup;
  final List<double> currentDiscounts;
  final void Function(List<double>) onApply;
  final VoidCallback onClose;

  @override
  State<DiscountModalContent> createState() => _DiscountModalContentState();
}

class _DiscountModalContentState extends State<DiscountModalContent> {
  late final List<TextEditingController> _controllers;
  late List<String> _inputTypes;
  late List<String?> _errorMessages;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.maxLimits.length,
      (i) => TextEditingController(
        text: widget.currentDiscounts.length > i
            ? (widget.currentDiscounts[i] * 100)
                .toStringAsFixed(2)
                .replaceAll('.00', '')
            : '',
      ),
    );
    _inputTypes = List<String>.generate(widget.maxLimits.length, (_) => '%');
    _errorMessages = List<String?>.generate(
      widget.maxLimits.length,
      (_) => null,
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showToast(BuildContext context, String message) {
    AppFeedback.show(
      context,
      message: message,
      type: AppFeedbackType.warning,
      floating: true,
    );
  }

  double _getRunningBaseBeforeTier(int tierIndex) {
    double runningTotal = widget.baseTotalEup;
    for (int j = 0; j < tierIndex && j < _controllers.length; j++) {
      final text = _controllers[j].text.replaceAll(',', '.');
      if (text.isEmpty) continue;
      final val = double.tryParse(text);
      if (val == null || val <= 0) continue;
      if (_inputTypes[j] == '%') {
        runningTotal -= (runningTotal * (val / 100));
      } else {
        runningTotal -= val;
      }
    }
    return runningTotal;
  }

  void _validateAndCalculate([BuildContext? context]) {
    double runningTotal = widget.baseTotalEup;
    for (int i = 0; i < widget.maxLimits.length; i++) {
      _errorMessages[i] = null;
      final text = _controllers[i].text.replaceAll(',', '.');
      if (text.isEmpty) continue;

      final inputValue = double.tryParse(text);
      if (inputValue == null) {
        _errorMessages[i] = 'Input tidak valid';
        continue;
      }

      final limitPercent = widget.maxLimits[i];
      final maxNominalAllowed = runningTotal * limitPercent;

      if (_inputTypes[i] == '%') {
        final maxPercent = limitPercent * 100;
        if (inputValue > maxPercent) {
          if (context != null && mounted) {
            _showToast(context, 'Maksimal ${maxPercent.toStringAsFixed(0)}%');
            _controllers[i].text = maxPercent.round().toString();
            _controllers[i].selection = TextSelection.collapsed(
              offset: _controllers[i].text.length,
            );
            setState(() {});
          }
          return;
        } else {
          runningTotal -= (runningTotal * (inputValue / 100));
        }
      } else {
        if (inputValue > maxNominalAllowed) {
          if (context != null && mounted) {
            final maxRpStr =
                AppFormatters.currencyIdrNoSymbol(maxNominalAllowed);
            _showToast(context, 'Maksimal Rp $maxRpStr');
            _controllers[i].text = maxRpStr;
            _controllers[i].selection = TextSelection.collapsed(
              offset: _controllers[i].text.length,
            );
            setState(() {});
          }
          return;
        } else {
          runningTotal -= inputValue;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      topRadius: 20,
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diskon Tambahan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Input persentase (%) atau nominal (Rp). Batas per tingkat dari database.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ...List.generate(widget.maxLimits.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diskon ${i + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _controllers[i],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: _inputTypes[i] == '%' ? '0' : '0',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (_) => _validateAndCalculate(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_inputTypes[i] == 'Rp') {
                                    final text = _controllers[i]
                                        .text
                                        .replaceAll(',', '.');
                                    final nominal = double.tryParse(text);
                                    if (nominal != null && nominal > 0) {
                                      final base = _getRunningBaseBeforeTier(i);
                                      if (base > 0) {
                                        final percent = (nominal / base) * 100;
                                        _controllers[i].text = percent
                                            .toStringAsFixed(2)
                                            .replaceAll('.00', '');
                                      }
                                    }
                                  }
                                  _inputTypes[i] = '%';
                                  _validateAndCalculate(context);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _inputTypes[i] == '%'
                                      ? AppColors.accent
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _inputTypes[i] == '%'
                                        ? AppColors.onPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_inputTypes[i] == '%') {
                                    final text = _controllers[i]
                                        .text
                                        .replaceAll(',', '.');
                                    final percentVal = double.tryParse(text);
                                    if (percentVal != null && percentVal > 0) {
                                      final base = _getRunningBaseBeforeTier(i);
                                      final nominal = base * (percentVal / 100);
                                      _controllers[i].text =
                                          nominal.round().toString();
                                    }
                                  }
                                  _inputTypes[i] = 'Rp';
                                  _validateAndCalculate(context);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _inputTypes[i] == 'Rp'
                                      ? AppColors.accent
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Rp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _inputTypes[i] == 'Rp'
                                        ? AppColors.onPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _validateAndCalculate(context);
                  if (_errorMessages.any((msg) => msg != null)) return;

                  final finalDiscounts = <double>[];
                  double currentRunningBase = widget.baseTotalEup;

                  for (int i = 0; i < widget.maxLimits.length; i++) {
                    final text = _controllers[i].text.replaceAll(',', '.');
                    if (text.isEmpty || text == '0') continue;

                    final val = double.tryParse(text);
                    if (val == null || val <= 0) continue;

                    if (_inputTypes[i] == '%') {
                      finalDiscounts.add(val / 100);
                      currentRunningBase -= (currentRunningBase * (val / 100));
                    } else {
                      final percentEquivalent = val / currentRunningBase;
                      finalDiscounts.add(percentEquivalent);
                      currentRunningBase -= val;
                    }
                  }

                  widget.onApply(finalDiscounts);
                  widget.onClose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Terapkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
