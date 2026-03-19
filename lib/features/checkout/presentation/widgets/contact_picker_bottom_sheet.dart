import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable bottom sheet to pick one saved customer contact.
class ContactPickerBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;

  const ContactPickerBottomSheet({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pilih Kontak Pelanggan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: contacts.length,
              itemBuilder: (_, index) {
                final contact = contacts[index];
                final subtitle = [
                  if ((contact['phone']?.toString() ?? '').isNotEmpty)
                    contact['phone']?.toString() ?? '',
                  if ((contact['kota']?.toString() ?? '').isNotEmpty)
                    contact['kota']?.toString() ?? '',
                ].join(' • ');

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    contact['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: subtitle.isNotEmpty
                      ? Text(subtitle, style: const TextStyle(fontSize: 12))
                      : null,
                  onTap: () => Navigator.pop(context, contact),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
