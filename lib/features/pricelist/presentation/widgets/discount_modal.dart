import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/action_button_bar.dart';
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
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: DiscountModalContent(
        maxLimits: maxLimits,
        baseTotalEup: baseTotalEup,
        currentDiscounts: currentDiscounts,
        onApply: onApply,
        onClose: () => Navigator.of(ctx).pop(),
      ),
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

  void _onApplyPressed(BuildContext context) {
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
  }

  @override
  Widget build(BuildContext context) {
    final fieldRadius = BorderRadius.circular(AppLayoutTokens.radius10);
    final viewInset = MediaQuery.viewInsetsOf(context).bottom;
    final noneBorder = OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide.none,
    );

    void dismissKeyboard() {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    return SheetScaffold(
      topRadius: 20,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: GestureDetector(
        onTap: dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Diskon Tambahan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: AppLayoutTokens.space8),
              Text(
                'Input persentase (%) atau nominal (Rp). Batas per tingkat dari database.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: AppLayoutTokens.space20),
              ...List.generate(widget.maxLimits.length, (i) {
                return Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diskon ${i + 1}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: AppLayoutTokens.space8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _controllers[i],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onTapOutside: (PointerDownEvent event) {
                                dismissKeyboard();
                              },
                              scrollPadding: EdgeInsets.only(
                                bottom: viewInset + 120,
                                top: AppLayoutTokens.space20,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: AppColors.textTertiary.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                                isDense: true,
                                border: noneBorder,
                                enabledBorder: noneBorder,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: fieldRadius,
                                  borderSide: const BorderSide(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (_) => _validateAndCalculate(context),
                            ),
                          ),
                          const SizedBox(width: AppLayoutTokens.space10),
                          _DiscountModeSegmentedControl(
                            isPercent: _inputTypes[i] == '%',
                            onSelectPercent: () {
                              setState(() {
                                if (_inputTypes[i] == 'Rp') {
                                  final text =
                                      _controllers[i].text.replaceAll(',', '.');
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
                            onSelectRp: () {
                              setState(() {
                                if (_inputTypes[i] == '%') {
                                  final text =
                                      _controllers[i].text.replaceAll(',', '.');
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
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: AppLayoutTokens.space8),
              ActionButtonBar(
                height: 48,
                borderRadius: 12,
                primaryLabel: 'Terapkan',
                primaryBackgroundColor: AppColors.accent,
                primaryForegroundColor: AppColors.onPrimary,
                primaryLabelStyle: const TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                onPrimaryPressed: () => _onApplyPressed(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const double _kDiscountSegmentRadius = 8;

/// Segmented control gaya native: track lembut, segmen aktif putih + bayangan tipis.
class _DiscountModeSegmentedControl extends StatelessWidget {
  const _DiscountModeSegmentedControl({
    required this.isPercent,
    required this.onSelectPercent,
    required this.onSelectRp,
  });

  final bool isPercent;
  final VoidCallback onSelectPercent;
  final VoidCallback onSelectRp;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SegmentChip(
                label: '%',
                selected: isPercent,
                onTap: onSelectPercent,
              ),
            ),
            Expanded(
              child: _SegmentChip(
                label: 'Rp',
                selected: !isPercent,
                onTap: onSelectRp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kDiscountSegmentRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.transparent,
            borderRadius: BorderRadius.circular(_kDiscountSegmentRadius),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowSubtle,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
