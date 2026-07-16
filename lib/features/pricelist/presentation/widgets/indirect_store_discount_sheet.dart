import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/store_discount_calculator.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/sheet_scaffold.dart';

/// Bottom sheet untuk menambah/mengubah/menghapus tier **Diskon Toko** sebelum
/// item masuk keranjang (mode indirect, halaman detail produk).
void showIndirectStoreDiscountSheet(
  BuildContext context, {
  required List<double> currentDiscounts,
  required List<double> defaultDiscounts,
  required ValueChanged<List<double>> onApply,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _IndirectStoreDiscountSheetBody(
        initialDiscounts: currentDiscounts,
        defaultDiscounts: defaultDiscounts,
        onApply: (discounts) {
          onApply(discounts);
          Navigator.of(ctx).pop();
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

class _IndirectStoreDiscountSheetBody extends StatefulWidget {
  const _IndirectStoreDiscountSheetBody({
    required this.initialDiscounts,
    required this.defaultDiscounts,
    required this.onApply,
    required this.onClose,
  });

  final List<double> initialDiscounts;
  final List<double> defaultDiscounts;
  final ValueChanged<List<double>> onApply;
  final VoidCallback onClose;

  @override
  State<_IndirectStoreDiscountSheetBody> createState() =>
      _IndirectStoreDiscountSheetBodyState();
}

class _IndirectStoreDiscountSheetBodyState
    extends State<_IndirectStoreDiscountSheetBody> {
  static const _maxTiers = 7;

  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _buildControllers(widget.initialDiscounts);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> _buildControllers(List<double> discounts) {
    final seeds = discounts.isEmpty ? <double>[0] : discounts;
    return seeds
        .map((d) => TextEditingController(text: _formatPercent(d)))
        .toList();
  }

  String _formatPercent(double value) {
    if (value <= 0) return '';
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString().replaceAll('.', ',');
  }

  double? _parsePercent(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null || v <= 0) return null;
    return v.clamp(0, 100);
  }

  List<double> _collectDiscounts() {
    final out = <double>[];
    for (final c in _controllers) {
      final v = _parsePercent(c.text);
      if (v != null && v > 0) out.add(v);
    }
    return out;
  }

  void _addTier() {
    if (_controllers.length >= _maxTiers) return;
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeTier(int index) {
    if (_controllers.length <= 1) {
      _controllers.first.clear();
      setState(() {});
      return;
    }
    setState(() {
      _controllers.removeAt(index).dispose();
    });
  }

  void _resetToDefault() {
    for (final c in _controllers) {
      c.dispose();
    }
    setState(() {
      _controllers = _buildControllers(widget.defaultDiscounts);
    });
  }

  void _apply() {
    widget.onApply(_collectDiscounts());
  }

  @override
  Widget build(BuildContext context) {
    final preview = StoreDiscountCalculator.formatDisplay(_collectDiscounts());
    final canReset = widget.defaultDiscounts.isNotEmpty;

    return SheetScaffold(
      topRadius: 20,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Diskon Toko',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppLayoutTokens.space8),
            Text(
              'Atur tier diskon toko untuk item ini. Kosongkan atau hapus tier '
              'jika tidak ingin menerapkan diskon.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: AppLayoutTokens.space12),
            if (canReset)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _resetToDefault,
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Reset ke default toko'),
                ),
              ),
            ...List.generate(_controllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppLayoutTokens.space10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        'Tier ${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controllers[i],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,3}([.,]\d{0,2})?$'),
                          ),
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: '0',
                          suffixText: '%',
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppLayoutTokens.radius8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppLayoutTokens.space12,
                            vertical: AppLayoutTokens.space10,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus tier',
                      onPressed: () => _removeTier(i),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (_controllers.length < _maxTiers)
              TextButton.icon(
                onPressed: _addTier,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah tier'),
              ),
            const SizedBox(height: AppLayoutTokens.space8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppLayoutTokens.space12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
              ),
              child: Text(
                preview == '-' ? 'Tidak ada diskon toko' : preview,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: AppLayoutTokens.space16),
            ActionButtonBar(
              height: 48,
              borderRadius: 12,
              primaryLabel: 'Simpan',
              onPrimaryPressed: _apply,
              secondaryLabel: 'Batal',
              onSecondaryPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}
