import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'detail_contact_info_line.dart';
import 'detail_contact_phone_row.dart';
import 'detail_section_label.dart';

/// Reusable customer/contact information card for detail pages.
class DetailContactInfoCard extends StatelessWidget {
  final String title;
  final String name;
  final List<String> phones;
  final String email;
  final String address;
  final void Function(String phone)? onCopyPhone;
  final void Function(String phone)? onOpenWhatsApp;
  final void Function(String phone)? onCallPhone;

  const DetailContactInfoCard({
    super.key,
    required this.title,
    required this.name,
    required this.phones,
    required this.email,
    required this.address,
    this.onCopyPhone,
    this.onOpenWhatsApp,
    this.onCallPhone,
  });

  @override
  Widget build(BuildContext context) {
    final hasEmail = email.isNotEmpty && email != '-';
    final hasAddress = address.isNotEmpty && address != '-';
    final hasPhone = phones.any((p) {
      final t = p.trim();
      return t.isNotEmpty && t != '-';
    });

    return Semantics(
      container: true,
      label: 'Info kontak',
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailSectionLabel(title: title),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accentLight,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!hasPhone && hasEmail) const SizedBox(height: 8),
                    DetailContactPhoneRow(
                      phones: phones,
                      onCopyPhone: hasPhone ? onCopyPhone : null,
                      onCallPhone: hasPhone ? onCallPhone : null,
                      onOpenWhatsApp: hasPhone ? onOpenWhatsApp : null,
                    ),
                    if (hasPhone && (hasEmail || hasAddress))
                      const SizedBox(height: 12),
                    if (hasEmail) ...[
                      DetailContactInfoLine(
                        icon: Icons.email_outlined,
                        text: email,
                        maxLines: 3,
                        crossAxisAlignment: CrossAxisAlignment.center,
                      ),
                      if (hasAddress) const SizedBox(height: 6),
                    ],
                    if (hasAddress)
                      DetailContactInfoLine(
                        icon: Icons.location_on_outlined,
                        text: address,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
