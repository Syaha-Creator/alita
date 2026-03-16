import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/form_field_label.dart';

/// Reusable payment method/channel inputs for checkout form.
class PaymentMethodChannelSection extends StatelessWidget {
  final String? paymentMethod;
  final String? paymentBank;
  final TextEditingController otherChannelController;
  final Map<String, List<String>> paymentChannelsMap;
  final ValueChanged<String?> onPaymentMethodChanged;
  final ValueChanged<String?> onPaymentBankChanged;

  const PaymentMethodChannelSection({
    super.key,
    required this.paymentMethod,
    required this.paymentBank,
    required this.otherChannelController,
    required this.paymentChannelsMap,
    required this.onPaymentMethodChanged,
    required this.onPaymentBankChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormFieldLabel('Metode *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                hint: const Text(
                  'Pilih Metode',
                  style: TextStyle(fontSize: 12),
                ),
                isExpanded: true,
                decoration: CheckoutInputDecoration.dropdown(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  isDense: true,
                  filled: false,
                ),
                items: paymentChannelsMap.keys
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(
                          key,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    value == null ? 'Metode wajib dipilih' : null,
                onChanged: onPaymentMethodChanged,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormFieldLabel('Channel *'),
              const SizedBox(height: 8),
              if (paymentMethod == 'Lainnya')
                TextField(
                  controller: otherChannelController,
                  textInputAction: TextInputAction.next,
                  decoration: CheckoutInputDecoration.form(
                    hintText: 'Ketik nama bank / channel',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                    focusedBorderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                    fillColor: Colors.grey.shade50,
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: paymentBank,
                  hint: const Text(
                    'Pilih Channel',
                    style: TextStyle(fontSize: 12),
                  ),
                  isExpanded: true,
                  decoration: CheckoutInputDecoration.dropdown(
                    enabledBorderSide: BorderSide(
                      color: paymentMethod == null
                          ? const Color(0xFFEEEEEE)
                          : const Color(0xFFE0E0E0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                    filled: paymentMethod == null,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                  items: (paymentChannelsMap[paymentMethod] ?? [])
                      .map(
                        (ch) => DropdownMenuItem(
                          value: ch,
                          child: Text(
                            ch,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  validator: paymentMethod == null || paymentMethod == 'Lainnya'
                      ? null
                      : (value) => value == null ? 'Channel wajib dipilih' : null,
                  onChanged: paymentMethod == null ? null : onPaymentBankChanged,
                ),
            ],
          ),
        ),
      ],
    );
  }

}
