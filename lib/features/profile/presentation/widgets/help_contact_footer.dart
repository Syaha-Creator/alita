import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/contact_actions.dart';

/// "Masih butuh bantuan?" footer with phone and WhatsApp buttons.
class HelpContactFooter extends StatelessWidget {
  const HelpContactFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF0F7FF), Color(0xFFE8F0FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.accentBorder.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.support_agent_rounded,
              size: 36,
              color: AppColors.accent,
            ),
            const SizedBox(height: 10),
            const Text(
              'Masih butuh bantuan?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hubungi admin IT untuk kendala teknis',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ContactButton(
                    icon: Icons.phone_rounded,
                    label: 'Telepon',
                    onTap: () => ContactActions.callPhone('02154396429'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ContactButton(
                    customIcon: Image.asset(
                      'assets/logo/whatsapp-icon.png',
                      width: 18,
                      height: 18,
                      filterQuality: FilterQuality.medium,
                    ),
                    label: 'WhatsApp',
                    isPrimary: true,
                    onTap: () => ContactActions.openWhatsAppChat(
                      '6281774105440',
                      message:
                          'Halo, saya butuh bantuan terkait aplikasi Alita Pricelist.',
                    ),
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

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    this.icon,
    this.customIcon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppColors.accent : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              customIcon ??
                  Icon(
                    icon,
                    size: 18,
                    color: isPrimary ? AppColors.onPrimary : AppColors.accent,
                  ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.onPrimary : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
