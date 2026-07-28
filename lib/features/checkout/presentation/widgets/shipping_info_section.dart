import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../data/models/store_model.dart';

/// Shipping address section extracted from CheckoutPage.
///
/// Includes the "Kirim ke alamat pelanggan" toggle, the address/region
/// fields for customer, and the optional receiver (dropship) sub-form.
class ShippingInfoSection extends StatelessWidget {
  const ShippingInfoSection({
    super.key,
    this.sectionTitle = 'Alamat & Pengiriman',
    this.sameAsCustomerLabel = 'Kirim ke alamat pelanggan di atas',
    this.receiverBlockTitle = 'Informasi Penerima (Dropship / Lokasi Lain)',
    this.useStoreAddressLabels = false,

    /// Indirect: nama & no. HP penerima/gudang opsional (format dicek jika diisi).
    this.receiverContactOptional = false,

    /// Indirect: sembunyikan pemilih wilayah toko; cukup detail alamat.
    this.hideCustomerRegionPicker = false,

    /// Indirect + alamat beda: email penerima (opsional).
    this.showIndirectAlternateReceiverEmail = false,
    this.shippingEmailCtrl,
    this.showIndirectSaveReceiverContact = false,
    this.isFromContactBook = false,
    this.shouldSaveReceiverContact = true,
    required this.onToggleSaveReceiverContact,
    required this.customerAddressCtrl,
    required this.regionCtrl,
    required this.isShippingSameAsCustomer,
    required this.onToggleSameAddress,
    required this.onPickCustomerRegion,
    // Receiver fields
    required this.shippingNameCtrl,
    required this.shippingPhoneCtrl,
    required this.shippingPhone2Ctrl,
    required this.showReceiverBackupPhone,
    required this.onToggleReceiverBackupPhone,
    required this.shippingAddressCtrl,
    required this.shippingRegionCtrl,
    required this.onPickShippingRegion,
    this.isReceiverBranchMode = true,
    this.onToggleReceiverBranchMode,
    this.availableStores = const [],
    this.selectedReceiverStore,
    this.onReceiverStorePicked,
    this.onPickReceiverContact,
    this.isFromReceiverContactBook = false,
    this.onRefreshStores,
    this.isRefreshingStores = false,
  });

  final String sectionTitle;
  final String sameAsCustomerLabel;
  final String receiverBlockTitle;
  final bool useStoreAddressLabels;
  final bool hideCustomerRegionPicker;
  final bool receiverContactOptional;
  final bool showIndirectAlternateReceiverEmail;
  final TextEditingController? shippingEmailCtrl;
  final bool showIndirectSaveReceiverContact;
  final bool isFromContactBook;
  final bool shouldSaveReceiverContact;
  final ValueChanged<bool> onToggleSaveReceiverContact;

  final TextEditingController customerAddressCtrl;
  final TextEditingController regionCtrl;
  final bool isShippingSameAsCustomer;
  final ValueChanged<bool> onToggleSameAddress;
  final VoidCallback onPickCustomerRegion;

  final TextEditingController shippingNameCtrl;
  final TextEditingController shippingPhoneCtrl;
  final TextEditingController shippingPhone2Ctrl;
  final bool showReceiverBackupPhone;
  final VoidCallback onToggleReceiverBackupPhone;
  final TextEditingController shippingAddressCtrl;
  final TextEditingController shippingRegionCtrl;
  final VoidCallback onPickShippingRegion;

  /// Indirect only: mode toggle untuk penerima.
  /// true = cabang/gudang (pilih dari store list); false = customer baru (form bebas).
  final bool isReceiverBranchMode;
  final ValueChanged<bool>? onToggleReceiverBranchMode;
  final List<StoreModel> availableStores;
  final StoreModel? selectedReceiverStore;
  final ValueChanged<StoreModel>? onReceiverStorePicked;

  /// Customer Baru mode: callback untuk pilih kontak dari buku kontak.
  final VoidCallback? onPickReceiverContact;

  /// True jika penerima sudah dipilih dari buku kontak (sembunyikan simpan kontak).
  final bool isFromReceiverContactBook;

  /// Refresh daftar toko (all stores API).
  final VoidCallback? onRefreshStores;
  final bool isRefreshingStores;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32, color: AppColors.border),
        Text(
          sectionTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (!hideCustomerRegionPicker) ...[
          FormFieldLabel(
            useStoreAddressLabels ? 'Wilayah Toko' : 'Wilayah Pelanggan',
          ),
          const SizedBox(height: 8),
          _buildRegionSelector(
            controller: regionCtrl,
            label: 'Provinsi, Kota/Kab, Kecamatan *',
            onTap: onPickCustomerRegion,
          ),
          const SizedBox(height: 16),
        ],
        FormFieldLabel(
          useStoreAddressLabels
              ? 'Detail Alamat Toko'
              : 'Detail Alamat Pelanggan',
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: customerAddressCtrl,
          label: 'Detail Alamat (Nama Jalan, Blok, RT/RW, Patokan) *',
          maxLines: 2,
          alignLabelWithHint: true,
          isRequired: true,
        ),

        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox.adaptive(
                value: isShippingSameAsCustomer,
                onChanged: (v) => onToggleSameAddress(v ?? true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sameAsCustomerLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        // Receiver sub-form
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isShippingSameAsCustomer
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      receiverBlockTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    // Mode toggle: hanya tampil untuk indirect (onToggleReceiverBranchMode != null)
                    if (onToggleReceiverBranchMode != null) ...[
                      const SizedBox(height: 12),
                      _ReceiverModeToggle(
                        isBranchMode: isReceiverBranchMode,
                        onToggle: onToggleReceiverBranchMode!,
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Branch mode: store picker
                    if (onToggleReceiverBranchMode != null &&
                        isReceiverBranchMode) ...[
                      _StorePicker(
                        stores: availableStores,
                        selected: selectedReceiverStore,
                        onPicked: onReceiverStorePicked,
                        onRefresh: onRefreshStores,
                        isRefreshing: isRefreshingStores,
                      ),
                      if (selectedReceiverStore != null) ...[
                        const SizedBox(height: 12),
                        _StoreReceiverSummary(store: selectedReceiverStore!),
                      ],
                      const SizedBox(height: 8),
                    ] else ...[
                      // Customer baru / non-indirect: form bebas
                      // Tombol pilih dari kontak (hanya untuk indirect customer baru)
                      if (onPickReceiverContact != null) ...[
                        OutlinedButton.icon(
                          onPressed: onPickReceiverContact,
                          icon: const Icon(Icons.contacts_outlined, size: 16),
                          label: const Text('Pilih dari Kontak',
                              style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                            side: const BorderSide(color: AppColors.border),
                            foregroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildTextField(
                        controller: shippingNameCtrl,
                        label: receiverContactOptional
                            ? 'Nama Penerima'
                            : 'Nama Penerima *',
                        isRequired: !receiverContactOptional,
                      ),
                      const SizedBox(height: 16),
                      _buildReceiverPhoneRow(),
                      if (showIndirectAlternateReceiverEmail &&
                          shippingEmailCtrl != null) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: shippingEmailCtrl!,
                          label: 'Email penerima',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final t = value?.trim() ?? '';
                            if (t.isEmpty) return null;
                            if (!RegExp(r'^[\w.+-]+@[\w.-]+\.\w{2,}$')
                                .hasMatch(t)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildRegionSelector(
                        controller: shippingRegionCtrl,
                        label: 'Provinsi, Kota/Kab, Kecamatan Penerima *',
                        onTap: onPickShippingRegion,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: shippingAddressCtrl,
                        label:
                            'Detail Alamat Penerima (Jalan, Blok, Patokan) *',
                        maxLines: 2,
                        alignLabelWithHint: true,
                        isRequired: true,
                      ),
                      // Simpan kontak penerima — hanya di mode Customer Baru
                      if (showIndirectSaveReceiverContact &&
                          !isFromReceiverContactBook) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox.adaptive(
                                value: shouldSaveReceiverContact,
                                onChanged: (v) =>
                                    onToggleSaveReceiverContact(v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Simpan kontak penerima ke buku kontak',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  /// HP penerima utama + tambah / HP kedua (layout sama seperti blok pelanggan).
  Widget _buildReceiverPhoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: shippingPhoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14),
            validator: receiverContactOptional
                ? (value) {
                    final t = value?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final digits = t.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10 || digits.length > 15) {
                      return 'No. HP harus 10–15 digit';
                    }
                    return null;
                  }
                : (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Field ini wajib diisi';
                    }
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10 || digits.length > 15) {
                      return 'No. HP harus 10–15 digit';
                    }
                    return null;
                  },
            decoration: CheckoutInputDecoration.form(
              labelText:
                  receiverContactOptional ? 'No. HP Utama' : 'No. HP Utama *',
              labelStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(
                Icons.phone,
                size: 16,
                color: AppColors.textTertiary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (!showReceiverBackupPhone) ...[
          const SizedBox(width: AppLayoutTokens.space8),
          SizedBox(
            height: 44,
            width: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppLayoutTokens.radius8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add, color: AppColors.accent),
                tooltip: 'Tambah No. Kedua',
                onPressed: onToggleReceiverBackupPhone,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(width: AppLayoutTokens.space8),
          Expanded(
            child: TextField(
              controller: shippingPhone2Ctrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 14),
              decoration: CheckoutInputDecoration.form(
                labelText: 'No. HP Kedua',
                labelStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(
                  Icons.phone_android,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegionSelector({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: controller,
          decoration: CheckoutInputDecoration.form(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13),
            hintText: 'Pilih Wilayah',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            fillColor: AppColors.surfaceLight,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool alignLabelWithHint = false,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    final resolvedKeyboardType = keyboardType ??
        (maxLines > 1 ? TextInputType.multiline : TextInputType.text);
    final resolvedInputAction =
        maxLines > 1 ? TextInputAction.newline : TextInputAction.next;

    final effectiveValidator = validator ??
        (isRequired
            ? (String? value) => (value == null || value.trim().isEmpty)
                ? 'Field ini wajib diisi'
                : null
            : null);

    return TextFormField(
      controller: controller,
      keyboardType: resolvedKeyboardType,
      textInputAction: resolvedInputAction,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      validator: effectiveValidator,
      decoration: CheckoutInputDecoration.form(
        labelText: label,
        alignLabelWithHint: alignLabelWithHint,
        labelStyle: const TextStyle(fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: maxLines == 1,
      ),
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────

/// Toggle antara mode "Cabang/Gudang Lain" dan "Customer Baru".
class _ReceiverModeToggle extends StatelessWidget {
  const _ReceiverModeToggle({
    required this.isBranchMode,
    required this.onToggle,
  });

  final bool isBranchMode;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return SegmentedToggle(
      height: 40,
      borderRadius: AppLayoutTokens.radius10,
      leftLabel: 'Cabang / Gudang',
      rightLabel: 'Customer Baru',
      leftIcon: Icons.store_outlined,
      rightIcon: Icons.person_outline,
      isLeftSelected: isBranchMode,
      onTapLeft: () => onToggle(true),
      onTapRight: () => onToggle(false),
    );
  }
}

/// Dropdown pencarian toko dari daftar `availableStores` + tombol refresh.
class _StorePicker extends StatefulWidget {
  const _StorePicker({
    required this.stores,
    required this.selected,
    required this.onPicked,
    this.onRefresh,
    this.isRefreshing = false,
  });

  final List<StoreModel> stores;
  final StoreModel? selected;
  final ValueChanged<StoreModel>? onPicked;
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  @override
  State<_StorePicker> createState() => _StorePickerState();
}

class _StorePickerState extends State<_StorePicker> {
  final _searchCtrl = TextEditingController();
  List<StoreModel> _filtered = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.stores;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void didUpdateWidget(_StorePicker old) {
    super.didUpdateWidget(old);
    if (old.stores != widget.stores) {
      _filtered = _applyFilter(_searchCtrl.text);
    }
  }

  void _onSearch() {
    setState(() => _filtered = _applyFilter(_searchCtrl.text));
  }

  List<StoreModel> _applyFilter(String q) {
    if (q.trim().isEmpty) return widget.stores;
    final lower = q.toLowerCase();
    return widget.stores
        .where((s) =>
            s.name.toLowerCase().contains(lower) ||
            s.city.toLowerCase().contains(lower) ||
            s.area.toLowerCase().contains(lower) ||
            s.address.toLowerCase().contains(lower))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final hasSelected = selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trigger field — mirip form field lain di checkout
        GestureDetector(
          onTap: () => setState(() => _showDropdown = !_showDropdown),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showDropdown
                    ? AppColors.accent
                    : (hasSelected ? AppColors.accentBorder : AppColors.border),
                width: _showDropdown ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 16,
                  color:
                      hasSelected ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasSelected
                        ? selected.displayLabelOrFallback
                        : 'Cari & pilih toko / cabang...',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasSelected
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                if (widget.isRefreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppColors.accent),
                  )
                else
                  Icon(
                    _showDropdown
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _showDropdown
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),

        // Dropdown panel
        if (_showDropdown) ...[
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search + refresh row
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari nama, kota, area...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: AppColors.textTertiary),
                            prefixIcon: const Icon(Icons.search_rounded,
                                size: 16, color: AppColors.accent),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 9),
                            filled: true,
                            fillColor: AppColors.accentLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.accentBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.accentBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.accent, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      if (widget.onRefresh != null)
                        Tooltip(
                          message: 'Perbarui daftar toko',
                          child: IconButton(
                            icon: widget.isRefreshing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppColors.accent),
                                  )
                                : const Icon(Icons.refresh_rounded,
                                    size: 18, color: AppColors.accent),
                            onPressed:
                                widget.isRefreshing ? null : widget.onRefresh,
                            splashRadius: 20,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: widget.stores.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.store_outlined,
                                  size: 28,
                                  color:
                                      AppColors.accent.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              const Text(
                                'Daftar toko belum termuat.\nTekan refresh untuk memuat.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : _filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded,
                                      size: 28,
                                      color: AppColors.accent
                                          .withValues(alpha: 0.4)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Toko tidak ditemukan.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final store = _filtered[i];
                                final isSelected = store.id == selected?.id;
                                return InkWell(
                                  onTap: () {
                                    widget.onPicked?.call(store);
                                    setState(() {
                                      _showDropdown = false;
                                      _searchCtrl.clear();
                                      _filtered = widget.stores;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.accentLight
                                          : null,
                                      border: isSelected
                                          ? const Border(
                                              left: BorderSide(
                                                  color: AppColors.accent,
                                                  width: 3))
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                              if (store
                                                  .displayLocLine.isNotEmpty)
                                                Text(
                                                  store.displayLocLine,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded,
                                              size: 16,
                                              color: AppColors.accent),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Ringkasan read-only dari toko yang dipilih sebagai penerima.
class _StoreReceiverSummary extends StatelessWidget {
  const _StoreReceiverSummary({required this.store});

  final StoreModel store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
              icon: Icons.store_outlined,
              label: 'Nama',
              value: store.displayLabelOrFallback),
          if (store.phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.phone_outlined,
                label: 'No. HP',
                value: store.phone),
          ],
          if (store.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Alamat',
                value: store.address),
          ],
          if (store.displayLocLine.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.map_outlined,
                label: 'Kota',
                value: store.displayLocLine),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
