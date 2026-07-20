import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_input_formatter.dart';

/// Section card wrapper (icon + title + fields) dipakai berulang di
/// [EditOrderHeaderSheet].
class EditOrderSectionCard extends StatelessWidget {
  const EditOrderSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// Text field bergaya konsisten untuk form edit informasi pesanan.
class EditOrderTextField extends StatelessWidget {
  const EditOrderTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.prefixIcon,
    this.keyboard = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.required = true,
  });

  final String label;
  final TextEditingController controller;
  final IconData prefixIcon;
  final TextInputType keyboard;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: Icon(prefixIcon, size: 17, color: AppColors.textTertiary),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 0),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
            : null,
      ),
    );
  }
}

/// Field "Ongkos Kirim" dengan formatter ribuan + prefix "Rp".
class EditOrderPostageField extends StatelessWidget {
  const EditOrderPostageField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [ThousandsSeparatorInputFormatter()],
        decoration: InputDecoration(
          labelText: 'Ongkos Kirim (opsional)',
          labelStyle:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.local_shipping_outlined,
              size: 17, color: AppColors.textTertiary),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 0),
          prefixText: 'Rp ',
          prefixStyle:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          hintText: '0',
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
    );
  }
}

/// Field "Tanggal Kirim" read-only yang membuka date picker saat ditekan.
class EditOrderDateField extends StatelessWidget {
  const EditOrderDateField({
    super.key,
    required this.requestDate,
    required this.onTap,
    required this.enabled,
  });

  final DateTime? requestDate;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AbsorbPointer(
          child: TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Tanggal Kirim',
              labelStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.event_outlined,
                  size: 17, color: AppColors.textTertiary),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 0),
              suffixIcon: const Icon(Icons.arrow_drop_down_rounded,
                  color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            // Key + initialValue: rebuild saat tanggal berubah, tanpa leak controller.
            key: ValueKey(requestDate?.millisecondsSinceEpoch ?? 0),
            initialValue: requestDate != null
                ? DateFormat('dd MMM yyyy', 'id_ID').format(requestDate!)
                : '',
            validator: (_) =>
                requestDate == null ? 'Tanggal kirim wajib dipilih' : null,
          ),
        ),
      ),
    );
  }
}
