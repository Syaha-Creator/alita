import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_formatters.dart';
import '../utils/number_input_formatter.dart';
import 'app_dropdown_field.dart';
import 'checkout_input_decoration.dart';
import 'date_picker_field_tile.dart';
import 'form_field_label.dart';
import 'receipt_upload_field.dart';
import 'segmented_toggle.dart';

/// Reusable payment form content used in checkout and add-payment flows.
class PaymentFormContent extends StatelessWidget {
  final Widget? topBanner;
  final bool showModeToggle;
  final String leftModeLabel;
  final String rightModeLabel;
  final bool isLeftModeSelected;
  final VoidCallback? onTapLeftMode;
  final VoidCallback? onTapRightMode;

  final String amountLabel;
  final TextEditingController amountController;
  final bool amountReadOnly;
  final ValueChanged<String>? onAmountChanged;
  final String amountHintText;
  final bool amountFilled;
  final Widget? amountSuffixIcon;
  final BorderSide? amountFocusedBorderSide;
  final TextStyle? amountStyle;
  final TextStyle? amountPrefixStyle;
  final String? Function(String?)? amountValidator;
  final Widget? amountStatusWidget;

  final List<String> paymentMethods;
  final String? paymentMethod;
  final String? paymentChannel;
  final TextEditingController customChannelController;
  final Map<String, List<String>> paymentChannelsMap;
  final ValueChanged<String?> onPaymentMethodChanged;
  final ValueChanged<String?> onPaymentChannelChanged;
  final bool requireMethod;
  final bool requireChannel;
  final String methodLabel;
  final String channelLabel;
  final String methodHintText;
  final String channelHintText;

  final String referenceLabel;
  final TextEditingController referenceController;
  final String referenceHintText;
  final String dateLabel;
  final DateTime paymentDate;
  final VoidCallback onPickDate;
  final bool inlineReferenceAndDate;

  final bool showPaymentNote;
  final String paymentNoteLabel;
  final TextEditingController? paymentNoteController;

  final String receiptLabel;
  final File? receiptImage;
  final VoidCallback onPickOrEditReceipt;
  final VoidCallback onRemoveReceipt;
  final bool requireReceipt;
  final String receiptRequiredMessage;

  const PaymentFormContent({
    super.key,
    this.topBanner,
    this.showModeToggle = true,
    this.leftModeLabel = 'Lunas',
    this.rightModeLabel = 'Down Payment (DP)',
    required this.isLeftModeSelected,
    this.onTapLeftMode,
    this.onTapRightMode,
    required this.amountLabel,
    required this.amountController,
    this.amountReadOnly = false,
    this.onAmountChanged,
    this.amountHintText = '0',
    this.amountFilled = false,
    this.amountSuffixIcon,
    this.amountFocusedBorderSide,
    this.amountStyle,
    this.amountPrefixStyle,
    this.amountValidator,
    this.amountStatusWidget,
    required this.paymentMethods,
    required this.paymentMethod,
    required this.paymentChannel,
    required this.customChannelController,
    required this.paymentChannelsMap,
    required this.onPaymentMethodChanged,
    required this.onPaymentChannelChanged,
    this.requireMethod = true,
    this.requireChannel = true,
    this.methodLabel = 'Metode Pembayaran *',
    this.channelLabel = 'Bank / Channel *',
    this.methodHintText = 'Pilih Metode',
    this.channelHintText = 'Pilih Channel',
    this.referenceLabel = 'No Referensi',
    required this.referenceController,
    this.referenceHintText = 'Opsional',
    this.dateLabel = 'Tanggal Pembayaran *',
    required this.paymentDate,
    required this.onPickDate,
    this.inlineReferenceAndDate = false,
    this.showPaymentNote = false,
    this.paymentNoteLabel = 'Catatan Pembayaran',
    this.paymentNoteController,
    this.receiptLabel = 'Bukti Pembayaran (Struk / Transfer) *',
    required this.receiptImage,
    required this.onPickOrEditReceipt,
    required this.onRemoveReceipt,
    this.requireReceipt = true,
    this.receiptRequiredMessage = 'Bukti transfer wajib diupload',
  });

  InputDecoration _inputDecoration({
    String? prefixText,
    Widget? suffixIcon,
    bool? filled,
    Color? fillColor,
    EdgeInsets? contentPadding,
    BorderSide? focusedBorderSide,
    BorderSide? enabledBorderSide,
  }) {
    return CheckoutInputDecoration.form(
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      filled: filled ?? true,
      fillColor: fillColor ?? AppColors.surfaceLight,
      contentPadding:
          contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      focusedBorderSide: focusedBorderSide ??
          const BorderSide(
            color: AppColors.accent,
            width: 1.5,
          ),
      enabledBorderSide:
          enabledBorderSide ?? const BorderSide(color: AppColors.border),
    );
  }


  Widget _buildModeToggle() {
    return SegmentedToggle(
      leftLabel: leftModeLabel,
      rightLabel: rightModeLabel,
      isLeftSelected: isLeftModeSelected,
      onTapLeft: onTapLeftMode,
      onTapRight: onTapRightMode,
    );
  }

  Widget _buildMethodAndChannel(BuildContext context) {
    final channels = paymentChannelsMap[paymentMethod] ?? const <String>[];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormFieldLabel(methodLabel),
              const SizedBox(height: 8),
              AppDropdownField<String>(
                value: paymentMethod,
                hintText: methodHintText,
                items: paymentMethods,
                labelBuilder: (e) => e,
                decoration: _inputDecoration(),
                onChanged: onPaymentMethodChanged,
                validator: requireMethod
                    ? (v) => (v == null || v.isEmpty) ? 'Pilih metode' : null
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormFieldLabel(channelLabel),
              const SizedBox(height: 8),
              if (paymentMethod == 'Lainnya')
                TextFormField(
                  controller: customChannelController,
                  decoration: _inputDecoration().copyWith(
                    hintText: 'Ketik nama bank / channel',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  validator: requireChannel
                      ? (v) =>
                          (v == null || v.trim().isEmpty) ? 'Isi channel' : null
                      : null,
                )
              else
                AppDropdownField<String>(
                  value: paymentChannel,
                  hintText: channelHintText,
                  items: channels,
                  labelBuilder: (e) => e,
                  decoration: _inputDecoration(),
                  onChanged: onPaymentChannelChanged,
                  validator: requireChannel
                      ? (v) {
                          if (paymentMethod == null) return 'Pilih metode';
                          if (channels.isEmpty) return null;
                          return (v == null || v.isEmpty) ? 'Pilih bank' : null;
                        }
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceAndDate(BuildContext context) {
    final dateText = AppFormatters.shortDateId(
      AppFormatters.apiDate(paymentDate),
    );

    final dateWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(dateLabel),
        const SizedBox(height: 8),
        DatePickerFieldTile(
          text: dateText,
          onTap: onPickDate,
          placeholder: 'Pilih Tanggal',
          icon: Icons.calendar_today_outlined,
          iconSize: 18,
          textStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );

    if (!inlineReferenceAndDate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(referenceLabel),
          const SizedBox(height: 8),
          TextFormField(
            controller: referenceController,
            decoration: _inputDecoration().copyWith(
              hintText: referenceHintText,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          dateWidget,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormFieldLabel(referenceLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: referenceController,
                decoration: _inputDecoration().copyWith(
                  hintText: referenceHintText,
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: dateWidget),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Form pembayaran',
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topBanner case final b?) ...[
          b,
          const SizedBox(height: 16),
        ],
        if (showModeToggle) ...[
          _buildModeToggle(),
          const SizedBox(height: 16),
        ],
        FormFieldLabel(amountLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: amountController,
          readOnly: amountReadOnly,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: onAmountChanged,
          validator: amountValidator,
          style: amountStyle ??
              TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: amountReadOnly ? AppColors.textPrimary : AppColors.textPrimary,
              ),
          decoration: _inputDecoration(
            prefixText: 'Rp ',
            suffixIcon: amountSuffixIcon,
            filled: amountFilled,
            fillColor: AppColors.surfaceLight,
            focusedBorderSide: amountFocusedBorderSide,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ).copyWith(
            hintText: amountHintText,
            prefixStyle: amountPrefixStyle ??
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
            isDense: true,
          ),
        ),
        if (amountStatusWidget case final w?) ...[
          const SizedBox(height: 6),
          w,
        ],
        const SizedBox(height: 16),
        _buildMethodAndChannel(context),
        const SizedBox(height: 16),
        _buildReferenceAndDate(context),
        if (showPaymentNote && paymentNoteController != null) ...[
          const SizedBox(height: 16),
          FormFieldLabel(paymentNoteLabel),
          const SizedBox(height: 8),
          TextFormField(
            controller: paymentNoteController,
            maxLines: 2,
            decoration: _inputDecoration(),
          ),
        ],
        const SizedBox(height: 16),
        FormFieldLabel(receiptLabel),
        const SizedBox(height: 8),
        FormField<File>(
          validator: (_) {
            if (!requireReceipt) return null;
            return receiptImage == null ? receiptRequiredMessage : null;
          },
          builder: (formState) => ReceiptUploadField(
            imageFile: receiptImage,
            hasError: formState.hasError,
            errorText: formState.errorText,
            onPickOrEdit: onPickOrEditReceipt,
            onRemove: onRemoveReceipt,
          ),
        ),
      ],
    ),
    );
  }
}
