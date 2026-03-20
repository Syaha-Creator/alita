import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/date_picker_field_tile.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../../core/widgets/segmented_toggle.dart';

/// Delivery information section extracted from CheckoutPage.
///
/// Contains: request date picker, delivery method toggle (Kurir Pabrik /
/// Bawa Sendiri), postage field, order notes, and SC code.
class DeliveryInfoSection extends StatelessWidget {
  const DeliveryInfoSection({
    super.key,
    required this.requestDate,
    required this.onPickRequestDate,
    required this.isTakeAway,
    required this.onTakeAwayChanged,
    required this.postageCtrl,
    required this.notesController,
    required this.scCodeCtrl,
  });

  final DateTime? requestDate;
  final VoidCallback onPickRequestDate;
  final bool isTakeAway;
  final ValueChanged<bool> onTakeAwayChanged;
  final TextEditingController postageCtrl;
  final TextEditingController notesController;
  final TextEditingController scCodeCtrl;

  static final _dateFmt = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Tanggal Permintaan Kirim
        const FormFieldLabel('Tanggal Permintaan Kirim'),
        const SizedBox(height: 8),
        FormField<DateTime>(
          validator: (_) {
            if (!isTakeAway && requestDate == null) {
              return 'Tanggal wajib dipilih';
            }
            return null;
          },
          builder: (formState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DatePickerFieldTile(
                  text: switch (requestDate) {
                    final rd? => _dateFmt.format(rd),
                    null => '',
                  },
                  hasError: formState.hasError,
                  errorText: formState.errorText,
                  onTap: () {
                    onPickRequestDate();
                    formState.didChange(requestDate);
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // 2. Metode Pengiriman
        const FormFieldLabel('Metode Pengiriman'),
        const SizedBox(height: 8),
        SegmentedToggle(
          leftLabel: 'Kurir Pabrik',
          leftIcon: Icons.local_shipping_outlined,
          rightLabel: 'Bawa Sendiri',
          rightIcon: Icons.directions_car_outlined,
          isLeftSelected: !isTakeAway,
          onTapLeft: () => onTakeAwayChanged(false),
          onTapRight: () => onTakeAwayChanged(true),
        ),

        // Ongkos Kirim (only for factory courier)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isTakeAway
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const FormFieldLabel('Ongkos Kirim (Jika Ada)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: postageCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      style: const TextStyle(fontSize: 14),
                      decoration: CheckoutInputDecoration.form(
                        prefixText: 'Rp ',
                        hintText: '0',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 12),

        // 3. Catatan Pesanan
        const FormFieldLabel('Catatan Pesanan'),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: CheckoutInputDecoration.form(
            hintText: 'Misal: Telpon sebelum kirim, masuk gang...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            isDense: false,
          ),
        ),

        const SizedBox(height: 12),

        // 4. SC Code
        const FormFieldLabel('SC Code'),
        const SizedBox(height: 8),
        TextField(
          controller: scCodeCtrl,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 14),
          decoration: CheckoutInputDecoration.form(
            hintText: 'Masukkan SC Code (Opsional)',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

