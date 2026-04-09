import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'detail_contact_info_line.dart';
import 'detail_contact_phone_row.dart';
import 'detail_section_label.dart';

/// Reusable shipping information card for detail pages.
class DetailShippingInfoCard extends StatelessWidget {
  final String title;
  final String name;
  final String address;
  final List<String> phones;
  final void Function(String phone)? onCopyPhone;
  final void Function(String phone)? onCallPhone;
  final void Function(String phone)? onOpenWhatsApp;

  const DetailShippingInfoCard({
    super.key,
    this.title = 'Informasi Pengiriman',
    required this.name,
    required this.address,
    this.phones = const [],
    this.onCopyPhone,
    this.onCallPhone,
    this.onOpenWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = name.isNotEmpty && name != '-';
    final hasPhone = phones.any(
      (p) {
        final t = p.trim();
        return t.isNotEmpty && t != '-';
      },
    );
    final hasAddress = address.isNotEmpty && address != '-';

    return Semantics(
      container: true,
      label: 'Info pengiriman',
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.accentLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasName)
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      if (hasName && !hasPhone && hasAddress)
                        const SizedBox(height: 8),
                      DetailContactPhoneRow(
                        phones: phones,
                        onCopyPhone: onCopyPhone,
                        onCallPhone: onCallPhone,
                        onOpenWhatsApp: onOpenWhatsApp,
                      ),
                      if (hasPhone && hasAddress) const SizedBox(height: 12),
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
