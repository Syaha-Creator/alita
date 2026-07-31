import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import 'edit_order_header_fields.dart';

/// Section "Data Pelanggan": nama, telepon, email, alamat.
class EditOrderCustomerSection extends StatelessWidget {
  const EditOrderCustomerSection({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.addressCtrl,
  });

  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController addressCtrl;

  @override
  Widget build(BuildContext context) {
    return EditOrderSectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Data Pelanggan',
      children: [
        EditOrderTextField(
          label: 'Nama Pelanggan',
          controller: nameCtrl,
          prefixIcon: Icons.badge_outlined,
          required: true,
        ),
        EditOrderTextField(
          label: 'Telepon',
          controller: phoneCtrl,
          prefixIcon: Icons.phone_outlined,
          keyboard: TextInputType.phone,
          required: false,
        ),
        EditOrderTextField(
          label: 'Email',
          controller: emailCtrl,
          prefixIcon: Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
          required: false,
        ),
        EditOrderTextField(
          label: 'Alamat Pelanggan',
          controller: addressCtrl,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
          required: false,
        ),
      ],
    );
  }
}

/// Section "Pengiriman": nama/alamat penerima, tanggal kirim, no. PO, ongkir.
class EditOrderShippingSection extends StatelessWidget {
  const EditOrderShippingSection({
    super.key,
    required this.shipToNameCtrl,
    required this.addressShipToCtrl,
    required this.noPoCtrl,
    required this.postageCtrl,
    required this.requestDate,
    required this.onPickDate,
    required this.dateFieldEnabled,
  });

  final TextEditingController shipToNameCtrl;
  final TextEditingController addressShipToCtrl;
  final TextEditingController noPoCtrl;
  final TextEditingController postageCtrl;
  final DateTime? requestDate;
  final VoidCallback onPickDate;
  final bool dateFieldEnabled;

  @override
  Widget build(BuildContext context) {
    return EditOrderSectionCard(
      icon: Icons.local_shipping_outlined,
      title: 'Pengiriman',
      children: [
        EditOrderTextField(
          label: 'Nama Penerima',
          controller: shipToNameCtrl,
          prefixIcon: Icons.person_pin_outlined,
          required: false,
        ),
        EditOrderTextField(
          label: 'Alamat Pengiriman',
          controller: addressShipToCtrl,
          prefixIcon: Icons.place_outlined,
          maxLines: 2,
          required: false,
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: EditOrderDateField(
                requestDate: requestDate,
                onTap: onPickDate,
                enabled: dateFieldEnabled,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: EditOrderTextField(
                label: 'No. PO',
                controller: noPoCtrl,
                prefixIcon: Icons.tag_rounded,
                required: false,
              ),
            ),
          ],
        ),
        EditOrderPostageField(controller: postageCtrl),
      ],
    );
  }
}

/// Section "Keterangan": SC code + catatan tambahan.
class EditOrderNoteSection extends StatelessWidget {
  const EditOrderNoteSection({
    super.key,
    required this.salesCodeCtrl,
    required this.noteCtrl,
  });

  final TextEditingController salesCodeCtrl;
  final TextEditingController noteCtrl;

  @override
  Widget build(BuildContext context) {
    return EditOrderSectionCard(
      icon: Icons.notes_rounded,
      title: 'Keterangan',
      children: [
        EditOrderTextField(
          label: 'SC Code',
          controller: salesCodeCtrl,
          prefixIcon: Icons.qr_code_rounded,
          keyboard: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          required: false,
        ),
        EditOrderTextField(
          label: 'Catatan tambahan (opsional)',
          controller: noteCtrl,
          prefixIcon: Icons.sticky_note_2_outlined,
          maxLines: 3,
          required: false,
        ),
      ],
    );
  }
}

/// Handle bar + header strip (judul, no. SP, tombol tutup) untuk
/// [EditOrderHeaderSheet].
class EditOrderHeaderSheetTopBar extends StatelessWidget {
  const EditOrderHeaderSheetTopBar({
    super.key,
    required this.noSp,
    required this.onClose,
  });

  final String noSp;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
          decoration: const BoxDecoration(color: AppColors.background),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Surat Pesanan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    noSp,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.textSecondary),
                tooltip: 'Tutup',
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Banner peringatan bahwa approval akan direset ke pending.
class EditOrderResetApprovalBanner extends StatelessWidget {
  const EditOrderResetApprovalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.restart_alt_rounded, color: AppColors.warning, size: 17),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Approval yang sudah masuk akan direset ke pending. '
              'Atasan perlu menyetujui kembali setelah perubahan disimpan.',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol footer "Simpan Perubahan" dengan state loading.
class EditOrderHeaderSheetFooterButton extends StatelessWidget {
  const EditOrderHeaderSheetFooterButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border:
            const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: isSubmitting ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSubmitting) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 10),
              ] else ...[
                const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                isSubmitting ? 'Menyimpan…' : 'Simpan Perubahan',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
