import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/number_input_formatter.dart';

/// Kartu collapsible untuk input diskon Program Bulanan (indirect only).
///
/// User memilih tipe (% atau Rp) via suffix chip di dalam text field,
/// lalu mengetik nilai. Saat nilai berubah, [onChanged] dipanggil.
/// Saat kartu dikosongkan/ditutup tanpa nilai, [onChanged] dipanggil
/// dengan type='' dan value=0.
class ProgramBulananCard extends StatefulWidget {
  /// Tipe aktif: '' | 'percent' | 'nominal'. Dikelola oleh parent.
  final String type;

  /// Nilai aktif yang disimpan di parent (% atau Rp tergantung [type]).
  final double value;

  /// Dipanggil saat type/value berubah.
  final void Function(String type, double value) onChanged;

  const ProgramBulananCard({
    super.key,
    required this.type,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ProgramBulananCard> createState() => _ProgramBulananCardState();
}

class _ProgramBulananCardState extends State<ProgramBulananCard> {
  bool _expanded = false;

  /// Tipe sementara saat card sedang expanded (sebelum dikonfirmasi).
  late String _draftType;
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _draftType = widget.type.isEmpty ? 'percent' : widget.type;
    _syncController();
  }

  @override
  void didUpdateWidget(ProgramBulananCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type || oldWidget.value != widget.value) {
      if (!_focusNode.hasFocus) {
        if (widget.type.isNotEmpty) {
          _draftType = widget.type;
        }
        _syncController();
      }
    }
  }

  void _syncController() {
    final v = widget.value;
    if (v <= 0) {
      _ctrl.text = '';
      return;
    }
    if (widget.type == 'nominal') {
      _ctrl.text = _formatNominal(v);
    } else {
      _ctrl.text = _formatPercent(v);
    }
  }

  String _formatNominal(double v) {
    if (v <= 0) return '';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => '.',
        );
  }

  String _formatPercent(double v) {
    if (v <= 0) return '';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString();
  }

  double _parseInput(String text) {
    final clean = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean) ?? 0.0;
  }

  bool get _hasValue => widget.type.isNotEmpty && widget.value > 0;

  void _toggleType() {
    setState(() {
      _draftType = _draftType == 'percent' ? 'nominal' : 'percent';
      _ctrl.clear();
    });
    widget.onChanged('', 0);
    _focusNode.requestFocus();
  }

  void _onFieldChanged(String text) {
    final v = _parseInput(text);
    widget.onChanged(v > 0 ? _draftType : '', v);
  }

  void _clear() {
    _ctrl.clear();
    widget.onChanged('', 0);
    setState(() => _expanded = false);
  }

  List<TextInputFormatter> get _formatters {
    if (_draftType == 'nominal') {
      return [
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorInputFormatter(),
      ];
    }
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _hasValue
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
        border: Border.all(
          color: _hasValue
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.accent.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          if (_expanded) _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayoutTokens.space12,
          vertical: AppLayoutTokens.space10,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color:
                  _hasValue ? AppColors.success : AppColors.accent,
            ),
            const SizedBox(width: AppLayoutTokens.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Program Bulanan',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _hasValue
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                  ),
                  if (_hasValue) ...[
                    const SizedBox(height: 2),
                    Text(
                      _summaryLabel(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ] else
                    Text(
                      'Ketuk untuk isi diskon program',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                ],
              ),
            ),
            if (_hasValue)
              GestureDetector(
                onTap: _clear,
                child: const Padding(
                  padding: EdgeInsets.only(right: AppLayoutTokens.space4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayoutTokens.space12,
        0,
        AppLayoutTokens.space12,
        AppLayoutTokens.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppLayoutTokens.space10),
          Text(
            'Nilai Diskon',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppLayoutTokens.space6),
          TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _formatters,
            onChanged: _onFieldChanged,
            decoration: InputDecoration(
              hintText: _draftType == 'percent'
                  ? 'Contoh: 5'
                  : 'Contoh: 50.000',
              hintStyle: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppLayoutTokens.space12,
                vertical: AppLayoutTokens.space10,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppLayoutTokens.radius8),
                borderSide:
                    BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppLayoutTokens.radius8),
                borderSide:
                    BorderSide(color: AppColors.accent.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppLayoutTokens.radius8),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              suffixIcon: _buildSuffixToggle(context),
            ),
          ),
          if (_hasValue) ...[
            const SizedBox(height: AppLayoutTokens.space8),
            _buildSavingsPreview(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSuffixToggle(BuildContext context) {
    return GestureDetector(
      onTap: _toggleType,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius8),
        ),
        child: Text(
          _draftType == 'percent' ? '%' : 'Rp',
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsPreview(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 14, color: AppColors.success),
        const SizedBox(width: AppLayoutTokens.space4),
        Text(
          'Diskon program: ${_summaryLabel()} (auto-approve)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  String _summaryLabel() {
    if (widget.type == 'percent') {
      return '${_formatPercent(widget.value)}%';
    }
    if (widget.type == 'nominal') {
      return AppFormatters.currencyIdr(widget.value);
    }
    return '';
  }
}
