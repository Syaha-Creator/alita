import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/api_session_expired.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../checkout/data/models/approver_model.dart';
import '../../../checkout/data/models/store_model.dart';
import '../../../checkout/data/services/approval_service.dart';
import '../../../checkout/logic/store_provider.dart';
import '../../../checkout/presentation/widgets/searchable_dropdown_field.dart';
import '../../../profile/logic/profile_provider.dart';
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

  DateTime? _requestDate;
  bool _isSubmitting = false;

  // Indirect-only: toggle receiver mode.
  // false = Customer Baru (fields bebas), true = Cabang/Gudang (store picker).
  bool _isReceiverBranchMode = false;
  StoreModel? _selectedReceiverStore;
  final TextEditingController _storeSearchCtrl = TextEditingController();

  // ASM picker untuk Customer Baru (indirect only).
  List<Approver> _approvers = [];
  bool _isLoadingApprovers = false;
  Approver? _selectedAsm;

  bool get _isIndirectOrder =>
      (widget.order.channel?.trim().toUpperCase() ?? '') == 'SO';

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

    // Indirect: pre-load ASM list saat sheet dibuka supaya langsung siap
    // ketika user memilih mode "Customer Baru".
    if (_isIndirectOrder) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadApprovers());
    }
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
    _storeSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApprovers() async {
    if (_approvers.isNotEmpty) return;
    if (!_isLoadingApprovers) setState(() => _isLoadingApprovers = true);
    try {
      final profile = await ref.read(profileProvider.future);
      if (profile == null) return;
      final data = await ApprovalService()
          .getApprovers(profile.companyId, profile.areaId);
      data.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      if (mounted) setState(() => _approvers = data);
    } catch (_) {
      // Biarkan list kosong — user bisa retry dengan tap ulang.
    } finally {
      if (mounted) setState(() => _isLoadingApprovers = false);
    }
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
    // Indirect + Customer Baru: ASM wajib dipilih.
    if (_isIndirectOrder && !_isReceiverBranchMode && _selectedAsm == null) {
      AppFeedback.show(
        context,
        message: 'Pilih ASM terlebih dahulu untuk pengiriman ke customer baru.',
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
        // Empty/null akan dikonversi service jadi `null` di payload — supaya
        // user bisa menghapus PO / SC yang sebelumnya sudah ada.
        noPo: _noPoCtrl.text,
        salesCode: _salesCodeCtrl.text,
        note: _noteCtrl.text,
      );

      await _service.editAndReset(
        order: widget.order,
        headerPayload: payload,
        token: token,
      );

      // Indirect + Customer Baru: POST discount row ASM baru ke tiap detail.
      if (_isIndirectOrder && !_isReceiverBranchMode && _selectedAsm != null) {
        await _service.postAsmDiscountRows(
          order: widget.order,
          asm: _selectedAsm!,
          token: token,
        );
      }

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
                          // ── Toggle receiver mode (indirect only) ─────────
                          if (_isIndirectOrder) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tipe Penerima',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SegmentedToggle(
                                    height: 40,
                                    borderRadius: 10,
                                    leftLabel: 'Cabang / Gudang',
                                    rightLabel: 'Customer Baru',
                                    leftIcon: Icons.store_outlined,
                                    rightIcon: Icons.person_outline,
                                    isLeftSelected: _isReceiverBranchMode,
                                    onTapLeft: () => setState(() {
                                      _isReceiverBranchMode = true;
                                      _selectedReceiverStore = null;
                                      _selectedAsm = null;
                                      _shipToNameCtrl.clear();
                                      _addressShipToCtrl.clear();
                                    }),
                                    onTapRight: () {
                                      setState(() {
                                        _isReceiverBranchMode = false;
                                        _selectedReceiverStore = null;
                                        _shipToNameCtrl.clear();
                                        _addressShipToCtrl.clear();
                                        // Set loading sekarang supaya tidak ada
                                        // flash tombol "Muat daftar ASM".
                                        if (_approvers.isEmpty) {
                                          _isLoadingApprovers = true;
                                        }
                                      });
                                      _loadApprovers();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // ── Cabang/Gudang: store picker ───────────────────
                          if (_isIndirectOrder && _isReceiverBranchMode) ...[
                            _buildStorePicker(),
                          ] else ...[
                            // Customer Baru (atau direct): field bebas
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
                            // Warning + ASM picker: Customer Baru indirect
                            if (_isIndirectOrder) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.person_outline,
                                          size: 14, color: AppColors.accent),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Pengiriman ke customer baru — '
                                          'pilih ASM yang akan menyetujui.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.accent,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Dropdown ASM
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildAsmDropdown(),
                              ),
                            ],
                          ],

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

  Widget _buildAsmDropdown() {
    if (_isLoadingApprovers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_approvers.isEmpty) {
      return TextButton.icon(
        onPressed: _loadApprovers,
        icon: const Icon(Icons.refresh_rounded, size: 14),
        label: const Text('Muat daftar ASM', style: TextStyle(fontSize: 13)),
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      );
    }
    return SearchableDropdownField<Approver>(
      label: 'Area Sales Manager (ASM)',
      hint: 'Pilih ASM',
      selectedValue: _selectedAsm,
      items: _approvers,
      itemAsString: (a) => a.displayLabel,
      onChanged: (v) => setState(() => _selectedAsm = v),
    );
  }

  Widget _buildStorePicker() {
    final storesAsync = ref.watch(storeListProvider);
    final stores = storesAsync.valueOrNull ?? [];

    // Filter berdasarkan query pencarian.
    final query = _storeSearchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? stores
        : stores.where((s) {
            final label = s.displayLabelOrFallback.toLowerCase();
            final addr = s.address.toLowerCase();
            return label.contains(query) || addr.contains(query);
          }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _storeSearchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari toko / cabang…',
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 17, color: AppColors.textTertiary),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 0),
              suffixIcon: storesAsync.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child:
                            CircularProgressIndicator.adaptive(strokeWidth: 2),
                      ),
                    )
                  : null,
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
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          if (filtered.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 0, thickness: 0.5),
                itemBuilder: (_, i) {
                  final store = filtered[i];
                  final isSelected = _selectedReceiverStore?.id == store.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedReceiverStore = store;
                        _shipToNameCtrl.text =
                            AppFormatters.titleCase(store.name.trim());
                        _addressShipToCtrl.text = store.address.trim();
                        _storeSearchCtrl.clear();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.displayLabelOrFallback,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.accent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                if (store.address.isNotEmpty)
                                  Text(
                                    store.address,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded,
                                size: 16, color: AppColors.accent),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          // Tampilkan nama+alamat yang sudah dipilih
          if (_selectedReceiverStore != null &&
              _storeSearchCtrl.text.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store_outlined,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppFormatters.titleCase(
                              _selectedReceiverStore!.name.trim()),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_selectedReceiverStore!.address.isNotEmpty)
                          Text(
                            _selectedReceiverStore!.address,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
