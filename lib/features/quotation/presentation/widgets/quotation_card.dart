import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/platform_utils.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../data/quotation_model.dart';
import '../../logic/quotation_list_provider.dart';
import '../../logic/quotation_pdf_generator.dart';
import 'edit_customer_sheet.dart';
import 'quotation_detail_sheet.dart';

class QuotationCard extends ConsumerWidget {
  const QuotationCard({super.key, required this.quotation});

  final QuotationModel quotation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = quotation.items.fold<int>(0, (s, e) => s + e.quantity);
    final itemNames = quotation.items
        .map((e) => e.product.name)
        .where((n) => n.isNotEmpty)
        .join(', ');

    return TapScale(
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.15),
                            AppColors.accent.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined,
                          size: 20, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quotation.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.dateTimeId(
                                quotation.createdAt.toIso8601String()),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.currencyIdr(quotation.totalPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusChip(quotation),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _InfoPill(
                      icon: Icons.inventory_2_outlined,
                      label: '$itemCount produk',
                    ),
                    if (itemNames.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoPill(
                          icon: Icons.bed_outlined,
                          label: itemNames,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
                child: Row(
                  children: [
                    _IconAction(
                      icon: Icons.picture_as_pdf_outlined,
                      tooltip: 'Bagikan PDF',
                      onTap: () => _sharePdf(context, ref),
                    ),
                    _IconAction(
                      customIcon: Image.asset(
                        'assets/logo/whatsapp-icon.png',
                        width: 18,
                        height: 18,
                        filterQuality: FilterQuality.medium,
                      ),
                      tooltip: 'Bagikan Teks WA',
                      onTap: () => _shareWaText(context),
                    ),
                    _IconAction(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit Info',
                      onTap: () => _editCustomerInfo(context, ref),
                    ),
                    const Spacer(),
                    _ActionChip(
                      icon: Icons.add_shopping_cart_outlined,
                      label: 'Tambah',
                      onTap: () => _addItemsAndBrowse(context, ref),
                    ),
                    const SizedBox(width: 4),
                    _ActionChip(
                      icon: Icons.shopping_cart_checkout_outlined,
                      label: 'Checkout',
                      color: AppColors.success,
                      onTap: () => _continueToCheckout(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    hapticTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuotationDetailSheet(quotation: quotation),
    );
  }

  Future<void> _sharePdf(BuildContext context, WidgetRef ref) async {
    try {
      final isOffline = ref.read(isOfflineProvider);
      if (ifOfflineShowFeedback(context, isOffline: isOffline)) {
        return;
      }
      hapticTap();
      AppFeedback.show(context,
          message: 'Membuat PDF…', type: AppFeedbackType.info);
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
      await QuotationPdfGenerator.generateAndShare(quotation,
          sharePositionOrigin: origin);

      if (quotation.status == QuotationStatus.draft) {
        unawaited(ref
            .read(quotationListProvider.notifier)
            .update(quotation.copyWith(status: QuotationStatus.sent)));
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.show(context,
            message: 'Gagal: $e', type: AppFeedbackType.error);
      }
    }
  }

  Future<void> _shareWaText(BuildContext context) async {
    final lines = <String>[
      'Penawaran untuk *${quotation.customerName}*',
      'Tanggal: ${AppFormatters.dateTimeId(quotation.createdAt.toIso8601String())}',
      '',
      ...quotation.items.map((e) => '- ${e.product.name} x${e.quantity}'),
      '',
      'Total: ${AppFormatters.currencyIdr(quotation.totalPrice)}',
    ];
    final text = lines.join('\n');
    final phone = quotation.customerPhone.trim();
    try {
      if (phone.isNotEmpty) {
        final opened = await WhatsAppHelper.openChat(
          phone: phone,
          message: text,
        );
        if (opened && context.mounted) return;
      }
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        AppFeedback.show(
          context,
          message: 'Teks penawaran disalin. Anda bisa kirim saat online.',
          type: AppFeedbackType.info,
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      AppFeedback.show(
        context,
        message: 'Gagal membuka WhatsApp. Teks disalin ke clipboard.',
        type: AppFeedbackType.warning,
      );
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  void _addItemsAndBrowse(BuildContext context, WidgetRef ref) {
    hapticTap();
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Item'),
        content: const Text(
          'Lanjutkan & tambah item ke penawaran ini?\n'
          'Keranjang saat ini akan diganti dengan item dari draft ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !context.mounted) return;

      final cart = ref.read(cartProvider.notifier);
      await cart.clearCart();
      for (final item in quotation.items) {
        await cart.addItem(item);
      }

      ref.read(activeDraftProvider.notifier).state = quotation;

      if (!context.mounted) return;
      AppFeedback.show(context,
          message:
              '${quotation.items.length} item dimuat — silakan tambah produk',
          type: AppFeedbackType.success);
      context.go('/');
    });
  }

  void _continueToCheckout(BuildContext context, WidgetRef ref) {
    hapticTap();
    context.push('/checkout', extra: quotation);
  }

  void _editCustomerInfo(BuildContext context, WidgetRef ref) {
    hapticTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditCustomerSheet(
        quotation: quotation,
        onSave: (updated) {
          ref.read(quotationListProvider.notifier).update(updated);
          if (context.mounted) {
            AppFeedback.show(context,
                message: 'Info pelanggan diperbarui',
                type: AppFeedbackType.success);
          }
        },
      ),
    );
  }
}

// ─── Status chip builder ────────────────────────────────────────────────

Widget _buildStatusChip(QuotationModel q) {
  final (fg, bg) = switch (q.status) {
    QuotationStatus.draft => (AppColors.textTertiary, AppColors.surfaceLight),
    QuotationStatus.sent => (
        AppColors.accent,
        AppColors.accent.withValues(alpha: 0.1)
      ),
    QuotationStatus.converted => (
        AppColors.success,
        AppColors.success.withValues(alpha: 0.1)
      ),
  };

  String? expiryText;
  Color? expiryColor;
  if (q.validUntil != null) {
    final isExpired = q.isExpired;
    final days = q.daysRemaining;
    expiryText = isExpired
        ? 'Kadaluarsa'
        : days == 0
            ? 'Hari ini'
            : '$days hari lagi';
    expiryColor = isExpired
        ? AppColors.error
        : days <= 3
            ? AppColors.warning
            : AppColors.textTertiary;
  }

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      StatusChip(
        label: q.status.label,
        foregroundColor: fg,
        backgroundColor: bg,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        borderRadius: 6,
        textStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
      if (expiryText != null) ...[
        const SizedBox(width: 6),
        Text(
          expiryText,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: expiryColor,
          ),
        ),
      ],
    ],
  );
}

// ─── Small helper widgets ───────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    this.icon,
    this.customIcon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData? icon;
  final Widget? customIcon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          customBorder: const CircleBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 38, minHeight: 40),
            child: Center(
              child: customIcon ??
                  Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: c),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
