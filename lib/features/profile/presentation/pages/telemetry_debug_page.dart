import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Internal page for admin to understand telemetry coverage quickly.
class TelemetryDebugPage extends StatelessWidget {
  const TelemetryDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    const events = <(String, List<String>)>[
      ('Login', [
        'login_attempted',
        'login_success',
        'login_failed',
        'login_validation_failed',
        'login_offline_blocked',
        'logout',
      ]),
      ('Approval', [
        'approval_inbox_loaded',
        'approval_inbox_failed',
        'approval_inbox_auth',
        'approval_decision_started',
        'approval_location_resolved',
        'approval_location_failed',
        'approval_session_expired',
        'approval_decision_success',
        'approval_decision_failed',
        'approval_notification_sent',
        'approval_notification_failed',
      ]),
      ('Checkout', [
        'checkout_missing_workplace',
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
      ]),
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
          const SizedBox(height: 16),
          for (final (section, items) in events) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text(
                section,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            ...items.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      e.contains('failed') || e.contains('exception')
                          ? Icons.error_outline_rounded
                          : Icons.bolt_rounded,
                      size: 16,
                      color: e.contains('failed') || e.contains('exception')
                          ? AppColors.error
                          : AppColors.accent,
                    ),
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
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
