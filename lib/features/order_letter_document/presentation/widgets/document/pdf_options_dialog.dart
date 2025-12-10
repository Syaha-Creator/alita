import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';

/// Dialog untuk memilih jenis PDF yang akan di-generate
class PDFOptionsDialog extends StatelessWidget {
  final void Function(bool showApprovalColumn) onOptionSelected;

  const PDFOptionsDialog({
    super.key,
    required this.onOptionSelected,
  });

  /// Show the dialog and return the result
  static Future<void> show(
    BuildContext context, {
    required void Function(bool showApprovalColumn) onOptionSelected,
  }) {
    return showDialog(
      context: context,
      builder: (context) =>
          PDFOptionsDialog(onOptionSelected: onOptionSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Jenis PDF'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.person, color: AppColors.accentLight), // 10% - Accent
            title: const Text('PDF Customer'),
            subtitle: const Text('PDF untuk customer (tanpa kolom approval)'),
            onTap: () {
              Navigator.of(context).pop();
              onOptionSelected(false);
            },
          ),
          ListTile(
            leading: Icon(Icons.approval, color: AppColors.success), // Status color
            title: const Text('PDF Approval'),
            subtitle: const Text('PDF dengan kolom approval dan stempel'),
            onTap: () {
              Navigator.of(context).pop();
              onOptionSelected(true);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
