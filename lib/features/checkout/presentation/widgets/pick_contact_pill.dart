import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pill-shaped action button that opens the server-side contact book
/// (`ContactPickerBottomSheet` / `/address_books`).
///
/// Shared between [CustomerInfoSection] (pelanggan/toko) and
/// [ShippingInfoSection] (penerima Customer Baru) — extracted here instead of
/// duplicated in both, per reusable-widget policy.
///
/// Kept feature-local (not `core/widgets/`) because the copy ("Pilih Kontak")
/// and icon are specific to the checkout contact-picking flow, not a
/// general-purpose pattern.
class PickContactPill extends StatelessWidget {
  const PickContactPill({
    super.key,
    required this.onTap,
    this.label = 'Pilih Kontak',
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.contacts_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
