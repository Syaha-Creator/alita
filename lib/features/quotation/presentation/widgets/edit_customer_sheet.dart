import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../data/quotation_model.dart';

class EditCustomerSheet extends StatefulWidget {
  const EditCustomerSheet({
    super.key,
    required this.quotation,
    required this.onSave,
  });

  final QuotationModel quotation;
  final ValueChanged<QuotationModel> onSave;

  @override
  State<EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends State<EditCustomerSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _phone2Ctrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _scCodeCtrl;
  late final TextEditingController _postageCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final q = widget.quotation;
    _nameCtrl = TextEditingController(text: q.customerName);
    _phoneCtrl = TextEditingController(text: q.customerPhone);
    _phone2Ctrl = TextEditingController(text: q.customerPhone2);
    _emailCtrl = TextEditingController(text: q.customerEmail);
    _addressCtrl = TextEditingController(text: q.customerAddress);
    _scCodeCtrl = TextEditingController(text: q.scCode);
    _postageCtrl = TextEditingController(text: q.postage);
    _notesCtrl = TextEditingController(text: q.notes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _phone2Ctrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _scCodeCtrl.dispose();
    _postageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      AppFeedback.show(context,
          message: 'Nama pelanggan wajib diisi',
          type: AppFeedbackType.warning);
      return;
    }

    final updated = widget.quotation.copyWith(
      customerName: _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      customerPhone2: _phone2Ctrl.text.trim(),
      customerEmail: _emailCtrl.text.trim(),
      customerAddress: _addressCtrl.text.trim(),
      scCode: _scCodeCtrl.text.trim(),
      postage: _postageCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded,
                      size: 20, color: AppColors.accent),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Edit Info Pelanggan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  _SheetField(
                      label: 'Nama Pelanggan *',
                      ctrl: _nameCtrl,
                      icon: Icons.person_outline),
                  _SheetField(
                      label: 'Telepon',
                      ctrl: _phoneCtrl,
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone),
                  _SheetField(
                      label: 'Telepon 2',
                      ctrl: _phone2Ctrl,
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone),
                  _SheetField(
                      label: 'Email',
                      ctrl: _emailCtrl,
                      icon: Icons.email_outlined,
                      keyboard: TextInputType.emailAddress),
                  _SheetField(
                      label: 'Alamat Detail',
                      ctrl: _addressCtrl,
                      icon: Icons.location_on_outlined,
                      maxLines: 2),
                  _SheetField(
                      label: 'SC Code',
                      ctrl: _scCodeCtrl,
                      icon: Icons.badge_outlined),
                  _SheetField(
                      label: 'Ongkos Kirim',
                      ctrl: _postageCtrl,
                      icon: Icons.local_shipping_outlined,
                      keyboard: TextInputType.number),
                  _SheetField(
                      label: 'Catatan',
                      ctrl: _notesCtrl,
                      icon: Icons.notes_outlined,
                      maxLines: 3),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Simpan Perubahan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.keyboard,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType? keyboard;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: CheckoutInputDecoration.form(
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
