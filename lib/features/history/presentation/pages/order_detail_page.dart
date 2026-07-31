import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/platform_utils.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/services/api_session_expired.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/pdf_service/invoice_pdf_generator.dart';
import '../../../../core/services/screen_capture_guard_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/contact_actions.dart';
import '../../../../core/utils/order_letter_contact_utils.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/utils/internal_pdf_access.dart';
import '../../../../core/utils/shipping_utils.dart';
import '../../../../core/widgets/detail_contact_info_card.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/image_viewer_dialog.dart';
import '../../../../core/widgets/detail_note_card.dart';
import '../../../../core/widgets/detail_shipping_info_card.dart';
import '../../../../core/widgets/go_router_pop_scope.dart';
import '../../../../core/widgets/pdf_action_sheet.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../approval/logic/approval_decision_service.dart';
import '../../../approval/logic/approval_inbox_provider.dart';
import '../../../approval/presentation/approval_detail_route_args.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../../profile/logic/profile_provider.dart';
import '../../data/models/order_history.dart';
import '../../logic/edit_order_context_provider.dart';
import '../../logic/order_detail_provider.dart';
import '../widgets/add_payment_bottom_sheet.dart';
import '../widgets/approval_timeline_widget.dart';
import '../widgets/edit_order_header_sheet.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ScreenCaptureGuardService.enter(
          onScreenshotAttempt: () {
            if (!mounted) return;
            AppFeedback.show(
              context,
              message: 'Screenshot tidak diizinkan di halaman ini.',
              type: AppFeedbackType.warning,
              floating: true,
            );
          },
          onScreenRecord: (recording) {
            if (!mounted || !recording) return;
            AppFeedback.show(
              context,
              message:
                  'Perekaman layar terdeteksi. Konten sensitif dilindungi.',
              type: AppFeedbackType.warning,
              floating: true,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    // `dispose` tidak boleh async; teardown async dijalankan sampai selesai
    // di background agar flag native tidak "bocor" ke halaman berikutnya.
    unawaited(ScreenCaptureGuardService.leave());
    super.dispose();
  }

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
      unawaited(
          ref.read(approvalInboxProvider.notifier).fetchInbox(force: true));
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
        message: userFacingErrorMessage(e),
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

    final totalPaid = currentOrder.payments
        .where((payment) => payment.countsTowardTotal)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final remainingPayment =
        (currentOrder.totalAmount - totalPaid).clamp(0.0, double.infinity);

    final currentStatus = OrderStatusX.fromRaw(currentOrder.status);
    final isSoChannel =
        (currentOrder.channel?.trim().toUpperCase() ?? '') == 'SO';
    final isCreator = currentOrder.creator == userId.toString();
    // Approver (dari konteks inbox persetujuan) bisa void order Approved.
    final showVoidBottomBar = !isOffline &&
        ((widget.allowVoidFromApprovalContext &&
                currentStatus == OrderStatus.approved) ||
            // Creator order SO bisa void miliknya sendiri selama belum Rejected.
            (isSoChannel &&
                isCreator &&
                currentStatus != OrderStatus.rejected));

    // Kondisi dasar: pemilik SP, tidak offline, status bukan rejected.
    final canEditBase = !isOffline &&
        currentOrder.creator == userId.toString() &&
        OrderStatusX.fromRaw(currentOrder.status) != OrderStatus.rejected;
    // Edit informasi (header): berlaku untuk semua channel. Hanya field
    // header (nama, kontak, alamat, tanggal kirim, PO, ongkir, dll) yang
    // diubah — data harga/diskon per item tidak tersentuh sama sekali.
    final canEditHeader = canEditBase;
    // Edit barang: berlaku untuk semua channel.
    final canEditItems = canEditBase && currentOrder.details.isNotEmpty;

    // Cegah user keluar halaman selagi void SP sedang diproses ke server —
    // sama seperti approval detail: tanpa ini, request GET
    // order_letters_rejected bisa terputus tanpa error yang pernah terlihat
    // user, karena mereka sudah berpindah halaman sendiri.
    return PopScope(
      canPop: !_voidingSp,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
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
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Kembali',
            onPressed: _voidingSp
                ? null
                : () => GoRouterPopScope.handlePop(
                      context,
                      fallbackLocation: '/order_history',
                    ),
          ),
          actions: [
            // Single entry point untuk semua "Edit": tap → adaptive sheet
            // (iOS action sheet / Android modal bottom sheet) berisi opsi
            // "Edit Informasi Pesanan" + "Edit Item Pesanan" sesuai permission.
            // Bila hanya satu permission yang aktif, langsung jalankan tanpa sheet.
            if (canEditHeader || canEditItems)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Pesanan',
                onPressed: () => _onEditTapped(
                  context,
                  order: currentOrder,
                  canEditHeader: canEditHeader,
                  canEditItems: canEditItems,
                  editorName: myName,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () {
                if (ifOfflineShowFeedback(context, isOffline: isOffline))
                  return;
                ref
                    .read(orderDetailProvider(widget.order.id).notifier)
                    .refresh();
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.picture_as_pdf_outlined,
                color: isOffline ? AppColors.textTertiary : null,
              ),
              enabled: !isOffline,
              tooltip:
                  isOffline ? 'Membutuhkan internet' : 'Cetak / Bagikan PDF',
              position: PopupMenuPosition.under,
              offset: const Offset(0, 4),
              onSelected: (value) {
                if (value != 'customer' && value != 'internal') return;
                if (value == 'internal') {
                  final uid = ref.read(authProvider).userId;
                  final canBypass =
                      InternalPdfAccess.bypassesItemDiscountApprovalGate(uid);
                  if (!canBypass &&
                      !ApprovalDecisionService
                          .orderHistoryAllItemDiscountsApproved(
                        currentOrder,
                      )) {
                    showAdaptiveAlert<void>(
                      context: context,
                      title: 'Persetujuan belum lengkap',
                      content:
                          'Surat Pesanan (Internal) hanya dapat dibuka setelah '
                          'semua level persetujuan diskon pada timeline berstatus '
                          'disetujui, tanpa level yang masih menunggu atau ditolak.',
                      actions: const [
                        AdaptiveAction(
                          label: 'Mengerti',
                          isDefault: true,
                          popResult: true,
                        ),
                      ],
                    );
                    return;
                  }
                }
                _showPdfActionSheet(
                  context,
                  order: currentOrder,
                  isInternal: value == 'internal',
                );
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
        // skipError: keep showing stale data on a failed background refresh
        // instead of replacing already-visible content with an error screen.
        body: detailState.when(
          skipError: true,
          loading: () => const OrderDetailSkeleton(),
          error: (error, _) => _ErrorBody(
            onRetry: () => ref
                .read(orderDetailProvider(widget.order.id).notifier)
                .refresh(),
            message: error.toString(),
            onGoHome: () => context.go('/order_history'),
          ),
          data: (_) => RefreshIndicator.adaptive(
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
                      backgroundColor: AppColors.accent.withValues(alpha: 0.08),
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
                                  extra: ApprovalDetailRouteArgs(
                                    orderData:
                                        currentOrder.toApprovalOrderDataMap(),
                                  ),
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
                            : (phone) => _callPhone(context, phone),
                        onOpenWhatsApp: customerPhones.isEmpty
                            ? null
                            : (phone) => _openWhatsApp(
                                  context,
                                  phone: phone,
                                  customerName: currentOrder.customerName,
                                  noSp: currentOrder.noSp,
                                  senderName: ref.read(authProvider).userName,
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
                        final waName = currentOrder.shipToName.trim().isNotEmpty
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
                              : (phone) => _callPhone(context, phone),
                          onOpenWhatsApp: shipPhones.isEmpty
                              ? null
                              : (phone) => _openWhatsApp(
                                    context,
                                    phone: phone,
                                    customerName: waName,
                                    noSp: currentOrder.noSp,
                                    senderName: ref.read(authProvider).userName,
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
                      borderColor: AppColors.warning.withValues(alpha: 0.3),
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
                  if ((currentOrder.payments.isNotEmpty ||
                          remainingPayment > 0) &&
                      (currentOrder.channel?.trim().toUpperCase() != 'SO')) ...[
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

  /// Entry point tunggal untuk tombol Edit di appbar.
  ///
  /// - Bila kedua permission aktif → tampilkan adaptive sheet (iOS:
  ///   [CupertinoActionSheet], Android: [showModalBottomSheet]).
  /// - Bila hanya satu permission yang aktif → jalankan langsung tanpa sheet
  ///   agar tidak menambah tap yang tidak perlu.
  Future<void> _onEditTapped(
    BuildContext context, {
    required OrderHistory order,
    required bool canEditHeader,
    required bool canEditItems,
    required String editorName,
  }) async {
    hapticTap();

    void runEditHeader() {
      EditOrderHeaderSheet.show(
        context,
        order: order,
        editorName: editorName,
        onSuccess: () {
          ref.read(orderDetailProvider(widget.order.id).notifier).refresh();
        },
      );
    }

    Future<void> runEditItems() => _startEditItems(context, order);

    // Hanya satu opsi yang aktif → langsung jalankan, skip sheet.
    if (canEditHeader && !canEditItems) {
      runEditHeader();
      return;
    }
    if (canEditItems && !canEditHeader) {
      await runEditItems();
      return;
    }

    // Dua opsi aktif → tampilkan adaptive sheet.
    final choice = await _showEditOptionsSheet(context);
    if (choice == _EditChoice.header) {
      runEditHeader();
    } else if (choice == _EditChoice.items) {
      await runEditItems();
    }
  }

  /// Tampilkan adaptive sheet pilihan edit. Mengembalikan [_EditChoice]
  /// atau `null` jika user membatalkan.
  Future<_EditChoice?> _showEditOptionsSheet(BuildContext context) {
    if (isIOS) {
      return showCupertinoModalPopup<_EditChoice>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Edit Pesanan'),
          message: const Text(
            'Pilih bagian yang ingin diubah. Approval akan disesuaikan otomatis.',
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(_EditChoice.header),
              child: const Text('Edit Informasi Pesanan'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(_EditChoice.items),
              child: const Text('Edit Item Pesanan'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
        ),
      );
    }

    return showModalBottomSheet<_EditChoice>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  'Edit Pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Pilih bagian yang ingin diubah.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _EditOptionTile(
                icon: Icons.assignment_outlined,
                title: 'Edit Informasi Pesanan',
                subtitle:
                    'Pelanggan, alamat, pengiriman, catatan, dan diskon header',
                onTap: () => Navigator.of(ctx).pop(_EditChoice.header),
              ),
              _EditOptionTile(
                icon: Icons.inventory_2_outlined,
                title: 'Edit Item Pesanan',
                subtitle: 'Tambah, ubah, atau hapus produk dan diskon per item',
                onTap: () => Navigator.of(ctx).pop(_EditChoice.items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Memulai alur "Edit Items": kosongkan keranjang, set edit context,
  /// navigasi ke halaman pemilihan produk sesuai channel order.
  Future<void> _startEditItems(
    BuildContext context,
    OrderHistory order,
  ) async {
    final isIndirect = (order.channel?.trim().toUpperCase() ?? '') == 'SO';
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Item Pesanan'),
        content: const Text(
          'Keranjang akan dikosongkan dan kamu bisa memilih item baru dari '
          'awal.\n\nApproval akan di-reset setelah perubahan disimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Set edit context dan kosongkan cart — user pilih item dari awal.
    ref.read(editOrderContextProvider.notifier).state = order;
    await ref.read(cartProvider.notifier).clearCart();

    if (!mounted) return;

    // Gunakan `go()` agar stack rapi: user kembali ke home/sales_hub sebagai root,
    // lalu setelah Simpan Perubahan akan di-redirect ke /order_detail.
    router.go(isIndirect ? '/sales_hub' : '/');
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
                message: userFacingErrorMessage(e),
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

/// Hasil pilihan dari adaptive edit sheet di [OrderDetailPage].
enum _EditChoice { header, items }

/// Tile satu opsi di Android modal bottom sheet "Edit Pesanan".
class _EditOptionTile extends StatelessWidget {
  const _EditOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        hapticTap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
