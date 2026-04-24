import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/api_session_expired.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/models/order_history.dart';
import '../../data/services/edit_order_header_service.dart';

/// Bottom sheet untuk mengedit field header [order_letters].
///
/// Hanya mengubah: nama pelanggan, telepon, alamat, email, nama/alamat
/// pengiriman, tanggal kirim, no. PO, dan keterangan.
///
/// Setelah submit berhasil, **semua baris approval direset ke pending** dan
/// status SP kembali ke `pending`. [onSuccess] dipanggil agar halaman
/// pemanggil melakukan refresh.
class EditOrderHeaderSheet extends StatefulWidget {
  const EditOrderHeaderSheet({
    super.key,
    required this.order,
    required this.editorName,
    required this.onSuccess,
  });

  final OrderHistory order;

  /// Nama editor (dari profileProvider) — dikirim ke notifikasi approval ulang.
  final String editorName;
  final VoidCallback onSuccess;

  static Future<void> show(
    BuildContext context, {
    required OrderHistory order,
    required String editorName,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => EditOrderHeaderSheet(
        order: order,
        editorName: editorName,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<EditOrderHeaderSheet> createState() => _EditOrderHeaderSheetState();
}

class _EditOrderHeaderSheetState extends State<EditOrderHeaderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = EditOrderHeaderService();

  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _shipToNameCtrl;
  late final TextEditingController _addressShipToCtrl;
  late final TextEditingController _noPoCtrl;
  late final TextEditingController _salesCodeCtrl;
  late final TextEditingController _noteCtrl;

  DateTime? _requestDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _customerNameCtrl = TextEditingController(text: o.customerName);
    _phoneCtrl = TextEditingController(text: o.phone == '-' ? '' : o.phone);
    _addressCtrl =
        TextEditingController(text: o.address == '-' ? '' : o.address);
    _emailCtrl = TextEditingController(text: o.email);
    _shipToNameCtrl = TextEditingController(text: o.shipToName);
    _addressShipToCtrl = TextEditingController(text: o.addressShipTo);
    _noPoCtrl = TextEditingController(text: o.noPo ?? '');
    _salesCodeCtrl = TextEditingController(text: o.salesCode);
    _noteCtrl = TextEditingController(text: o.note == '-' ? '' : o.note);
    // Coba parse requestDate; fallback ke hari ini jika tidak valid atau "-".
    _requestDate = (o.requestDate.isEmpty || o.requestDate == '-')
        ? DateTime.now()
        : DateTime.tryParse(o.requestDate) ?? DateTime.now();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _shipToNameCtrl.dispose();
    _addressShipToCtrl.dispose();
    _noPoCtrl.dispose();
    _salesCodeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _requestDate ?? now;
    // firstDate harus <= initialDate; izinkan past date untuk order yang
    // sudah ada (tanggal kirim bisa sudah lewat).
    final first = initial.isBefore(now)
        ? initial.subtract(const Duration(days: 30))
        : now;
    final picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Tanggal Kirim',
    );
    if (picked != null) setState(() => _requestDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_requestDate == null) {
      AppFeedback.show(
        context,
        message: 'Tanggal kirim belum dipilih.',
        type: AppFeedbackType.warning,
        floating: true,
      );
      return;
    }

    final hasApprovals =
        EditOrderHeaderService.collectDiscountIds(widget.order).isNotEmpty;

    if (hasApprovals) {
      final confirm = await showAdaptiveConfirm(
        context: context,
        title: 'Reset Semua Persetujuan?',
        content: 'Perubahan ini akan mereset semua approval ke pending.\n'
            'Atasan perlu menyetujui kembali dari awal.',
        confirmLabel: 'Ya, Simpan',
        confirmColor: AppColors.accent,
      );
      if (confirm != true || !mounted) return;
    }

    setState(() => _isSubmitting = true);
    if (!mounted) return;
    LoadingOverlay.show(
      context,
      title: 'Menyimpan perubahan…',
      subtitle: 'Mohon tunggu',
    );

    try {
      final token = await StorageService.loadAccessToken();
      final payload = EditOrderHeaderService.buildHeaderPayload(
        customerName: _customerNameCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
        email: _emailCtrl.text,
        shipToName: _shipToNameCtrl.text,
        addressShipTo: _addressShipToCtrl.text,
        requestDate: AppFormatters.apiDate(_requestDate!),
        noPo: _noPoCtrl.text.trim().isEmpty ? null : _noPoCtrl.text.trim(),
        salesCode: _salesCodeCtrl.text.trim().isEmpty
            ? null
            : _salesCodeCtrl.text.trim(),
        note: _noteCtrl.text,
      );

      await _service.editAndReset(
        order: widget.order,
        headerPayload: payload,
        token: token,
      );

      // Notifikasi ke approver pertama (SPV/ASM) — fire-and-forget,
      // tidak boleh block UI atau gagalkan proses utama.
      unawaited(
        EditOrderHeaderService.triggerReEditNotification(
          order: widget.order,
          token: token,
          editorName: widget.editorName,
        ),
      );

      if (!mounted) return;
      LoadingOverlay.dismiss(context);
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
      widget.onSuccess();
      AppFeedback.show(
        context,
        message: 'Surat Pesanan berhasil diperbarui.',
        type: AppFeedbackType.success,
        floating: true,
      );
    } catch (e) {
      if (!mounted) return;
      LoadingOverlay.dismiss(context);
      setState(() => _isSubmitting = false);
      if (e is ApiSessionExpiredException) {
        AppFeedback.show(
          context,
          message: e.toString(),
          type: AppFeedbackType.warning,
          floating: true,
          duration: const Duration(seconds: 5),
        );
        return;
      }
      AppFeedback.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppFeedbackType.error,
        floating: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final hasApprovals =
        EditOrderHeaderService.collectDiscountIds(widget.order).isNotEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.88,
      ),
      child: Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
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

          // ── Header strip ──────────────────────────────────────────
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
                      widget.order.noSp,
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
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Form — scrollable ─────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Data Pelanggan
                    _buildSectionCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Data Pelanggan',
                      children: [
                        _buildField(
                          label: 'Nama Pelanggan',
                          controller: _customerNameCtrl,
                          prefixIcon: Icons.badge_outlined,
                          required: true,
                        ),
                        _buildField(
                          label: 'Telepon',
                          controller: _phoneCtrl,
                          prefixIcon: Icons.phone_outlined,
                          keyboard: TextInputType.phone,
                        ),
                        _buildField(
                          label: 'Email',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_outlined,
                          keyboard: TextInputType.emailAddress,
                        ),
                        _buildField(
                          label: 'Alamat Pelanggan',
                          controller: _addressCtrl,
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 2,
                          required: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Section: Pengiriman
                    _buildSectionCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'Pengiriman',
                      children: [
                        _buildField(
                          label: 'Nama Penerima',
                          controller: _shipToNameCtrl,
                          prefixIcon: Icons.person_pin_outlined,
                          required: false,
                        ),
                        _buildField(
                          label: 'Alamat Pengiriman',
                          controller: _addressShipToCtrl,
                          prefixIcon: Icons.place_outlined,
                          maxLines: 2,
                          required: false,
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildDateField(),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: _buildField(
                                label: 'No. PO',
                                controller: _noPoCtrl,
                                prefixIcon: Icons.tag_rounded,
                                required: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Section: Keterangan
                    _buildSectionCard(
                      icon: Icons.notes_rounded,
                      title: 'Keterangan',
                      children: [
                        _buildField(
                          label: 'SC Code',
                          controller: _salesCodeCtrl,
                          prefixIcon: Icons.qr_code_rounded,
                          keyboard: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          required: false,
                        ),
                        _buildField(
                          label: 'Catatan tambahan (opsional)',
                          controller: _noteCtrl,
                          prefixIcon: Icons.sticky_note_2_outlined,
                          maxLines: 3,
                          required: false,
                        ),
                      ],
                    ),

                    // Banner reset approval
                    if (hasApprovals) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warningBorder),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.restart_alt_rounded,
                                color: AppColors.warning, size: 17),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Approval yang sudah masuk akan direset ke pending. '
                                'Atasan perlu menyetujui kembali setelah perubahan disimpan.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // ── Footer tombol ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1)),
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
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSubmitting) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                    ] else ...[
                      const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isSubmitting ? 'Menyimpan…' : 'Simpan Perubahan',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ), // Container
    ); // ConstrainedBox
  }

  // ── Widgets ──────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
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
          // Fields
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
            borderSide:
                const BorderSide(color: AppColors.accent, width: 1.5),
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
            ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
            : null,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _isSubmitting ? null : _pickDate,
        child: AbsorbPointer(
          child: TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Tanggal Kirim',
              labelStyle: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
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
            controller: TextEditingController(
              text: _requestDate != null
                  ? DateFormat('dd MMM yyyy', 'id_ID').format(_requestDate!)
                  : '',
            ),
            validator: (_) =>
                _requestDate == null ? 'Tanggal kirim wajib dipilih' : null,
          ),
        ),
      ),
    );
  }
}
