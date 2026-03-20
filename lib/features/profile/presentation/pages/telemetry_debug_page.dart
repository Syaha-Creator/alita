import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Internal page for admin to understand telemetry coverage quickly.
class TelemetryDebugPage extends StatelessWidget {
  const TelemetryDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    const events = <String>[
      'checkout_submit_started',
      'checkout_prep_completed',
      'checkout_step1_header_ok',
      'checkout_step2_contacts_ok',
      'checkout_step3_payments_ok',
      'checkout_step4_details_done',
      'checkout_step5_discounts_done',
      'checkout_submit_success',
      'checkout_submit_partial_failure',
      'checkout_submit_exception',
      'checkout_retry_success',
      'checkout_retry_partial_failure',
      'checkout_retry_exception',
      'checkout_receipt_selected',
      'checkout_receipt_pick_failed',
      'checkout_payment_upload_ok',
      'checkout_payment_upload_failed',
      'checkout_long_list_frame',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Telemetry Debug'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'Halaman internal admin. Event telemetry dikirim otomatis ke '
              'Crashlytics pada release build. Data sensitif (nama, email, '
              'telepon, alamat, token) disamarkan.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...events.map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
