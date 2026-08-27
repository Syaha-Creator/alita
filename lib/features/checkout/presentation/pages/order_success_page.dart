import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../data/services/paper_id_payment_service.dart';
import '../order_success_route_args.dart';

/// Order success confirmation. Direct (S1) may include Paper.id pay CTA
/// or a recreate CTA when Paper create soft-failed after SP success.
class OrderSuccessPage extends ConsumerStatefulWidget {
  const OrderSuccessPage({super.key, this.args});

  final OrderSuccessRouteArgs? args;

  @override
  ConsumerState<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends ConsumerState<OrderSuccessPage> {
  late String? _paperInvoiceUrl;
  bool _isRecreatingPaper = false;

  OrderSuccessRouteArgs? get _args => widget.args;

  @override
  void initState() {
    super.initState();
    _paperInvoiceUrl = _args?.paperInvoiceUrl;
  }

  bool get _hasPaperPay => (_paperInvoiceUrl?.trim() ?? '').isNotEmpty;

  bool get _needsPaperRetry {
    final a = _args;
    if (a == null || !a.expectPaperPayment) return false;
    return !_hasPaperPay;
  }

  Future<void> _openPaperInvoice() async {
    final raw = _paperInvoiceUrl?.trim() ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      AppFeedback.show(
        context,
        message: 'Link pembayaran Paper.id tidak valid.',
        type: AppFeedbackType.error,
        floating: true,
      );
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        AppFeedback.show(
          context,
          message: 'Tidak bisa membuka link Paper.id.',
          type: AppFeedbackType.error,
          floating: true,
        );
      }
    } on Object catch (e, s) {
      Log.error(e, s, reason: 'OrderSuccessPage.openPaperInvoice');
      if (mounted) {
        AppFeedback.show(
          context,
          message: 'Gagal membuka link Paper.id.',
          type: AppFeedbackType.error,
          floating: true,
        );
      }
    }
  }

  Future<void> _recreatePaperInvoice() async {
    final a = _args;
    if (a == null || !a.canRetryPaper || _isRecreatingPaper) return;

    setState(() => _isRecreatingPaper = true);
    try {
      final token = await StorageService.loadAccessToken();
      if (token.trim().isEmpty) {
        throw StateError('Token tidak tersedia');
      }
      var creatorId = a.paperCreatorId ?? 0;
      if (creatorId <= 0) {
        creatorId = await StorageService.loadUserId();
      }
      final paper = await PaperIdPaymentService().createPaperPayment(
        orderLetterId: a.orderLetterId!,
        noSp: a.noSp,
        paymentAmount: a.paperPaymentAmount!,
        creatorId: creatorId,
        token: token,
      );
      final url = paper.paperIdInvoiceUrl.trim();
      if (url.isEmpty) {
        throw StateError('paper_id_invoice_url kosong');
      }
      if (!mounted) return;
      setState(() {
        _paperInvoiceUrl = url;
        _isRecreatingPaper = false;
      });
      AppFeedback.show(
        context,
        message: 'Link pembayaran Paper.id berhasil dibuat.',
        type: AppFeedbackType.success,
        floating: true,
      );
    } on Object catch (e, s) {
      Log.error(e, s, reason: 'OrderSuccessPage.recreatePaperInvoice');
      if (!mounted) return;
      setState(() => _isRecreatingPaper = false);
      AppFeedback.show(
        context,
        message: 'Gagal membuat ulang link Paper.id. Coba lagi.',
        type: AppFeedbackType.error,
        floating: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final noSp = _args?.noSp.trim() ?? '';
    final theme = Theme.of(context);
    final paperFailed = _needsPaperRetry;
    final iconColor = paperFailed ? AppColors.warning : AppColors.success;
    final title = paperFailed
        ? 'Pesanan Berhasil, Pembayaran Belum Siap'
        : 'Pesanan Berhasil Dibuat!';
    final subtitle = paperFailed
        ? 'Surat pesanan sudah tersimpan, tetapi link pembayaran Paper.id gagal dibuat. Buat ulang link untuk melanjutkan pembayaran.'
        : _hasPaperPay
            ? 'Lanjutkan pembayaran melalui Paper.id, atau kembali ke beranda.'
            : 'Kami akan memproses pesanan Anda segera.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppLayoutTokens.space20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  paperFailed
                      ? Icons.warning_amber_rounded
                      : Icons.check_rounded,
                  size: 64,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: AppLayoutTokens.space20),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (noSp.isNotEmpty) ...[
                const SizedBox(height: AppLayoutTokens.space8),
                Text(
                  'No. SP $noSp',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppLayoutTokens.space12),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (paperFailed)
                ActionButtonBar(
                  primaryLabel: _isRecreatingPaper
                      ? 'Membuat ulang…'
                      : 'Buat ulang link Paper.id',
                  onPrimaryPressed: (_isRecreatingPaper ||
                          !(_args?.canRetryPaper ?? false))
                      ? null
                      : _recreatePaperInvoice,
                  primaryLeading: _isRecreatingPaper
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  primaryBackgroundColor: AppColors.warning,
                )
              else if (_hasPaperPay)
                ActionButtonBar(
                  primaryLabel: 'Bayar via Paper.id',
                  onPrimaryPressed: _openPaperInvoice,
                  primaryLeading:
                      const Icon(Icons.open_in_new_rounded, size: 18),
                  secondaryLabel: 'Kembali ke Beranda',
                  onSecondaryPressed: () => context.go('/'),
                )
              else
                ActionButtonBar(
                  primaryLabel: 'Kembali ke Beranda',
                  onPrimaryPressed: () => context.go('/'),
                ),
              const SizedBox(height: AppLayoutTokens.space16),
            ],
          ),
        ),
      ),
    );
  }
}
