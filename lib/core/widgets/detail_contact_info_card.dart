import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'detail_section_header.dart';

/// Reusable customer/contact information card for detail pages.
class DetailContactInfoCard extends StatelessWidget {
  final String title;
  final String name;
  final String phone;
  final String email;
  final String address;
  final VoidCallback? onCopyPhone;
  final VoidCallback? onOpenWhatsApp;
  final VoidCallback? onCallPhone;

  const DetailContactInfoCard({
    super.key,
    required this.title,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.onCopyPhone,
    this.onOpenWhatsApp,
    this.onCallPhone,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone.isNotEmpty && phone != '-';
    final hasEmail = email.isNotEmpty && email != '-';
    final hasAddress = address.isNotEmpty && address != '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailSectionHeader(title: title, icon: Icons.person_outline),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.pink.shade50,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    if (hasPhone) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_android_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            phone,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (onCopyPhone != null)
                            _ActionIcon(
                              tooltip: 'Salin nomor',
                              onTap: onCopyPhone!,
                              icon: Icons.copy_rounded,
                              backgroundColor: Colors.grey.shade100,
                              iconColor: Colors.grey.shade700,
                            ),
                          if (onCallPhone != null) ...[
                            const SizedBox(width: 4),
                            _ActionIcon(
                              tooltip: 'Telepon',
                              onTap: onCallPhone!,
                              icon: Icons.phone_outlined,
                              backgroundColor: Colors.blue.shade50,
                              iconColor: Colors.blue.shade700,
                              borderColor: Colors.blue.shade200,
                            ),
                          ],
                          if (onOpenWhatsApp != null) ...[
                            const SizedBox(width: 4),
                            _ActionIcon(
                              tooltip: 'Chat WhatsApp',
                              onTap: onOpenWhatsApp!,
                              icon: Icons.chat_bubble_outline,
                              backgroundColor: Colors.green.shade50,
                              iconColor: Colors.green.shade700,
                              borderColor: Colors.green.shade200,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (hasEmail) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (hasAddress)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.tooltip,
    required this.onTap,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.borderColor,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
      ),
    );
  }
}
