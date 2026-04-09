import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/platform_utils.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/services/api_session_expired.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/pdf_service/invoice_pdf_generator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/contact_actions.dart';
import '../../../../core/utils/order_letter_contact_utils.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/utils/shipping_utils.dart';
import '../../../../core/widgets/detail_contact_info_card.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/image_viewer_dialog.dart';
import '../../../../core/widgets/detail_note_card.dart';
import '../../../../core/widgets/detail_shipping_info_card.dart';
import '../../../../core/widgets/pdf_action_sheet.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../approval/logic/approval_decision_service.dart';
import '../../../approval/logic/approval_inbox_provider.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../profile/logic/profile_provider.dart';
import '../../data/models/order_history.dart';
import '../../logic/order_detail_provider.dart';
import '../widgets/add_payment_bottom_sheet.dart';
import '../widgets/approval_timeline_widget.dart';
import '../widgets/order_detail_void_bottom_bar.dart';
import '../widgets/order_detail_skeleton.dart';
import '../widgets/order_status_header.dart';
import '../widgets/payment_info_section.dart';
import '../widgets/product_items_list.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.order,
    this.allowVoidFromApprovalContext = false,
  });

  final OrderHistory order;

  /// Hanya `true` dari inbox Persetujuan (tab selesai); bukan dari Riwayat Pesanan.
  final bool allowVoidFromApprovalContext;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  bool _voidingSp = false;

  Future<void> _onVoidSuratPesanan(
    BuildContext context,
    OrderHistory currentOrder,
  ) async {
    if (!context.mounted) return;
    final confirm = await showAdaptiveConfirm(
      context: context,
      title: 'Void Surat Pesanan?',
      content: 'SP ${currentOrder.noSp} akan ditandai dibatalkan.',
      confirmLabel: 'Ya, void SP',
      isDestructive: true,
      confirmColor: AppColors.error,
    );
    if (confirm != true || !context.mounted) return;
    if (ifOfflineShowFeedback(
      context,
      isOffline: ref.read(isOfflineProvider),
    )) {
      return;
    }

    setState(() => _voidingSp = true);
    if (!context.mounted) return;
    LoadingOverlay.show(
      context,
      title: 'Memproses void…',
      subtitle: 'Mohon tunggu',
    );
    try {
      final token = await StorageService.loadAccessToken();
      final profile = ref.read(profileProvider).valueOrNull;
      final userId = await StorageService.loadUserId();
      if (userId <= 0) {
        throw Exception('ID pengguna tidak valid. Silakan login ulang.');
      }
      await ref
          .read(approvalInboxProvider.notifier)
          .voidOrderLetterViaRejectedEndpoint(
            orderLetterId: currentOrder.id,
            userId: userId,
            token: token,
          );
      unawaited(
        ApprovalDecisionService.triggerRejectionNotification(
          orderData: currentOrder.toApprovalOrderDataMap(),
          spNumber: currentOrder.noSp,
          token: token,
          senderName: profile?.name ?? 'Approver',
        ),
      );
      unawaited(ref.read(approvalInboxProvider.notifier).fetchInbox());
      await ref.read(orderDetailProvider(widget.order.id).notifier).refresh();
      if (!context.mounted) return;
      LoadingOverlay.dismiss(context);
      setState(() => _voidingSp = false);
      if (!context.mounted) return;
      AppFeedback.show(
        context,
        message: 'Surat Pesanan telah divoid.',
        type: AppFeedbackType.success,
        floating: true,
      );
      if (!context.mounted) return;
      context.pop();
    } catch (e, st) {
      if (!context.mounted) return;
      LoadingOverlay.dismiss(context);
      setState(() => _voidingSp = false);
      if (!context.mounted) return;
      if (e is ApiSessionExpiredException) {
        Log.warning(
          'Void SP session expired: ${e.detail}',
          tag: 'OrderDetail',
        );
        AppFeedback.show(
          context,
          message: e.toString(),
          type: AppFeedbackType.warning,
          floating: true,
          duration: const Duration(seconds: 5),
        );
        await ref.read(authProvider.notifier).logout();
        return;
      }
      Log.error(e, st, reason: 'OrderDetail.voidSuratPesanan');
      AppFeedback.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppFeedbackType.error,
        floating: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(orderDetailProvider(widget.order.id));
    final currentOrder = detailState.valueOrNull ?? widget.order;
    final isOffline = ref.watch(isOfflineProvider);
    final shippingDiffers = isShippingDifferent(
      shipToName: currentOrder.shipToName,
      shipToAddress: currentOrder.addressShipTo,
      customerName: currentOrder.customerName,
      customerAddress: currentOrder.address,
    );
    final fmt = AppFormatters.currencyIdr;
    final myName = ref.watch(profileProvider).valueOrNull?.name ?? '';
    final userId = ref.watch(authProvider).userId;
    final needsDiscountApproval =
        ApprovalDecisionService.orderHistoryNeedsMyApproval(
      order: currentOrder,
      userId: userId,
      myName: myName,
    );

    final totalPaid = currentOrder.payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final remainingPayment =
        (currentOrder.totalAmount - totalPaid).clamp(0.0, double.infinity);

    final showVoidBottomBar = widget.allowVoidFromApprovalContext &&
        OrderStatusX.fromRaw(currentOrder.status) == OrderStatus.approved;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              if (ifOfflineShowFeedback(context, isOffline: isOffline)) return;
              ref.read(orderDetailProvider(widget.order.id).notifier).refresh();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.picture_as_pdf_outlined,
              color: isOffline ? AppColors.textTertiary : null,
            ),
            enabled: !isOffline,
            tooltip: isOffline ? 'Membutuhkan internet' : 'Cetak / Bagikan PDF',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 4),
            onSelected: (value) {
              if (value == 'customer' || value == 'internal') {
                _showPdfActionSheet(
                  context,
                  order: currentOrder,
                  isInternal: value == 'internal',
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'customer',
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description_outlined,
                          size: 18, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Surat Pesanan (Customer)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Versi untuk pelanggan',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'internal',
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_outline,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Surat Pesanan (Internal)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Versi internal dengan harga',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      bottomNavigationBar: showVoidBottomBar
          ? OrderDetailVoidBottomBar(
              isLoading: _voidingSp,
              onVoid: () => _onVoidSuratPesanan(context, currentOrder),
            )
          : null,
      body: detailState.isLoading && !detailState.hasValue
          ? const OrderDetailSkeleton()
          : detailState.hasError && !detailState.hasValue
              ? _ErrorBody(
                  onRetry: () => ref
                      .read(orderDetailProvider(widget.order.id).notifier)
                      .refresh(),
                  message: detailState.error.toString(),
                  onGoHome: () => context.go('/order_history'),
                )
              : RefreshIndicator.adaptive(
                  onRefresh: () => ref
                      .read(orderDetailProvider(widget.order.id).notifier)
                      .refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrderStatusHeader(
                          order: currentOrder,
                          onCopySp: () => ContactActions.copyText(
                            context,
                            text: currentOrder.noSp,
                            successMessage: 'No SP berhasil disalin',
                            duration: const Duration(seconds: 2),
                          ),
                        ),
                        if (needsDiscountApproval) ...[
                          const SizedBox(height: 12),
                          SectionCard(
                            title: 'Persetujuan diskon',
                            backgroundColor:
                                AppColors.accent.withValues(alpha: 0.08),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SP ini membutuhkan tindakan persetujuan diskon '
                                  'dari Anda. Gunakan halaman khusus persetujuan '
                                  'untuk menyetujui atau menolak.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppLayoutTokens.space12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () {
                                      hapticTap();
                                      context.push(
                                        '/approval_detail',
                                        extra: currentOrder
                                            .toApprovalOrderDataMap(),
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: AppColors.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppLayoutTokens.radius10,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Buka halaman persetujuan diskon',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final customerPhones =
                                OrderLetterContactUtils.customerPhoneList(
                              currentOrder.orderLetterContacts,
                              fallbackPhone: currentOrder.phone,
                            );
                            return DetailContactInfoCard(
                              title: shippingDiffers
                                  ? 'Informasi Pelanggan'
                                  : 'Informasi Pelanggan & Pengiriman',
                              name: currentOrder.customerName,
                              phones: customerPhones,
                              email: currentOrder.email,
                              address: currentOrder.address,
                              onCopyPhone: customerPhones.isEmpty
                                  ? null
                                  : (phone) => ContactActions.copyText(
                                        context,
                                        text: phone,
                                        successMessage: 'Nomor HP disalin',
                                        duration: const Duration(seconds: 1),
                                      ),
                              onCallPhone: customerPhones.isEmpty
                                  ? null
                                  : (phone) =>
                                      _callPhone(context, phone),
                              onOpenWhatsApp: customerPhones.isEmpty
                                  ? null
                                  : (phone) => _openWhatsApp(
                                        context,
                                        phone: phone,
                                        customerName:
                                            currentOrder.customerName,
                                        noSp: currentOrder.noSp,
                                        senderName: ref
                                            .read(authProvider)
                                            .userName,
                                      ),
                            );
                          },
                        ),
                        if (shippingDiffers) ...[
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final shipPhones =
                                  OrderLetterContactUtils.recipientPhoneList(
                                currentOrder.orderLetterContacts,
                                fallbackPhone: currentOrder.phone,
                              );
                              final waName = currentOrder.shipToName
                                      .trim()
                                      .isNotEmpty
                                  ? currentOrder.shipToName.trim()
                                  : currentOrder.customerName;
                              return DetailShippingInfoCard(
                                name: currentOrder.shipToName.trim(),
                                address: currentOrder.addressShipTo.trim(),
                                phones: shipPhones,
                                onCopyPhone: shipPhones.isEmpty
                                    ? null
                                    : (phone) => ContactActions.copyText(
                                          context,
                                          text: phone,
                                          successMessage: 'Nomor HP disalin',
                                          duration: const Duration(seconds: 1),
                                        ),
                                onCallPhone: shipPhones.isEmpty
                                    ? null
                                    : (phone) =>
                                        _callPhone(context, phone),
                                onOpenWhatsApp: shipPhones.isEmpty
                                    ? null
                                    : (phone) => _openWhatsApp(
                                          context,
                                          phone: phone,
                                          customerName: waName,
                                          noSp: currentOrder.noSp,
                                          senderName: ref
                                              .read(authProvider)
                                              .userName,
                                        ),
                              );
                            },
                          ),
                        ],
                        if (currentOrder.note.isNotEmpty &&
                            currentOrder.note != '-') ...[
                          const SizedBox(height: 12),
                          DetailNoteCard(
                            note: currentOrder.note,
                            borderRadius: 14,
                            borderColor:
                                AppColors.warning.withValues(alpha: 0.3),
                            iconColor: AppColors.warning,
                            titleColor: AppColors.warning,
                            noteStyle: const TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ProductItemsList(
                          order: currentOrder,
                          currencyFormatter: fmt,
                        ),
                        const SizedBox(height: 12),
                        ApprovalTimelineWidget(order: currentOrder),
                        if (currentOrder.payments.isNotEmpty ||
                            remainingPayment > 0) ...[
                          const SizedBox(height: 12),
                          PaymentInfoSection(
                            order: currentOrder,
                            currencyFormatter: fmt,
                            onTapReceipt: (imageUrl) =>
                                _showImageDialog(context, imageUrl),
                            onTapAddPayment: () {
                              _showAddPaymentBottomSheet(
                                context,
                                ref: ref,
                                remainingPayment: remainingPayment,
                                orderId: currentOrder.id,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── PDF ─────────────────────────────────────────────────────

  static Rect _shareOriginFromContext(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final screen = MediaQuery.of(context).size;
    return Rect.fromLTWH(0, 0, screen.width, screen.height / 2);
  }

  static void _showPdfActionSheet(
    BuildContext context, {
    required OrderHistory order,
    required bool isInternal,
  }) {
    final origin = _shareOriginFromContext(context);

    PdfActionSheet.show(
      context,
      label: isInternal ? 'Internal' : 'Customer',
      onPrint: isInternal
          ? () => InvoicePdfGenerator.generateInternalPdfFromOrder(order)
          : () => InvoicePdfGenerator.generateExternalPdfFromOrder(order),
      onShare: isInternal
          ? () => InvoicePdfGenerator.shareInternalPdfFromOrder(
                order,
                sharePositionOrigin: origin,
              )
          : () => InvoicePdfGenerator.shareExternalPdfFromOrder(
                order,
                sharePositionOrigin: origin,
              ),
    );
  }

  // ── Payment ─────────────────────────────────────────────────

  static void _showAddPaymentBottomSheet(
    BuildContext context, {
    required WidgetRef ref,
    required double remainingPayment,
    required int orderId,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddPaymentBottomSheet(
        remainingPayment: remainingPayment,
        onSave: (payload, receiptFile) async {
          if (ifOfflineShowFeedback(
            context,
            isOffline: ref.read(isOfflineProvider),
          )) {
            return;
          }
          try {
            hapticConfirm();
            await ref
                .read(orderDetailProvider(orderId).notifier)
                .addAdditionalPayment(
                  payload: payload,
                  receiptFile: receiptFile,
                );
            if (context.mounted) {
              AppFeedback.show(
                context,
                message:
                    'Pembayaran berhasil disimpan. Silakan refresh / buka ulang detail pesanan.',
                type: AppFeedbackType.success,
                floating: true,
              );
            }
          } catch (e, st) {
            Log.error(e, st, reason: 'OrderDetail.addPayment');
            if (context.mounted) {
              AppFeedback.show(
                context,
                message: e.toString().replaceFirst('Exception: ', ''),
                type: AppFeedbackType.error,
                floating: true,
              );
            }
          }
        },
      ),
    );
  }

  // ── Phone Call ──────────────────────────────────────────────

  static Future<void> _callPhone(BuildContext context, String phone) async {
    try {
      final called = await ContactActions.callPhone(phone);
      if (!called && context.mounted) {
        AppFeedback.plain(context, 'Tidak dapat membuka telepon');
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'OrderDetail.callPhone');
      if (context.mounted) {
        AppFeedback.plain(context, 'Terjadi kesalahan saat menelepon');
      }
    }
  }

  // ── WhatsApp ────────────────────────────────────────────────

  static Future<void> _openWhatsApp(
    BuildContext context, {
    required String phone,
    required String customerName,
    required String noSp,
    required String senderName,
  }) async {
    try {
      final sender = senderName.isNotEmpty ? senderName : 'Tim Sales';
      final message =
          'Halo Bapak/Ibu $customerName, saya $sender dari Sleep Center. '
          'Ingin konfirmasi mengenai Surat Pesanan No *$noSp*. '
          'Mohon informasinya, terima kasih.';

      final opened = await ContactActions.openWhatsAppChat(
        phone,
        message: message,
      );
      if (!opened && context.mounted) {
        AppFeedback.plain(context, 'Tidak dapat membuka WhatsApp');
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'OrderDetail.openWhatsApp');
      if (context.mounted) {
        AppFeedback.plain(context, 'Terjadi kesalahan saat membuka WhatsApp');
      }
    }
  }

  // ── Image Viewer ────────────────────────────────────────────

  static void _showImageDialog(BuildContext context, String imageUrl) {
    ImageViewerDialog.show(
      context: context,
      imageUrl: imageUrl,
      insetPadding: const EdgeInsets.all(16),
      borderRadius: 16,
      loadingWidget: Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ),
      errorWidget: Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Gagal memuat gambar',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      ),
      closeAsIconButton: true,
      closeTop: 0,
      closeRight: 0,
      closeIcon: Icons.cancel_rounded,
      closeIconSize: 32,
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.onRetry,
    required this.message,
    required this.onGoHome,
  });

  final VoidCallback onRetry;
  final VoidCallback onGoHome;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppLayoutTokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 28),
            const SizedBox(height: AppLayoutTokens.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppLayoutTokens.space12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onGoHome,
              child: const Text('Kembali ke Riwayat'),
            ),
          ],
        ),
      ),
    );
  }
}
