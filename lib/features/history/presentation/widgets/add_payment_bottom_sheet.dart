import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/widgets/payment_form_content.dart';

class AddPaymentBottomSheet extends StatefulWidget {
  final double remainingPayment;
  final Future<void> Function(Map<String, dynamic> payload, File receiptFile)
      onSave;

  const AddPaymentBottomSheet({
    super.key,
    required this.remainingPayment,
    required this.onSave,
  });

  @override
  State<AddPaymentBottomSheet> createState() => _AddPaymentBottomSheetState();
}

class _AddPaymentBottomSheetState extends State<AddPaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nominalCtrl = TextEditingController();
  final _customChannelCtrl = TextEditingController();
  final _paymentRefCtrl = TextEditingController();
  final _paymentNoteCtrl = TextEditingController();
  final _picker = ImagePicker();

  DateTime _paymentDate = DateTime.now();
  String? _paymentMethod;
  String? _paymentChannel;
  File? _receiptImage;
  bool _isSubmitting = false;

  static const List<String> _paymentMethods = [
    'Transfer Bank',
    'QRIS',
    'Kartu Kredit',
    'E-Wallet',
    'PayLater',
    'Cash',
    'Lainnya',
  ];

  static const Map<String, List<String>> _paymentChannelsMap = {
    'Transfer Bank': ['BCA', 'Mandiri', 'BNI', 'BRI', 'CIMB Niaga', 'Permata'],
    'QRIS': ['QRIS BCA', 'QRIS Mandiri', 'QRIS BNI', 'QRIS BRI'],
    'Kartu Kredit': ['BCA Card', 'Visa', 'Mastercard', 'JCB'],
    'E-Wallet': ['GoPay', 'OVO', 'Dana', 'ShopeePay', 'LinkAja'],
    'PayLater': ['Kredivo', 'Shopee PayLater', 'GoPay Later', 'Akulaku'],
  };

  @override
  void initState() {
    super.initState();
    _nominalCtrl.clear();
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _customChannelCtrl.dispose();
    _paymentRefCtrl.dispose();
    _paymentNoteCtrl.dispose();
    super.dispose();
  }

  double get _nominalValue {
    return double.tryParse(
          ThousandsSeparatorInputFormatter.digitsOnly(_nominalCtrl.text),
        ) ??
        0;
  }

  bool get _isOverPayment => _nominalValue > widget.remainingPayment;
  bool get _isPayLunasSelected =>
      _nominalCtrl.text.isNotEmpty && _nominalValue == widget.remainingPayment;

  bool get _canSubmit {
    final channels = _paymentChannelsMap[_paymentMethod] ?? const <String>[];
    final hasChannel = _paymentMethod == 'Lainnya'
        ? _customChannelCtrl.text.trim().isNotEmpty
        : (channels.isEmpty || (_paymentChannel?.isNotEmpty ?? false));
    return !_isSubmitting &&
        _nominalValue > 0 &&
        !_isOverPayment &&
        (_paymentMethod?.isNotEmpty ?? false) &&
        hasChannel &&
        _receiptImage != null;
  }

  Widget _buildAmountStatus() {
    final remainingAfterInput =
        (widget.remainingPayment - _nominalValue).clamp(0, double.infinity);
    if (_nominalValue > 0 && _nominalValue == widget.remainingPayment) {
      return const Text(
        'Status: LUNAS',
        style: TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (_nominalValue > 0 && _nominalValue < widget.remainingPayment) {
      return Text(
        'Sisa Tagihan Setelah Ini: ${AppFormatters.currencyIdr(remainingAfterInput)}',
        style: const TextStyle(
          color: AppColors.warning,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (_isOverPayment) {
      return const Text(
        'Nominal melebihi sisa tagihan!',
        style: TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _showReceiptSourceSheet() async {
    await ImageSourceSheet.show(
      context: context,
      title: 'Upload Bukti Pembayaran',
      onCamera: () async {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
        if (!mounted || file == null) return;
        setState(() => _receiptImage = File(file.path));
      },
      onGallery: () async {
        final file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
        if (!mounted || file == null) return;
        setState(() => _receiptImage = File(file.path));
      },
    );
  }

  Future<void> _pickPaymentDate() async {
    final picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_receiptImage == null) {
      AppFeedback.show(
        context,
        message: 'Bukti bayar wajib diupload.',
        type: AppFeedbackType.error,
        floating: true,
      );
      return;
    }
    if (_isOverPayment || _nominalValue <= 0) return;

    final nominal = _nominalValue;
    final channel = _paymentMethod == 'Lainnya'
        ? _customChannelCtrl.text.trim()
        : (_paymentChannel ?? '');
    // Sesuai CheckoutPayloadBuilder: backend expect `note`, `payment_method` Lainnya→other
    final methodForApi =
        _paymentMethod == 'Lainnya' ? 'other' : (_paymentMethod ?? '');

    setState(() => _isSubmitting = true);
    await widget.onSave(
      {
        'payment_amount': nominal,
        'payment_method': methodForApi,
        'payment_bank': channel,
        'payment_number': _paymentRefCtrl.text.trim(),
        'note': _paymentNoteCtrl.text.trim(),
        'payment_date': AppFormatters.apiDate(_paymentDate),
        'remaining_before': widget.remainingPayment,
      },
      _receiptImage!,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final insetBottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insetBottom),
      child: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Tambah Pembayaran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: PaymentFormContent(
                    topBanner: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentBorder),
                      ),
                      child: Text(
                        'Sisa Tagihan: ${AppFormatters.currencyIdr(widget.remainingPayment)}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    leftModeLabel: 'Bayar Lunas',
                    rightModeLabel: 'Nominal Lain',
                    isLeftModeSelected: _isPayLunasSelected,
                    onTapLeftMode: () {
                      setState(() {
                        _nominalCtrl.text = AppFormatters.currencyIdrNoSymbol(
                          widget.remainingPayment.round(),
                        );
                      });
                    },
                    onTapRightMode: () => setState(() => _nominalCtrl.clear()),
                    amountLabel: 'Nominal Pembayaran *',
                    amountController: _nominalCtrl,
                    amountReadOnly: false,
                    onAmountChanged: (_) => setState(() {}),
                    amountValidator: (v) {
                      final value = double.tryParse(
                            ThousandsSeparatorInputFormatter.digitsOnly(v ?? ''),
                          ) ??
                          0;
                      if (value <= 0) return 'Nominal harus lebih dari 0';
                      if (value > widget.remainingPayment) {
                        return 'Nominal melebihi sisa tagihan';
                      }
                      return null;
                    },
                    amountStatusWidget: _buildAmountStatus(),
                    paymentMethods: _paymentMethods,
                    paymentMethod: _paymentMethod,
                    paymentChannel: _paymentChannel,
                    customChannelController: _customChannelCtrl,
                    paymentChannelsMap: _paymentChannelsMap,
                    onPaymentMethodChanged: (v) => setState(() {
                      _paymentMethod = v;
                      _paymentChannel = null;
                      if (v != 'Lainnya') _customChannelCtrl.clear();
                    }),
                    onPaymentChannelChanged: (v) =>
                        setState(() => _paymentChannel = v),
                    referenceLabel: 'No Referensi',
                    referenceController: _paymentRefCtrl,
                    paymentDate: _paymentDate,
                    onPickDate: _pickPaymentDate,
                    inlineReferenceAndDate: true,
                    showPaymentNote: true,
                    paymentNoteLabel: 'Catatan Pembayaran',
                    paymentNoteController: _paymentNoteCtrl,
                    receiptImage: _receiptImage,
                    onPickOrEditReceipt: _showReceiptSourceSheet,
                    onRemoveReceipt: () => setState(() => _receiptImage = null),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.textTertiary,
                      disabledForegroundColor: AppColors.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                            ),
                          )
                        : const Text('Simpan Pembayaran'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

