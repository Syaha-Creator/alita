import 'package:flutter/material.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_colors.dart';

class WhatsAppDialog extends StatelessWidget {
  final String brand;
  final String area;
  final String channel;

  const WhatsAppDialog({
    super.key,
    required this.brand,
    required this.area,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.message,
            color: AppColors.whatsapp,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Produk Tidak Tersedia',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Produk:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildSimpleInfoRow(context, 'Brand', brand),
          _buildSimpleInfoRow(context, 'Area', area),
          _buildSimpleInfoRow(context, 'Channel', channel),
          const SizedBox(height: 16),
          Text(
            'Hubungi kami melalui WhatsApp untuk informasi lebih lanjut.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              await WhatsAppService.sendMessage(
                brand: brand,
                area: area,
                channel: channel,
              );
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Gagal membuka WhatsApp. Silakan coba lagi.'),
                    backgroundColor: colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.message, size: 18),
          label: const Text('WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.whatsapp,
            foregroundColor: AppColors.surfaceLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
