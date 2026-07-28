import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_session_expired.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/models/order_history.dart';
import '../../data/services/edit_order_header_service.dart';
import 'edit_order_header_sections.dart';

/// Bottom sheet untuk mengedit field header [order_letters].
///
/// Hanya mengubah: nama pelanggan, telepon, alamat, email, nama/alamat
/// pengiriman, tanggal kirim, no. PO, ongkir, dan keterangan. Berlaku sama
/// untuk order direct maupun indirect (SO) — harga/diskon per item tidak
/// tersentuh sama sekali oleh sheet ini.
///
/// **Direct:** reset semua baris approval L2+ ke pending + notifikasi approver.
/// **Indirect (SO):** header saja — status tetap Approved, tidak reset approval.
class EditOrderHeaderSheet extends ConsumerStatefulWidget {
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
  ConsumerState<EditOrderHeaderSheet> createState() =>
      _EditOrderHeaderSheetState();
}

class _EditOrderHeaderSheetState extends ConsumerState<EditOrderHeaderSheet> {
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
  late final TextEditingController _postageCtrl;

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
    _postageCtrl = TextEditingController(
      text: o.postage > 0 ? o.postage.toInt().toString() : '',
    );
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
    _postageCtrl.dispose();
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
    if (picked != null && mounted) setState(() => _requestDate = picked);
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
    final isIndirect = EditOrderHeaderService.isIndirectOrder(widget.order);
    final hasApprovals = !isIndirect &&
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
      final postageRaw =
          _postageCtrl.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
      final postage = postageRaw.isEmpty
          ? 0.0
          : (double.tryParse(postageRaw) ?? 0.0);
      // `extended_amount` = subtotal item + ongkir. Server tidak menghitung
      // ulang otomatis, jadi harus di-recompute & dikirim setiap ongkir
      // diedit — subtotal dihitung dari detail item langsung (net_price *
      // qty), bukan `totalAmount - postage` yang rawan salah kalau data lama
      // sudah korup/tidak sinkron.
      final itemsSubtotal =
          EditOrderHeaderService.computeItemsSubtotal(widget.order);
      final extendedAmount = itemsSubtotal + postage;
      final hargaAwal = EditOrderHeaderService.computeHargaAwal(widget.order);
      final payload = EditOrderHeaderService.buildHeaderPayload(
        customerName: _customerNameCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
        email: _emailCtrl.text,
        shipToName: _shipToNameCtrl.text,
        addressShipTo: _addressShipToCtrl.text,
        requestDate: AppFormatters.apiDate(_requestDate!),
        // Empty/null akan dikonversi service jadi `null` di payload — supaya
        // user bisa menghapus PO / SC yang sebelumnya sudah ada.
        noPo: _noPoCtrl.text,
        salesCode: _salesCodeCtrl.text,
        note: _noteCtrl.text,
        postage: postage,
        extendedAmount: extendedAmount,
        hargaAwal: hargaAwal,
        status: isIndirect ? 'Approved' : 'Pending',
      );

      await _service.editAndReset(
        order: widget.order,
        headerPayload: payload,
        token: token,
        resetApprovals: !isIndirect,
      );

      if (!isIndirect) {
        // Notifikasi ke approver pertama (SPV/ASM) — fire-and-forget,
        // tidak boleh block UI atau gagalkan proses utama.
        unawaited(
          EditOrderHeaderService.triggerReEditNotification(
            order: widget.order,
            token: token,
            editorName: widget.editorName,
          ),
        );
      }

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
    } catch (e, st) {
      if (!mounted) return;
      LoadingOverlay.dismiss(context);
      setState(() => _isSubmitting = false);
      if (e is ApiSessionExpiredException) {
        Log.warning(
          'Edit order header session expired: ${e.detail}',
          tag: 'EditOrderHeader',
        );
        AppFeedback.show(
          context,
          message: e.toString(),
          type: AppFeedbackType.warning,
          floating: true,
          duration: const Duration(seconds: 5),
        );
        return;
      }
      Log.error(e, st, reason: 'EditOrderHeader._submit');
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
    final isIndirect = EditOrderHeaderService.isIndirectOrder(widget.order);
    final hasApprovals = !isIndirect &&
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
            EditOrderHeaderSheetTopBar(
              noSp: widget.order.noSp,
              onClose: () => Navigator.of(context).pop(),
            ),

            // ── Form — scrollable ─────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EditOrderCustomerSection(
                        nameCtrl: _customerNameCtrl,
                        phoneCtrl: _phoneCtrl,
                        emailCtrl: _emailCtrl,
                        addressCtrl: _addressCtrl,
                      ),
                      const SizedBox(height: 12),

                      EditOrderShippingSection(
                        shipToNameCtrl: _shipToNameCtrl,
                        addressShipToCtrl: _addressShipToCtrl,
                        noPoCtrl: _noPoCtrl,
                        postageCtrl: _postageCtrl,
                        requestDate: _requestDate,
                        onPickDate: _pickDate,
                        dateFieldEnabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 12),

                      EditOrderNoteSection(
                        salesCodeCtrl: _salesCodeCtrl,
                        noteCtrl: _noteCtrl,
                      ),

                      // Banner reset approval
                      if (hasApprovals) ...[
                        const SizedBox(height: 12),
                        const EditOrderResetApprovalBanner(),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            EditOrderHeaderSheetFooterButton(
              isSubmitting: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ), // Container
    ); // ConstrainedBox
  }
}
